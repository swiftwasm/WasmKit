add_wasmkit_library(WASTRunner
  Spectest.swift
  TestCase.swift
)

target_link_wasmkit_libraries(WASTRunner PUBLIC
  _CWasmKit
  WAT
  WasmKit
  WasmParser
  WasmTypes
)
