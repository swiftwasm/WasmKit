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

add_dependencies(wasmkit-llvm ArgumentParser CLICommands LLVMBackend)

target_link_libraries(
  wasmkit-llvm

  ArgumentParser
  CLICommands
  LLVMBackend
)

install(TARGETS wasmkit-llvm
  RUNTIME DESTINATION bin)

if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  add_custom_command(TARGET wasmkit-llvm
      POST_BUILD COMMAND
      ${CMAKE_INSTALL_NAME_TOOL} -change "@rpath/libswiftCompatibilitySpan.dylib" "/Library/Developer/CommandLineTools/usr/lib/swift-6.2/macosx/libswiftCompatibilitySpan.dylib"
      $<TARGET_FILE:wasmkit-llvm>)
endif()
