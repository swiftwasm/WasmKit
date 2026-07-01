add_wasmkit_library(CLICommands
    Explore.swift
    Platform.swift
    Run.swift
    Wat2wasm.swift
    Wasm2wat.swift
)

target_link_wasmkit_libraries(CLICommands PUBLIC
  SystemExtras WAT WasmKitWASI)

add_dependencies(
  CLICommands

  ArgumentParser
)

target_link_libraries(CLICommands

  PUBLIC
  ArgumentParser
)
