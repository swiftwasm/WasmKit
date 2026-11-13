add_wasmkit_library(WAT
  BinaryEncoding/BinaryInstructionEncoder.swift
  BinaryEncoding/Encoder.swift
  Lexer.swift
  Location.swift
  NameToIndexResolver.swift
  ParseTextInstruction.swift
  Parser.swift
  Parser/ExpressionParser.swift
  Parser/WASTParser.swift
  Parser/WatParser.swift
  Printer/IndexToNameResolver.swift
  Printer/ModuleInfo.swift
  Printer/TextFormatting.swift
  Printer/TextInstructionPrinter.swift
  Printer/TextInstructionVisitor.swift
  Printer/WatPrinter.swift
  WAT.swift
  WatParserError.swift
)

target_link_wasmkit_libraries(WAT PUBLIC
  WasmParser)
