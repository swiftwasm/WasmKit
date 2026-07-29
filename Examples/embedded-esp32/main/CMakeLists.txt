if(WIN32)
  set(devnull NUL)
else()
  set(devnull /dev/null)
endif()
idf_component_register(
    SRCS ${devnull}
    PRIV_INCLUDE_DIRS "."
    PRIV_REQUIRES idf_swift wasmkit
)

idf_component_register_swift(
    ${COMPONENT_LIB}
    BRIDGING_HEADER ${CMAKE_CURRENT_LIST_DIR}/BridgingHeader.h
    SRCS Main.swift
)
target_compile_options(${COMPONENT_LIB} PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-I ${CMAKE_BINARY_DIR}/swift-modules>")
add_dependencies(${COMPONENT_LIB} __idf_wasmkit)

# String hashing/comparison in embedded Swift needs the Unicode data tables.
if(DEFINED ENV{SWIFT_EMBEDDED_LIB_DIR})
    set(swift_embedded_lib_dir $ENV{SWIFT_EMBEDDED_LIB_DIR})
else()
    get_filename_component(swift_bin_dir ${CMAKE_Swift_COMPILER} DIRECTORY)
    get_filename_component(swift_embedded_lib_dir
        "${swift_bin_dir}/../lib/swift/embedded/riscv32-none-none-eabi" ABSOLUTE)
endif()
target_link_libraries(${COMPONENT_LIB} INTERFACE
    "${swift_embedded_lib_dir}/libswiftUnicodeDataTables.a")
