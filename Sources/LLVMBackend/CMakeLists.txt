add_library(
  LLVMBackend

  CodegenContext.swift
  IRContext+codegen.swift
  IRFunctionVisitor.swift
  LLInstance.swift
  LLStore.swift
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

include(FetchContent)

FetchContent_Declare(
  SwiftLLVMBindings
  GIT_REPOSITORY "https://github.com/swiftlang/swift-llvm-bindings.git"
  GIT_TAG c1fffb92d4f9d7cb98800762631cfa354869fb46
  GIT_SHALLOW TRUE
  GIT_PROGRESS ON
)

FetchContent_MakeAvailable(SwiftLLVMBindings)

find_package(Subprocess CONFIG)

if(NOT Subprocess_FOUND)
  message("-- Vending Subprocess")
  FetchContent_Declare(
    Subprocess
    GIT_REPOSITORY https://github.com/swiftlang/swift-subprocess
    GIT_TAG 0.2.1
    GIT_SHALLOW TRUE
  )
  FetchContent_MakeAvailable(Subprocess)
endif()


add_dependencies(LLVMInterop LLVM_Utils Subprocess ${WASMKIT_DEPENDENCIES})

target_link_libraries(
  LLVMBackend
  ${WASMKIT_DEPENDENCIES}
  LLVMInterop
  LLVM_Utils
  Subprocess
)
