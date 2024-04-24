add_executable(wasmkit-cli
    Run/Run.swift
    CLI.swift
)

target_link_wasmkit_libraries(wasmkit-cli PUBLIC
  ArgumentParser WasmKitWASI)

install(TARGETS wasmkit-cli
  RUNTIME DESTINATION bin)
