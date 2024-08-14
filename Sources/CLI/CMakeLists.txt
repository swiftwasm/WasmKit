add_executable(wasmkit-cli
    Commands/Run.swift
    Commands/Explore.swift
    CLI.swift
)

target_link_wasmkit_libraries(wasmkit-cli PUBLIC
  ArgumentParser WasmKitWASI)

install(TARGETS wasmkit-cli
  RUNTIME DESTINATION bin)
