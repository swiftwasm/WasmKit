add_library(_CWasmKit INTERFACE)
target_include_directories(_CWasmKit INTERFACE
  include)

install(TARGETS _CWasmKit EXPORT WasmKitTargets)
set_property(GLOBAL APPEND PROPERTY WASMKIT_EXPORTS _CWasmKit)
