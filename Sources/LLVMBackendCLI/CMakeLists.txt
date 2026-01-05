add_executable(
  LLVMBackendCLI

  Entrypoint.swift
)
target_compile_options(
  LLVMBackendCLI
  PRIVATE
    -parse-as-library
    -package-name WasmKitPackage
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

add_dependencies(LLVMBackendCLI ArgumentParser LLVMBackend)

target_link_libraries(
  LLVMBackendCLI

  ArgumentParser
  LLVMBackend
)
