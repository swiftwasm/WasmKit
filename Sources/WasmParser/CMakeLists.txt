add_wasmkit_library(WasmParser
  Stream/ByteStream.swift
  Stream/FileHandleStream.swift
  BinaryInstructionDecoder.swift
  InstructionVisitor.swift
  LEB.swift
  Parser+Streaming.swift
  ParsingLimits.swift
  SectionSkim.swift
  WasmParserError.swift
  WasmParser.swift
  WasmTypes.swift
)

target_link_wasmkit_libraries(WasmParser PUBLIC
  WasmTypes SystemPackage)
