add_wasmkit_library(WasmParserCore
  Stream/ByteStream.swift
  Stream/Stream.swift
  BinaryInstructionDecoder.swift
  InstructionVisitor.swift
  LEB.swift
  ParsingLimits.swift
  WasmParserCore.swift
  WasmTypes.swift
)

target_link_wasmkit_libraries(WasmParserCore PUBLIC
  WasmTypes SystemPackage)
