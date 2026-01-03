add_executable(wasmkit-cli
    Commands/Explore.swift
    Commands/Run.swift
    Commands/Wat2wasm.swift
    CLI.swift
)

target_link_wasmkit_libraries(wasmkit-cli PUBLIC
  ArgumentParser WAT WasmKitWASI)

install(TARGETS wasmkit-cli
  RUNTIME DESTINATION bin)
