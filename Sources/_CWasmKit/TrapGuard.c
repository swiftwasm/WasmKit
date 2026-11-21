// glibc and musl declare the register indices of x86_64's `mcontext_t` (REG_RIP, REG_RSP) only
// for _GNU_SOURCE, which has to come before the first system header.
#if defined(__linux__) && !defined(_GNU_SOURCE)
#  define _GNU_SOURCE
#endif

#include "TrapGuard.h"
#include "Platform.h"

#if WASMKIT_MPROTECT_BOUND_CHECKING

#include <pthread.h>
#include <setjmp.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#if defined(__APPLE__)
#  include <sys/ucontext.h>
#else
#  include <ucontext.h>
#endif

typedef struct wasmkit_trap_guard {
  sigjmp_buf env;
  void *md;
  size_t reservation_size;
} wasmkit_trap_guard_t;

static __thread wasmkit_trap_guard_t *wasmkit_current_trap_guard = NULL;

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

/// Where a thread that faulted in a guard page resumes: it jumps back to its trap guard's
/// `sigsetjmp`, which then reports the trap.
///
/// The signal handler doesn't jump there itself. Leaving a handler by `siglongjmp` skips the
/// kernel's return from the signal, which is what restores the thread's signal mask and, on
/// Darwin, marks it as off its alternate signal stack; `siglongjmp` does those only for a
/// `sigsetjmp` that saved the mask, which costs two system calls on every entry into the guest.
/// So the handler instead points the interrupted thread's context here and returns: the kernel
/// restores the mask and the signal stack as they were at the fault, and the thread continues
/// here, on its own stack, as if this had been called from the faulting instruction. The frames
/// between this and the trap guard are abandoned, as a jump from the handler abandoned them.
__attribute__((noreturn, noinline))
static void wasmkit_trap_guard_land(void) {
  siglongjmp(wasmkit_current_trap_guard->env, 1);
}

/// Makes the thread that took the signal described by `ucontext` resume at
/// `wasmkit_trap_guard_land` when the handler returns.
static void wasmkit_resume_at_landing(void *ucontext) {
  ucontext_t *context = (ucontext_t *)ucontext;
  uintptr_t landing = (uintptr_t)&wasmkit_trap_guard_land;
#if defined(__APPLE__) && defined(__aarch64__)
  // Through the macro, which signs the address where the process uses pointer authentication.
  __darwin_arm_thread_state64_set_pc_fptr(context->uc_mcontext->__ss, (void *)landing);
#elif defined(__APPLE__) && defined(__x86_64__)
  // A function expects the stack 16-byte aligned before the call pushed its return address.
  context->uc_mcontext->__ss.__rsp = (context->uc_mcontext->__ss.__rsp & ~(uint64_t)15) - 8;
  context->uc_mcontext->__ss.__rip = landing;
#elif defined(__linux__) && defined(__aarch64__)
  context->uc_mcontext.pc = landing;
#elif defined(__linux__) && defined(__x86_64__)
  context->uc_mcontext.gregs[REG_RSP] = (context->uc_mcontext.gregs[REG_RSP] & ~(greg_t)15) - 8;
  context->uc_mcontext.gregs[REG_RIP] = (greg_t)landing;
#else
#  error "WASMKIT_MPROTECT_BOUND_CHECKING needs a way to resume a signalled thread elsewhere here"
#endif
}

static void wasmkit_signal_handler(int sig, siginfo_t *info, void *ucontext) {
  wasmkit_trap_guard_t *guard = wasmkit_current_trap_guard;
  if (guard && guard->md && guard->reservation_size > 0 && info && info->si_addr) {
    uintptr_t base = (uintptr_t)guard->md;
    uintptr_t addr = (uintptr_t)info->si_addr;
    if (addr >= base && addr < base + (uintptr_t)guard->reservation_size) {
      // Return from the handler into `wasmkit_trap_guard_land` rather than jumping out of it:
      // see there.
      wasmkit_resume_at_landing(ucontext);
      return;
    }
  }

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
  // No signal mask to save: a trap comes back through the kernel's return from the signal,
  // which restores it (see `wasmkit_trap_guard_land`).
  int jmp = sigsetjmp(guard.env, 0);
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
