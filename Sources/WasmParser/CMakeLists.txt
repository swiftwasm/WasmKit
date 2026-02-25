add_wasmkit_library(WasmParser
  FileHandleStream.swift
  WasmParser.swift
  ComponentParser.swift
)

target_link_wasmkit_libraries(WasmParser PUBLIC
  WasmParserCore)
