#include "CWasmKitTestSupport.h"

#include <stdlib.h>
#include <signal.h>

#define wasmkit_trap_guard_run wasmkit_test_shadow_trap_guard_run
#define wasmkit_trap_guard_set_current_memory wasmkit_test_shadow_trap_guard_set_current_memory
#include "../../Sources/_CWasmKit/TrapGuard.c"
#undef wasmkit_trap_guard_run
#undef wasmkit_trap_guard_set_current_memory

static volatile sig_atomic_t wasmkit_test_previous_handler_called = 0;

static void wasmkit_test_previous_handler(int sig) {
  (void)sig;
  wasmkit_test_previous_handler_called = 1;
}

int wasmkit_test_signal_handler_chains_to_previous_handler(void) {
  struct sigaction previous;

  wasmkit_test_previous_handler_called = 0;
  sigemptyset(&previous.sa_mask);
  previous.sa_flags = 0;
  previous.sa_handler = wasmkit_test_previous_handler;

  wasmkit_current_trap_guard = NULL;
  wasmkit_prev_segv = previous;
  wasmkit_has_prev_segv = true;

  wasmkit_signal_handler(SIGSEGV, NULL, NULL);
  return wasmkit_test_previous_handler_called ? 1 : 0;
}

void wasmkit_test_exit_with_code(int code) {
  exit(code);
}
