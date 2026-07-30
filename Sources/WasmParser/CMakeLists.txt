add_wasmkit_library(WasmParser
  Platform/FileIO.swift
  Stream/ByteStream.swift
  Stream/FileHandleStream.swift
  BinaryInstructionDecoder.swift
  InstructionVisitor.swift
  LEB.swift
  ParsingLimits.swift
  WasmParserError.swift
  WasmParser.swift
  WasmTypes.swift
)

target_link_wasmkit_libraries(WasmParser PUBLIC
  WasmTypes)

if(WASMKIT_ENABLE_FILESYSTEM)
  target_compile_options(WasmParser PRIVATE
    $<$<COMPILE_LANGUAGE:Swift>:-DFileSystem>)
endif()

