#include "TrapGuard.h"
#include "Platform.h"

#if WASMKIT_MPROTECT_BOUND_CHECKING

#include <pthread.h>
#include <setjmp.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

// MARK: - Thread-local trap guard (non-shared memory, existing behavior)

typedef struct wasmkit_trap_guard {
  sigjmp_buf env;
  void *md;
  size_t reservation_size;
} wasmkit_trap_guard_t;

static __thread wasmkit_trap_guard_t *wasmkit_current_trap_guard = NULL;

// MARK: - Shared memory guard registry

#define WASMKIT_MAX_SHARED_MEMORIES 256

static _Atomic(wasmkit_shared_memory_guard_t *) wasmkit_shared_guards[WASMKIT_MAX_SHARED_MEMORIES];
static atomic_flag wasmkit_registry_lock = ATOMIC_FLAG_INIT;

static void wasmkit_registry_acquire(void) {
  while (atomic_flag_test_and_set_explicit(&wasmkit_registry_lock, memory_order_acquire)) {
    // spin
  }
}

static void wasmkit_registry_release(void) {
  atomic_flag_clear_explicit(&wasmkit_registry_lock, memory_order_release);
}

int wasmkit_shared_memory_guard_register(wasmkit_shared_memory_guard_t *guard) {
  wasmkit_registry_acquire();
  for (int i = 0; i < WASMKIT_MAX_SHARED_MEMORIES; i++) {
    wasmkit_shared_memory_guard_t *slot =
        atomic_load_explicit(&wasmkit_shared_guards[i], memory_order_relaxed);
    if (slot == NULL) {
      atomic_store_explicit(&wasmkit_shared_guards[i], guard, memory_order_release);
      wasmkit_registry_release();
      return 0;
    }
  }
  wasmkit_registry_release();
  return -1;
}

void wasmkit_shared_memory_guard_unregister(wasmkit_shared_memory_guard_t *guard) {
  wasmkit_registry_acquire();
  for (int i = 0; i < WASMKIT_MAX_SHARED_MEMORIES; i++) {
    wasmkit_shared_memory_guard_t *slot =
        atomic_load_explicit(&wasmkit_shared_guards[i], memory_order_relaxed);
    if (slot == guard) {
      atomic_store_explicit(&wasmkit_shared_guards[i], (wasmkit_shared_memory_guard_t *)NULL,
                            memory_order_release);
      break;
    }
  }
  wasmkit_registry_release();
}

void wasmkit_shared_memory_guard_lock(wasmkit_shared_memory_guard_t *guard) {
  while (atomic_flag_test_and_set_explicit(&guard->spinlock, memory_order_acquire)) {
    // spin
  }
}

void wasmkit_shared_memory_guard_unlock(wasmkit_shared_memory_guard_t *guard) {
  atomic_flag_clear_explicit(&guard->spinlock, memory_order_release);
}

void wasmkit_shared_memory_guard_set_size(wasmkit_shared_memory_guard_t *guard, size_t size) {
  atomic_store_explicit(&guard->current_byte_count, size, memory_order_release);
}

size_t wasmkit_shared_memory_guard_get_size(wasmkit_shared_memory_guard_t *guard) {
  return atomic_load_explicit(&guard->current_byte_count, memory_order_acquire);
}

void wasmkit_shared_memory_guard_init(wasmkit_shared_memory_guard_t *guard,
                                       void *base_pointer,
                                       size_t max_byte_count,
                                       size_t initial_byte_count) {
  guard->spinlock = (atomic_flag)ATOMIC_FLAG_INIT;
  guard->base_pointer = base_pointer;
  guard->max_byte_count = max_byte_count;
  atomic_store_explicit(&guard->current_byte_count, initial_byte_count, memory_order_release);
}

// Saved signal mask for the grow path. Thread-local because each thread
// may be growing a different shared memory concurrently.
// Invariant: grow() is never recursive on the same thread.
static __thread sigset_t wasmkit_grow_saved_mask;

void wasmkit_shared_memory_guard_lock_for_grow(wasmkit_shared_memory_guard_t *guard) {
  sigset_t block;
  sigemptyset(&block);
  sigaddset(&block, SIGSEGV);
#ifdef SIGBUS
  sigaddset(&block, SIGBUS);
#endif
  pthread_sigmask(SIG_BLOCK, &block, &wasmkit_grow_saved_mask);
  wasmkit_shared_memory_guard_lock(guard);
}

void wasmkit_shared_memory_guard_unlock_for_grow(wasmkit_shared_memory_guard_t *guard) {
  wasmkit_shared_memory_guard_unlock(guard);
  pthread_sigmask(SIG_SETMASK, &wasmkit_grow_saved_mask, NULL);
}

// MARK: - Signal handler

static struct sigaction wasmkit_prev_segv;
static struct sigaction wasmkit_prev_bus;
static bool wasmkit_has_prev_segv = false;
static bool wasmkit_has_prev_bus = false;
static pthread_once_t wasmkit_install_once = PTHREAD_ONCE_INIT;

static void wasmkit_restore_and_reraise(const struct sigaction *prev, int sig) {
  if (prev) {
    sigaction(sig, prev, NULL);
  }
  kill(getpid(), sig);
  // Preserve the conventional shell exit status for signal termination.
  _exit(128 + sig);
}

