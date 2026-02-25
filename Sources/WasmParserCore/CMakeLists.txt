add_wasmkit_library(WasmParserCore
  Stream/ByteStream.swift
  BinaryInstructionDecoder.swift
  ComponentParser.swift
  InstructionVisitor.swift
  LEB.swift
  ParsingLimits.swift
  WasmKitError.swift
  WasmParserCore.swift
  WasmTypes.swift
)

target_link_wasmkit_libraries(WasmParserCore PUBLIC
  WasmTypes SystemPackage)
