add_wasmkit_library(WasmParser
  Stream/ByteStream.swift
  Stream/FileHandleStream.swift
  Stream/Stream.swift
  InstructionCode.swift
  InstructionVisitor.swift
  LEB.swift
  ParsingLimits.swift
  WasmParser.swift
  WasmTypes.swift
)

target_link_wasmkit_libraries(WasmParser PUBLIC
  WasmTypes SystemPackage)
