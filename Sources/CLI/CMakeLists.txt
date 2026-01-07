add_executable(wasmkit
    CLI.swift
)

target_compile_options(wasmkit PRIVATE
    -package-name WasmKitPackage
)

target_link_wasmkit_libraries(wasmkit PUBLIC
  CLICommands)

install(TARGETS wasmkit
  RUNTIME DESTINATION bin)
