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
idf_component_register(SRCS ${devnull} PRIV_REQUIRES idf_swift wasmtypes)

file(GLOB_RECURSE wasmparser_srcs ${WASMKIT_ROOT}/Sources/WasmParser/*.swift)
idf_component_register_swift(
    ${COMPONENT_LIB}
    BRIDGING_HEADER ${CMAKE_CURRENT_LIST_DIR}/Empty.h
    SRCS ${wasmparser_srcs}
)
set_target_properties(${COMPONENT_LIB} PROPERTIES
    Swift_MODULE_NAME WasmParser
    Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift-modules
)
# `-Xfrontend -function-sections` puts each function in its own section so
# ESP-IDF's `--gc-sections` can drop what the firmware never calls. Without it
# swiftc emits one `.text` per module and none of it can be stripped.
target_compile_options(${COMPONENT_LIB} PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-I ${CMAKE_BINARY_DIR}/swift-modules -Xfrontend -function-sections -package-name wasmkit>")
add_dependencies(${COMPONENT_LIB} __idf_wasmtypes)
