add_library(_CWasmKit
  _CWasmKit.c
  TrapGuard.c)
target_include_directories(_CWasmKit PUBLIC
  include)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  target_compile_definitions(_CWasmKit PRIVATE WASMKIT_MPROTECT_BOUND_CHECKING)
endif()

install(TARGETS _CWasmKit EXPORT WasmKitTargets)
set_property(GLOBAL APPEND PROPERTY WASMKIT_EXPORTS _CWasmKit)
