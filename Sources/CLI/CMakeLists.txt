add_executable(wasmkit
    Commands/Explore.swift
    Commands/Run.swift
    Commands/Wat2wasm.swift
    CLI.swift
)

target_link_wasmkit_libraries(wasmkit PUBLIC
  ArgumentParser WAT WasmKitWASI)

install(TARGETS wasmkit
  RUNTIME DESTINATION bin)
