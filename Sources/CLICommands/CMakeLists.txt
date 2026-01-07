if(WASMKIT_BUILD_CLI)
  set(BUILD_TESTING OFF) # disable ArgumentParser tests
  find_package(ArgumentParser CONFIG)
  if(NOT ArgumentParser_FOUND)
    message("-- Vending ArgumentParser")
    FetchContent_Declare(ArgumentParser
            GIT_REPOSITORY https://github.com/apple/swift-argument-parser
            GIT_TAG 1.6.1
    )
    FetchContent_MakeAvailable(ArgumentParser)
  endif()
endif()

add_wasmkit_library(CLICommands
    Explore.swift
    Run.swift
    Wat2wasm.swift
)

target_link_wasmkit_libraries(CLICommands PUBLIC
  ArgumentParser WAT WasmKitWASI)
