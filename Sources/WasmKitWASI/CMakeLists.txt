add_wasmkit_library(WasmKitWASI
  WASIBridgeToHost+WasmKit.swift
  WASIConfiguration.swift
)

target_link_wasmkit_libraries(WasmKitWASI PUBLIC
  WasmKit WASI)
