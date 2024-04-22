add_wasmkit_library(WasmKitWASI
  WASIBridgeToHost+WasmKit.swift
)

target_link_wasmkit_libraries(WasmKitWASI PUBLIC
  WasmKit WASI)
