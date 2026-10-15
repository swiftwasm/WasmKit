if(DEFINED ENV{WASMKIT_ROOT})
    set(WASMKIT_ROOT $ENV{WASMKIT_ROOT})
else()
    get_filename_component(WASMKIT_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE)
endif()
if(WIN32)
  set(devnull NUL)
else()
  set(devnull /dev/null)
endif()
idf_component_register(SRCS ${devnull} PRIV_REQUIRES idf_swift wasmtypes wasmparser cwasmkit wasmkit wasi wasmkitwasi gdbremoteprotocol)

file(GLOB_RECURSE gdbh_srcs ${WASMKIT_ROOT}/Sources/WasmKitGDBHandler/*.swift)
idf_component_register_swift(
    ${COMPONENT_LIB}
    BRIDGING_HEADER ${CMAKE_CURRENT_LIST_DIR}/Empty.h
    SRCS ${gdbh_srcs}
)
set_target_properties(${COMPONENT_LIB} PROPERTIES
    Swift_MODULE_NAME WasmKitGDBHandler
    Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift-modules
)
# See the wasmtypes component for why -function-sections is required here.
target_compile_options(${COMPONENT_LIB} PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-I ${CMAKE_BINARY_DIR}/swift-modules -Xcc -I${WASMKIT_ROOT}/Sources/_CWasmKit/include -Xfrontend -function-sections -DWasmDebuggingSupport -package-name wasmkit>")
add_dependencies(${COMPONENT_LIB} __idf_wasmtypes __idf_wasmparser __idf_wasmkit __idf_wasi __idf_wasmkitwasi __idf_gdbremoteprotocol)
