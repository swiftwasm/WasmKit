add_executable(
  wasmkit-llvm

  Entrypoint.swift
)
target_compile_options(
  wasmkit-llvm
  PRIVATE
    -parse-as-library
    -package-name WasmKitPackage
    -module-name LLVMBackendCLI
)
set(BUILD_TESTING OFF)

find_package(ArgumentParser CONFIG)
if(NOT ArgumentParser_FOUND)
  message("-- Vending ArgumentParser")
  FetchContent_Declare(
    ArgumentParser
    GIT_REPOSITORY https://github.com/apple/swift-argument-parser
    GIT_TAG 1.6.2
  )
  FetchContent_MakeAvailable(ArgumentParser)
endif()

add_dependencies(wasmkit-llvm ArgumentParser LLVMBackend)

target_link_libraries(
  wasmkit-llvm

  ArgumentParser
  LLVMBackend
)

install(TARGETS wasmkit-llvm
  RUNTIME DESTINATION bin)
