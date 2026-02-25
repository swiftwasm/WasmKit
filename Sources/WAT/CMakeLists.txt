add_wasmkit_library(WAT
  BinaryEncoding/BinaryInstructionEncoder.swift
  BinaryEncoding/Encoder.swift
  Lexer.swift
  NameMapping.swift
  ParseTextInstruction.swift
  Parser.swift
  Parser/ExpressionParser.swift
  Parser/WastParser.swift
  Parser/WatParser.swift
  Printer/ModuleCollector.swift
  Printer/TextInstructionVisitor.swift
  Printer/WatPrinter.swift
  WAT.swift
)

target_link_wasmkit_libraries(WAT PUBLIC
  WasmParser)
