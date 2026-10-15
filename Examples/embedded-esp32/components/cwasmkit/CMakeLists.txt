# C support code for WasmKit (_CWasmKit SwiftPM target).
if(DEFINED ENV{WASMKIT_ROOT})
    set(WASMKIT_ROOT $ENV{WASMKIT_ROOT})
else()
    get_filename_component(WASMKIT_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE)
endif()

idf_component_register(
    SRCS ${WASMKIT_ROOT}/Sources/_CWasmKit/_CWasmKit.c
         ${WASMKIT_ROOT}/Sources/_CWasmKit/TrapGuard.c
    INCLUDE_DIRS ${WASMKIT_ROOT}/Sources/_CWasmKit/include
)
