add_wasmkit_library(WasmKitTests
  Spectest/Spectest.swift
  Spectest/TestCase.swift
)

target_link_wasmkit_libraries(WasmKitTests PUBLIC
  _CWasmKit
  WAT
  WasmKit
  WasmParser
  WasmTypes
  SystemExtras
  SystemPackage
)
