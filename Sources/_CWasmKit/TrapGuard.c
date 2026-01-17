#include "TrapGuard.h"

#if defined(WASMKIT_MPROTECT_BOUND_CHECKING) && WASMKIT_MPROTECT_BOUND_CHECKING

#include <pthread.h>
#include <setjmp.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

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

static void wasmkit_chain_signal(const struct sigaction *prev, int sig,
                                 siginfo_t *info, void *ucontext) {
  if (!prev) {
    _exit(128 + sig);
  }

  if (prev->sa_flags & SA_SIGINFO) {
    if (prev->sa_sigaction) {
      prev->sa_sigaction(sig, info, ucontext);
      _exit(128 + sig);
    }
  } else {
    if (prev->sa_handler == SIG_IGN) {
      _exit(128 + sig);
    }
    if (prev->sa_handler && prev->sa_handler != SIG_DFL) {
      prev->sa_handler(sig);
      _exit(128 + sig);
    }
  }

  _exit(128 + sig);
}

static void wasmkit_signal_handler(int sig, siginfo_t *info, void *ucontext) {
  wasmkit_trap_guard_t *guard = wasmkit_current_trap_guard;
  if (guard && guard->md && guard->reservation_size > 0 && info && info->si_addr) {
    uintptr_t base = (uintptr_t)guard->md;
    uintptr_t addr = (uintptr_t)info->si_addr;
    if (addr >= base && addr < base + (uintptr_t)guard->reservation_size) {
      siglongjmp(guard->env, 1);
    }
  }

  if (sig == SIGSEGV && wasmkit_has_prev_segv) {
    wasmkit_chain_signal(&wasmkit_prev_segv, sig, info, ucontext);
  }
#ifdef SIGBUS
  if (sig == SIGBUS && wasmkit_has_prev_bus) {
    wasmkit_chain_signal(&wasmkit_prev_bus, sig, info, ucontext);
  }
#endif

  _exit(128 + sig);
}

static void wasmkit_install_signal_handlers_once(void) {
  struct sigaction action;
  sigemptyset(&action.sa_mask);
  action.sa_sigaction = wasmkit_signal_handler;
  action.sa_flags = SA_SIGINFO | SA_NODEFER;

  if (sigaction(SIGSEGV, &action, &wasmkit_prev_segv) == 0) {
    wasmkit_has_prev_segv = true;
  }
#ifdef SIGBUS
  if (sigaction(SIGBUS, &action, &wasmkit_prev_bus) == 0) {
    wasmkit_has_prev_bus = true;
  }
#endif
}

int wasmkit_trap_guard_run(wasmkit_trap_guard_fn fn, void *ctx) {
  pthread_once(&wasmkit_install_once, wasmkit_install_signal_handlers_once);

  wasmkit_trap_guard_t guard;
  guard.md = NULL;
  guard.reservation_size = 0;

  wasmkit_current_trap_guard = &guard;
  int jmp = sigsetjmp(guard.env, 1);
  if (jmp == 0) {
    fn(ctx);
    wasmkit_current_trap_guard = NULL;
    return 0;
  }

  wasmkit_current_trap_guard = NULL;
  return 1;
}

void wasmkit_trap_guard_set_current_memory(void *md, size_t reservation_size) {
  wasmkit_trap_guard_t *guard = wasmkit_current_trap_guard;
  if (guard) {
    guard->md = md;
    guard->reservation_size = reservation_size;
  }
}

#else

int wasmkit_trap_guard_run(wasmkit_trap_guard_fn fn, void *ctx) {
  fn(ctx);
  return 0;
}

void wasmkit_trap_guard_set_current_memory(void *md, size_t reservation_size) {
  (void)md;
  (void)reservation_size;
}

#endif

