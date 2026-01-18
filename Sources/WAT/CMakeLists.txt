add_wasmkit_library(WAT
  BinaryInstructionEncoder.swift
  Encoder.swift
  Lexer.swift
  Location.swift
  NameMapping.swift
  ParseTextInstruction.swift
  Parser.swift
  Parser/ExpressionParser.swift
  Parser/WastParser.swift
  Parser/WatParser.swift
  WAT.swift
)

target_link_wasmkit_libraries(WAT PUBLIC
  WasmParserCore)
