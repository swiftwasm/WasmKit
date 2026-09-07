add_wasmkit_library(WasmKitWASIThreads
  PlatformThread.swift
  WASIThreads.swift
)

target_compile_definitions(WasmKitWASIThreads PRIVATE
  MultiThread
)

target_link_wasmkit_libraries(WasmKitWASIThreads PUBLIC
  WasmKit
)

target_link_libraries(WasmKitWASIThreads PUBLIC
  CWasmKitWASIThreads
)
