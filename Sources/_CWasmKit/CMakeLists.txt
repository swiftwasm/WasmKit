add_library(_CWasmKit
  _CWasmKit.c
  TrapGuard.c)
target_include_directories(_CWasmKit PUBLIC
  include)

install(TARGETS _CWasmKit EXPORT WasmKitTargets)
set_property(GLOBAL APPEND PROPERTY WASMKIT_EXPORTS _CWasmKit)
