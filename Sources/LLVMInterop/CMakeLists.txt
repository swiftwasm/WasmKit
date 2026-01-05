

find_package(LLVM CONFIG REQUIRED)
message(STATUS "Found LLVM headers: ${LLVM_MAIN_INCLUDE_DIR}")
message(STATUS "Found LLVM generated headers: ${LLVM_INCLUDE_DIR}")

add_library(
  LLVMInterop

  IRContext.cpp
  IR/IRFunction.cpp
  IR/IRPHINode.cpp
)

target_compile_features(LLVMInterop PRIVATE cxx_std_17)

set(LLVMINTEROP_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_include_directories(
  LLVMInterop
  PUBLIC
    "${LLVMINTEROP_INCLUDE_DIR}"
    "${LLVM_MAIN_INCLUDE_DIR}"
    "${LLVM_INCLUDE_DIR}"
)

llvm_map_components_to_libnames(llvm_libs
  support
  core irreader mc passes targetparser target
  ${WASMKIT_LLVM_BACKEND_TARGET}codegen ${WASMKIT_LLVM_BACKEND_TARGET}asmparser
)

target_link_libraries(LLVMInterop ${llvm_libs})

install(
  TARGETS LLVMInterop
  # shared libraries
  LIBRARY DESTINATION lib
  # for static libraries
  ARCHIVE DESTINATION lib
  # public headers
  INCLUDES DESTINATION include
)
