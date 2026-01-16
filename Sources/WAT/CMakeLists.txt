add_wasmkit_library(WAT
  BinaryEncoding/BinaryInstructionEncoder.swift
  BinaryEncoding/Encoder.swift
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
  WasmParser)
