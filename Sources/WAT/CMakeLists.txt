add_wasmkit_library(WAT
  BinaryEncoding/BinaryInstructionEncoder.swift
  BinaryEncoding/Encoder.swift
  Lexer.swift
  Location.swift
  NameMapping.swift
  ParseTextInstruction.swift
  Parser.swift
  Parser/ExpressionParser.swift
  Parser/WASTParser.swift
  Parser/WatParser.swift
  Printer/IdentifierTable.swift
  Printer/InstructionMnemonics.swift
  Printer/ModuleInfo.swift
  Printer/ModuleNames.swift
  Printer/TextFormatting.swift
  Printer/TextInstructionVisitor.swift
  Printer/WatPrinter.swift
  WAT.swift
  WatParserError.swift
)

target_link_wasmkit_libraries(WAT PUBLIC
  WasmParser)
