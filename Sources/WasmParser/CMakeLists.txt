add_wasmkit_library(WasmParser
  FileHandleStream.swift
)

target_link_wasmkit_libraries(WasmParser PUBLIC
  WasmParserCore)
