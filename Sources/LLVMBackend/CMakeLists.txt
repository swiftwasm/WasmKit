add_library(
  LLVMBackend

  CodegenContext.swift
  IRContext+codegen.swift
  IRFunctionVisitor.swift
  Linker.swift
  Loader.swift
  Wasm32Memory.swift
)
target_compile_options(
  LLVMBackend
  PUBLIC
    "SHELL:-Xcc -std=c++17"
    "SHELL:-Xcc -fapinotes"
    "SHELL:-Xcc -fapinotes-modules"
    "-cxx-interoperability-mode=default"
    -package-name WasmKitPackage
)

target_include_directories(
  LLVMBackend
  PUBLIC
    "${LLVMINTEROP_INCLUDE_DIR}"
    "${LLVM_MAIN_INCLUDE_DIR}"
    "${LLVM_INCLUDE_DIR}"
)

set(WASMKIT_DEPENDENCIES WAT WasmKit WasmTypes WasmParser)
set(BUILD_TESTING OFF)

add_dependencies(LLVMInterop BasicContainers LLVM_Utils Subprocess ${WASMKIT_DEPENDENCIES})

target_link_libraries(
  LLVMBackend

  BasicContainers
  ${WASMKIT_DEPENDENCIES}
  LLVMInterop
  LLVM_Utils
  Subprocess
)
