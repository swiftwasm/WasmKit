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
idf_component_register(SRCS ${devnull} PRIV_REQUIRES idf_swift)

file(GLOB_RECURSE wasmtypes_srcs ${WASMKIT_ROOT}/Sources/WasmTypes/*.swift)
idf_component_register_swift(
    ${COMPONENT_LIB}
    BRIDGING_HEADER ${CMAKE_CURRENT_LIST_DIR}/Empty.h
    SRCS ${wasmtypes_srcs}
)
target_compile_options(${COMPONENT_LIB} PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-package-name wasmkit>")
set_target_properties(${COMPONENT_LIB} PROPERTIES
    Swift_MODULE_NAME WasmTypes
    Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift-modules
)
