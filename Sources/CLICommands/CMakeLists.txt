add_wasmkit_library(CLICommands
    Explore.swift
    Run.swift
    Wat2wasm.swift
)

target_link_wasmkit_libraries(CLICommands PUBLIC
  WAT WasmKitWASI)

add_dependencies(
  CLICommands

  ArgumentParser
)

target_link_libraries(CLICommands

  PUBLIC
  ArgumentParser
)