static void wasmkit_chain_signal(const struct sigaction *prev, int sig,
                                 siginfo_t *info, void *ucontext) {
  if (!prev) {
    wasmkit_restore_and_reraise(NULL, sig);
  }

  if (prev->sa_flags & SA_SIGINFO) {
    if (prev->sa_sigaction) {
      prev->sa_sigaction(sig, info, ucontext);
      return;
    }
  } else {
    if (prev->sa_handler == SIG_IGN) {
      return;
    }
    if (prev->sa_handler == SIG_DFL) {
      wasmkit_restore_and_reraise(prev, sig);
    }
    if (prev->sa_handler) {
      prev->sa_handler(sig);
      return;
    }
  }

  wasmkit_restore_and_reraise(prev, sig);
}

static void wasmkit_signal_handler(int sig, siginfo_t *info, void *ucontext) {
  if (!info || !info->si_addr) goto chain;

  uintptr_t addr = (uintptr_t)info->si_addr;

  // Phase 1: Check shared memory registry (spinlock + retry path).
  // Must be checked BEFORE the thread-local guard because shared memory
  // faults may need to retry the instruction (grow in progress).
  for (int i = 0; i < WASMKIT_MAX_SHARED_MEMORIES; i++) {
    wasmkit_shared_memory_guard_t *guard =
        atomic_load_explicit(&wasmkit_shared_guards[i], memory_order_acquire);
    if (!guard) continue;

    uintptr_t base = (uintptr_t)guard->base_pointer;
    size_t max = guard->max_byte_count;

    if (addr >= base && addr < base + max) {
      // Fault is in a shared memory region. Acquire the per-guard spinlock
      // to synchronize with grow (which holds it during mprotect + size update).
      wasmkit_shared_memory_guard_lock(guard);
      size_t size = atomic_load_explicit(&guard->current_byte_count, memory_order_acquire);
      wasmkit_shared_memory_guard_unlock(guard);

      if (addr < base + size) {
        // Address is within committed region. Pages must be accessible now
        // (grow completed mprotect before updating size, and we observed the
        // updated size after acquiring the spinlock that grow released).
        // Return from the signal handler to retry the faulting instruction.
        return;
      }

      // Genuine OOB on shared memory — trap via the thread-local guard.
      goto trap;
    }
  }

  // Phase 2: Check thread-local trap guard (non-shared memory).
  {
    wasmkit_trap_guard_t *tl_guard = wasmkit_current_trap_guard;
    if (tl_guard && tl_guard->md && tl_guard->reservation_size > 0) {
      uintptr_t base = (uintptr_t)tl_guard->md;
      if (addr >= base && addr < base + (uintptr_t)tl_guard->reservation_size) {
        siglongjmp(tl_guard->env, 1);
      }
    }
  }

chain:
  // Phase 3: Chain to the previously installed handler, preserving its
  // semantics (including SIG_DFL restore + re-raise via
  // wasmkit_restore_and_reraise) so non-WasmKit faults behave as expected.
  if (sig == SIGSEGV && wasmkit_has_prev_segv) {
    wasmkit_chain_signal(&wasmkit_prev_segv, sig, info, ucontext);
    return;
  }
#ifdef SIGBUS
  if (sig == SIGBUS && wasmkit_has_prev_bus) {
    wasmkit_chain_signal(&wasmkit_prev_bus, sig, info, ucontext);
    return;
  }
#endif

  // Preserve the conventional shell exit status for signal termination.
  _exit(128 + sig);

trap:
  {
    wasmkit_trap_guard_t *tl_guard = wasmkit_current_trap_guard;
    if (tl_guard) {
      siglongjmp(tl_guard->env, 1);
    }
    _exit(128 + sig);
  }
}

static void wasmkit_install_signal_handlers_once(void) {
  struct sigaction action;
  sigemptyset(&action.sa_mask);
  action.sa_sigaction = wasmkit_signal_handler;
  // SA_ONSTACK: use alternate signal stack if available (via sigaltstack),
  // preventing infinite handler recursion when SA_NODEFER is set and
  // the handler itself faults (e.g. due to stack overflow).
  action.sa_flags = SA_SIGINFO | SA_NODEFER | SA_ONSTACK;

  if (sigaction(SIGSEGV, &action, &wasmkit_prev_segv) == 0) {
    wasmkit_has_prev_segv = true;
  }
#ifdef SIGBUS
  if (sigaction(SIGBUS, &action, &wasmkit_prev_bus) == 0) {
    wasmkit_has_prev_bus = true;
  }
#endif
}

bool wasmkit_trap_guard_run(wasmkit_trap_guard_fn fn, void *ctx) {
  pthread_once(&wasmkit_install_once, wasmkit_install_signal_handlers_once);

  wasmkit_trap_guard_t guard;
  guard.md = NULL;
  guard.reservation_size = 0;
  wasmkit_trap_guard_t *previous_guard = wasmkit_current_trap_guard;

  wasmkit_current_trap_guard = &guard;
  int jmp = sigsetjmp(guard.env, 1);
  if (jmp == 0) {
    fn(ctx);
    wasmkit_current_trap_guard = previous_guard;
    return false;
  }

  wasmkit_current_trap_guard = previous_guard;
  return true;
}

void wasmkit_trap_guard_set_current_memory(void *md, size_t reservation_size) {
  wasmkit_trap_guard_t *guard = wasmkit_current_trap_guard;
  if (guard) {
    guard->md = md;
    guard->reservation_size = reservation_size;
  }
}

#else

bool wasmkit_trap_guard_run(wasmkit_trap_guard_fn fn, void *ctx) {
  fn(ctx);
  return false;
}

void wasmkit_trap_guard_set_current_memory(void *md, size_t reservation_size) {
  (void)md;
  (void)reservation_size;
}

#endif
