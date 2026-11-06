add_wasmkit_library(CLICommands
    CLIFile+WriteStrategy.swift
    Explore.swift
    Platform.swift
    Run.swift
    WAST.swift
    Wasm2wat.swift
    Wat2wasm.swift
)

target_link_wasmkit_libraries(CLICommands PUBLIC
  WAT WasmKitWASI WasmKitWASIThreads WASI WASTRunner)

add_dependencies(
  CLICommands

  ArgumentParser
)

target_link_libraries(CLICommands

  PUBLIC
  ArgumentParser
)
