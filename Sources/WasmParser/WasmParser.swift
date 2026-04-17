import WasmTypes

import struct SystemPackage.FileDescriptor
import struct SystemPackage.FilePath

#if os(Windows)
    import ucrt
#endif

/// A streaming parser for WebAssembly binary format.
///
/// The parser is designed to be used to incrementally parse a WebAssembly binary bytestream.
public struct Parser<Stream: ByteStream> {
    @usableFromInline
    let stream: Stream
    @usableFromInline let limits: ParsingLimits
    @usableFromInline var orderTracking = OrderTracking()

    @usableFromInline
    enum NextParseTarget {
        case header
        case section
    }
    @usableFromInline
    var nextParseTarget: NextParseTarget

    public let features: WasmFeatureSet
    public var offset: Int {
        return stream.currentIndex
    }

    public init(stream: Stream, features: WasmFeatureSet = .default) {
        self.stream = stream
        self.features = features
        self.nextParseTarget = .header
        self.limits = .default
    }

    @usableFromInline
    internal func makeError(_ message: WasmParserError.Message) -> WasmParserError {
        return WasmParserError(message: message, offset: offset)
    }
}

extension Parser where Stream == StaticByteStream {

    /// Initialize a new parser with the given bytes
    ///
    /// - Parameters:
    ///   - bytes: The bytes of the WebAssembly binary file to parse
    ///   - features: Enabled WebAssembly features for parsing
    public init(bytes: [UInt8], features: WasmFeatureSet = .default) {
        self.init(stream: StaticByteStream(bytes: bytes), features: features)
    }
}

extension Parser where Stream == FileHandleStream {

    /// Initialize a new parser with the given file handle
    ///
    /// - Parameters:
    ///   - fileHandle: The file handle to the WebAssembly binary file to parse
    ///   - features: Enabled WebAssembly features for parsing
    public init(fileHandle: FileDescriptor, features: WasmFeatureSet = .default) throws {
        self.init(stream: try FileHandleStream(fileHandle: fileHandle), features: features)
    }

    /// Initialize a new parser with the given file path
    ///
    /// - Parameters:
    ///   - filePath: The file path to the WebAssembly binary file to parse
    ///   - features: Enabled WebAssembly features for parsing
    public init(filePath: FilePath, features: WasmFeatureSet = .default) throws {
        #if os(Windows)
            // TODO: Upstream `O_BINARY` to `SystemPackage
            let accessMode = FileDescriptor.AccessMode(
                rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_BINARY
            )
        #else
            let accessMode: FileDescriptor.AccessMode = .readOnly
        #endif
        let fileHandle = try FileDescriptor.open(filePath, accessMode)
        self.init(stream: try FileHandleStream(fileHandle: fileHandle), features: features)
    }
}

@_documentation(visibility: internal)
public struct ExpressionParser {
    /// The byte offset of the code in the module
    let codeOffset: Int
    /// The initial byte offset of the code buffer stream
    /// NOTE: This might be different from `codeOffset` if the code buffer
    /// is not a part of the initial `FileHandleStream` buffer
    let initialStreamOffset: Int
    @usableFromInline
    var parser: Parser<StaticByteStream>

    /// Whether the final `end` opcode has been returned. We track this explicitly
    /// rather than checking `hasReachedEnd()` upfront because an exhausted stream
    /// without a preceding `end` opcode is a validation error, not a normal exit.
    @usableFromInline
    var reachedEnd: Bool

    public var offset: Int {
        self.codeOffset + self.parser.offset - self.initialStreamOffset
    }

    public init(code: Code) {
        self.parser = Parser(
            stream: StaticByteStream(bytes: code.expression),
            features: code.features
        )
        self.codeOffset = code.offset
        self.initialStreamOffset = self.parser.offset
        self.reachedEnd = false
    }

    /// Parse the next instruction. Returns nil when expression is complete (end opcode reached at top level).
    @inlinable
    public mutating func parse() throws(WasmParserError) -> Visit? {
        if reachedEnd { return nil }
        let instructionOffset = offset
        let instruction = try parser.parseInstruction()
        if case .end = instruction, try parser.stream.hasReachedEnd() {
            reachedEnd = true
        }
        return Visit(instruction: instruction, offset: instructionOffset)
    }

    /// A parsed instruction ready to be dispatched to a visitor.
    public struct Visit {
        @usableFromInline
        let instruction: Instruction
        @usableFromInline
        let offset: Int

        @usableFromInline
        init(instruction: Instruction, offset: Int) {
            self.instruction = instruction
            self.offset = offset
        }

        @inlinable
        public func callAsFunction<V: InstructionVisitor & ~Copyable>(
            visitor: inout V
        ) throws(V.VisitorError) {
            visitor.binaryOffset = offset
            try dispatchInstruction(instruction, to: &visitor)
        }
    }
}

let WASM_MAGIC: [UInt8] = [0x00, 0x61, 0x73, 0x6D]

/// Flags for enabling/disabling WebAssembly features
public struct WasmFeatureSet: OptionSet, Sendable {
    /// The raw value of the feature set
    public let rawValue: Int

    /// Initialize a new feature set with the given raw value
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The WebAssembly memory64 proposal
    @_alwaysEmitIntoClient
    public static var memory64: WasmFeatureSet { WasmFeatureSet(rawValue: 1 << 0) }
    /// The WebAssembly reference types proposal
    @_alwaysEmitIntoClient
    public static var referenceTypes: WasmFeatureSet { WasmFeatureSet(rawValue: 1 << 1) }
    /// The WebAssembly threads proposal
    @_alwaysEmitIntoClient
    public static var threads: WasmFeatureSet { WasmFeatureSet(rawValue: 1 << 2) }
    /// The WebAssembly tail-call proposal
    @_alwaysEmitIntoClient
    public static var tailCall: WasmFeatureSet { WasmFeatureSet(rawValue: 1 << 3) }
    /// The WebAssembly SIMD proposal
    @_alwaysEmitIntoClient
    public static var simd: WasmFeatureSet { WasmFeatureSet(rawValue: 1 << 4) }

    /// The default feature set
    public static let `default`: WasmFeatureSet = [.referenceTypes]
    /// The feature set with all features enabled
    public static let all: WasmFeatureSet = [.memory64, .referenceTypes, .threads, .tailCall, .simd]
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/conventions.html#vectors>
extension ByteStream {
    @inlinable
    func parseVector<Content>(content parser: () throws(WasmParserError) -> Content) throws(WasmParserError) -> [Content] {
        var contents = [Content]()
        let count: UInt32 = try parseUnsigned()
        for _ in 0..<count {
            try contents.append(parser())
        }
        return contents
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#integers>
extension ByteStream {
    @inlinable
    func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws(WasmParserError) -> T {
        try decodeLEB128(stream: self)
    }

    @inlinable
    func parseSigned<T: FixedWidthInteger & RawSignedInteger>() throws(WasmParserError) -> T {
        try decodeLEB128(stream: self)
    }

    @usableFromInline
    func parseVarSigned33() throws(WasmParserError) -> Int64 {
        try decodeLEB128(stream: self, bitWidth: 33)
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#names>
extension ByteStream {
    package func parseName() throws(WasmParserError) -> String {
        let bytes = try parseVector { () throws(WasmParserError) -> UInt8 in
            try consumeAny()
        }

        // TODO(optimize): Utilize ASCII fast path in UTF8 decoder
        var name = ""

        var iterator = bytes.makeIterator()
        var decoder = UTF8()
        Decode: while true {
            switch decoder.decode(&iterator) {
            case .scalarValue(let scalar): name.append(Character(scalar))
            case .emptyInput: break Decode
            case .error: throw WasmParserError(message: .invalidUTF8(bytes), offset: currentIndex)
            }
        }

        return name
    }
}

extension Parser {
    @inlinable
    func parseVector<Content>(content parser: () throws(WasmParserError) -> Content) throws(WasmParserError) -> [Content] {
        try stream.parseVector(content: parser)
    }

    @inline(__always)
    @inlinable
    func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws(WasmParserError) -> T {
        try stream.parseUnsigned(T.self)
    }

    @inlinable
    func parseInteger<T: RawUnsignedInteger>() throws(WasmParserError) -> T {
        let signed: T.Signed = try stream.parseSigned()
        return T(bitPattern: signed)
    }

    func parseName() throws(WasmParserError) -> String {
        try stream.parseName()
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#floating-point>
extension Parser {
    @usableFromInline
    func parseFloat() throws(WasmParserError) -> UInt32 {
        let consumedLittleEndian = try stream.consume(count: 4).reversed()
        let bitPattern = consumedLittleEndian.reduce(UInt32(0)) { acc, byte in
            acc << 8 + UInt32(byte)
        }
        return bitPattern
    }

    @usableFromInline
    func parseDouble() throws(WasmParserError) -> UInt64 {
        let consumedLittleEndian = try stream.consume(count: 8).reversed()
        let bitPattern = consumedLittleEndian.reduce(UInt64(0)) { acc, byte in
            acc << 8 + UInt64(byte)
        }
        return bitPattern
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/types.html#types>
extension Parser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#value-types>
    @usableFromInline
    func parseValueType() throws(WasmParserError) -> ValueType {
        let b = try stream.consumeAny()

        switch b {
        case 0x7F: return .i32
        case 0x7E: return .i64
        case 0x7D: return .f32
        case 0x7C: return .f64
        case 0x7B: return .v128
        default:
            guard let refType = try parseReferenceType(byte: b) else {
                throw makeError(.malformedValueType(b))
            }
            return .ref(refType)
        }
    }

    /// - Returns: `nil` if the given `byte` discriminator is malformed
    /// > Note:
    /// <https://webassembly.github.io/function-references/core/binary/types.html#reference-types>
    @usableFromInline
    func parseReferenceType(byte: UInt8) throws(WasmParserError) -> ReferenceType? {
        switch byte {
        case 0x63: return try ReferenceType(isNullable: true, heapType: parseHeapType())
        case 0x64: return try ReferenceType(isNullable: false, heapType: parseHeapType())
        case 0x6F: return .externRef
        case 0x70: return .funcRef
        default: return nil  // invalid discriminator
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/function-references/core/binary/types.html#heap-types>
    @usableFromInline
    func parseHeapType() throws(WasmParserError) -> HeapType {
        let b = try stream.peek()
        switch b {
        case 0x6F:
            _ = try stream.consumeAny()
            return .externRef
        case 0x70:
            _ = try stream.consumeAny()
            return .funcRef
        default:
            let rawIndex = try stream.parseVarSigned33()
            guard let index = TypeIndex(exactly: rawIndex) else {
                throw makeError(.invalidFunctionType(rawIndex))
            }
            return .concrete(typeIndex: index)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#result-types>
    @inlinable
    func parseResultType() throws(WasmParserError) -> BlockType {
        guard let nextByte = try stream.peek() else {
            throw makeError(.unexpectedEnd)
        }
        switch nextByte {
        case 0x40:
            _ = try stream.consumeAny()
            return .empty
        case 0x7B...0x7F, 0x70, 0x6F:
            return try .type(parseValueType())
        default:
            let rawIndex = try stream.parseVarSigned33()
            guard let index = TypeIndex(exactly: rawIndex) else {
                throw makeError(.invalidFunctionType(rawIndex))
            }
            return .funcType(index)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#function-types>
    @inlinable
    func parseFunctionType() throws(WasmParserError) -> FunctionType {
        let opcode = try stream.consumeAny()

        // XXX: spectest expects the first byte should be parsed as a LEB128 with 1 byte limit
        // but the spec itself doesn't require it, so just check the continue bit of LEB128 here.
        guard opcode & 0b10000000 == 0 else {
            throw makeError(.integerRepresentationTooLong)
        }
        guard opcode == 0x60 else {
            throw makeError(.malformedFunctionType(opcode))
        }

        let parameters = try parseVector { () throws(WasmParserError) in try parseValueType() }
        let results = try parseVector { () throws(WasmParserError) in try parseValueType() }
        return FunctionType(parameters: parameters, results: results)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#limits>
    @usableFromInline
    func parseLimits() throws(WasmParserError) -> Limits {
        let b = try stream.consumeAny()
        let sharedMask: UInt8 = 0b0010
        let isMemory64Mask: UInt8 = 0b0100

        let hasMax = b & 0b0001 != 0
        let shared = b & sharedMask != 0
        let isMemory64 = b & isMemory64Mask != 0

        var flagMask: UInt8 = 0b0001
        if features.contains(.threads) {
            flagMask |= sharedMask
        }
        if features.contains(.memory64) {
            flagMask |= isMemory64Mask
        }
        guard (b & ~flagMask) == 0 else {
            throw makeError(.malformedLimit(b))
        }

        let min: UInt64
        if isMemory64 {
            min = try parseUnsigned(UInt64.self)
        } else {
            min = try UInt64(parseUnsigned(UInt32.self))
        }
        var max: UInt64?
        if hasMax {
            if isMemory64 {
                max = try parseUnsigned(UInt64.self)
            } else {
                max = try UInt64(parseUnsigned(UInt32.self))
            }
        }
        return Limits(min: min, max: max, isMemory64: isMemory64, shared: shared)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#memory-types>
    func parseMemoryType() throws(WasmParserError) -> MemoryType {
        return try parseLimits()
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#table-types>
    @inlinable
    func parseTableType() throws(WasmParserError) -> TableType {
        let elementType: ReferenceType
        let b = try stream.consumeAny()

        switch b {
        case 0x70:
            elementType = .funcRef
        case 0x6F:
            elementType = .externRef
        default:
            throw WasmParserError(
                kind: .parserUnexpectedByte(b, expected: [0x6F, 0x70]),
                offset: stream.currentIndex
            )
        }

        let limits = try parseLimits()
        return TableType(elementType: elementType, limits: limits)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#global-types>
    @inlinable
    func parseGlobalType() throws(WasmParserError) -> GlobalType {
        let valueType = try parseValueType()
        let mutability = try parseMutability()
        return GlobalType(mutability: mutability, valueType: valueType)
    }

    @inlinable
    func parseMutability() throws(WasmParserError) -> Mutability {
        let b = try stream.consumeAny()
        switch b {
        case 0x00:
            return .constant
        case 0x01:
            return .variable
        default:
            throw makeError(.malformedMutability(b))
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/instructions.html#memory-instructions>
    @inlinable
    func parseMemarg() throws(WasmParserError) -> MemArg {
        let align: UInt32 = try parseUnsigned()
        let offset: UInt64 = try features.contains(.memory64) ? parseUnsigned(UInt64.self) : UInt64(parseUnsigned(UInt32.self))
        return MemArg(offset: offset, align: align)
    }

    @inlinable func parseVectorBytes() throws(WasmParserError) -> ArraySlice<UInt8> {
        let count: UInt32 = try parseUnsigned()
        return try stream.consume(count: Int(count))
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html>
extension Parser: BinaryInstructionDecoder {
    @inlinable func parseMemoryIndex() throws(WasmParserError) -> UInt32 {
        let zero = try stream.consumeAny()
        guard zero == 0x00 else {
            throw makeError(.zeroExpected(actual: zero))
        }
        return 0
    }

    @inlinable func throwUnknown(_ opcode: [UInt8]) throws(WasmParserError) -> Never {
        throw makeError(.illegalOpcode(opcode))
    }

    @inlinable func visitUnknown(_ opcode: [UInt8]) throws(WasmParserError) -> Bool {
        try throwUnknown(opcode)
    }

    @inlinable mutating func visitBlock() throws(WasmParserError) -> BlockType { try parseResultType() }
    @inlinable mutating func visitLoop() throws(WasmParserError) -> BlockType { try parseResultType() }
    @inlinable mutating func visitIf() throws(WasmParserError) -> BlockType { try parseResultType() }
    @inlinable mutating func visitBr() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitBrIf() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitBrTable() throws(WasmParserError) -> BrTable {
        let labelIndices: [UInt32] = try parseVector { () throws(WasmParserError) in try parseUnsigned() }
        let labelIndex: UInt32 = try parseUnsigned()
        return BrTable(labelIndices: labelIndices, defaultIndex: labelIndex)
    }
    @inlinable mutating func visitCall() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitCallRef() throws(WasmParserError) -> UInt32 {
        // TODO reference types checks
        // traps on nil
        try parseUnsigned()
    }

    @inlinable mutating func visitCallIndirect() throws(WasmParserError) -> (typeIndex: UInt32, tableIndex: UInt32) {
        let typeIndex: TypeIndex = try parseUnsigned()
        let peek = try stream.peek()

        if !features.contains(.referenceTypes) && peek != 0 {
            // Check that reserved byte is zero when reference-types is disabled
            throw makeError(.malformedIndirectCall)
        }
        let tableIndex: TableIndex = try parseUnsigned()
        return (typeIndex, tableIndex)
    }

    @inlinable mutating func visitReturnCall() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }

    @inlinable mutating func visitReturnCallIndirect() throws(WasmParserError) -> (typeIndex: UInt32, tableIndex: UInt32) {
        let typeIndex: TypeIndex = try parseUnsigned()
        let tableIndex: TableIndex = try parseUnsigned()
        return (typeIndex, tableIndex)
    }

    @inlinable mutating func visitReturnCallRef() throws(WasmParserError) -> UInt32 {
        return 0
    }

    @inlinable mutating func visitTypedSelect() throws(WasmParserError) -> WasmTypes.ValueType {
        let results = try parseVector { () throws(WasmParserError) in try parseValueType() }
        guard results.count == 1 else {
            throw makeError(.invalidResultArity(expected: 1, actual: results.count))
        }
        return results[0]
    }

    @inlinable mutating func visitLocalGet() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitLocalSet() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitLocalTee() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitGlobalGet() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitGlobalSet() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitLoad(_: Instruction.Load) throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitStore(_: Instruction.Store) throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitMemorySize() throws(WasmParserError) -> UInt32 {
        try parseMemoryIndex()
    }
    @inlinable mutating func visitMemoryGrow() throws(WasmParserError) -> UInt32 {
        try parseMemoryIndex()
    }
    @inlinable mutating func visitI32Const() throws(WasmParserError) -> Int32 {
        let n: UInt32 = try parseInteger()
        return Int32(bitPattern: n)
    }
    @inlinable mutating func visitI64Const() throws(WasmParserError) -> Int64 {
        let n: UInt64 = try parseInteger()
        return Int64(bitPattern: n)
    }
    @inlinable mutating func visitF32Const() throws(WasmParserError) -> IEEE754.Float32 {
        let n = try parseFloat()
        return IEEE754.Float32(bitPattern: n)
    }
    @inlinable mutating func visitF64Const() throws(WasmParserError) -> IEEE754.Float64 {
        let n = try parseDouble()
        return IEEE754.Float64(bitPattern: n)
    }
    @inlinable mutating func visitRefNull() throws(WasmParserError) -> WasmTypes.HeapType {
        return try parseHeapType()
    }
    @inlinable mutating func visitBrOnNull() throws(WasmParserError) -> UInt32 {
        return 0
    }
    @inlinable mutating func visitBrOnNonNull() throws(WasmParserError) -> UInt32 {
        return 0
    }

    @inlinable mutating func visitRefFunc() throws(WasmParserError) -> UInt32 { try parseUnsigned() }
    @inlinable mutating func visitMemoryInit() throws(WasmParserError) -> UInt32 {
        let dataIndex: DataIndex = try parseUnsigned()
        _ = try parseMemoryIndex()
        return dataIndex
    }

    @inlinable mutating func visitDataDrop() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }

    @inlinable mutating func visitMemoryCopy() throws(WasmParserError) -> (dstMem: UInt32, srcMem: UInt32) {
        _ = try parseMemoryIndex()
        _ = try parseMemoryIndex()
        return (0, 0)
    }

    @inlinable mutating func visitMemoryFill() throws(WasmParserError) -> UInt32 {
        let zero = try stream.consumeAny()
        guard zero == 0x00 else {
            throw makeError(.zeroExpected(actual: zero))
        }
        return 0
    }

    @inlinable mutating func visitTableInit() throws(WasmParserError) -> (elemIndex: UInt32, table: UInt32) {
        let elementIndex: ElementIndex = try parseUnsigned()
        let tableIndex: TableIndex = try parseUnsigned()
        return (elementIndex, tableIndex)
    }
    @inlinable mutating func visitElemDrop() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }
    @inlinable mutating func visitTableCopy() throws(WasmParserError) -> (dstTable: UInt32, srcTable: UInt32) {
        let destination: TableIndex = try parseUnsigned()
        let source: TableIndex = try parseUnsigned()
        return (destination, source)
    }
    @inlinable mutating func visitTableFill() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }
    @inlinable mutating func visitTableGet() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }
    @inlinable mutating func visitTableSet() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }
    @inlinable mutating func visitTableGrow() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }
    @inlinable mutating func visitTableSize() throws(WasmParserError) -> UInt32 {
        try parseUnsigned()
    }
    @inlinable mutating func visitMemoryAtomicNotify() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitMemoryAtomicWait32() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitMemoryAtomicWait64() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmwAdd() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmwAdd() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw8AddU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw16AddU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw8AddU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw16AddU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw32AddU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmwSub() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmwSub() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw8SubU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw16SubU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw8SubU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw16SubU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw32SubU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmwAnd() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmwAnd() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw8AndU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw16AndU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw8AndU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw16AndU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw32AndU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmwOr() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmwOr() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw8OrU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw16OrU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw8OrU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw16OrU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw32OrU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmwXor() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmwXor() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw8XorU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw16XorU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw8XorU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw16XorU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw32XorU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmwXchg() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmwXchg() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw8XchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw16XchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw8XchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw16XchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw32XchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmwCmpxchg() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmwCmpxchg() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw8CmpxchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI32AtomicRmw16CmpxchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw8CmpxchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw16CmpxchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitI64AtomicRmw32CmpxchgU() throws(WasmParserError) -> MemArg { try parseMemarg() }
    @inlinable mutating func visitV128Const() throws(WasmParserError) -> V128 {
        return V128(bytes: Array(try stream.consume(count: V128.byteCount)))
    }
    @inlinable mutating func visitI8x16Shuffle() throws(WasmParserError) -> V128ShuffleMask {
        return V128ShuffleMask(lanes: Array(try stream.consume(count: V128ShuffleMask.laneCount)))
    }
    @inlinable mutating func visitSimdLane(_: Instruction.SimdLane) throws(WasmParserError) -> UInt8 {
        return try stream.consumeAny()
    }
    @inlinable mutating func visitSimdMemLane(_: Instruction.SimdMemLane) throws(WasmParserError) -> (memarg: MemArg, lane: UInt8) {
        let memarg = try parseMemarg()
        let lane = try stream.consumeAny()
        return (memarg: memarg, lane: lane)
    }
    @inlinable func claimNextByte() throws(WasmParserError) -> UInt8 {
        return try stream.consumeAny()
    }

    /// Parse a single binary instruction.
    @inline(__always)
    @inlinable
    mutating func parseInstruction() throws(WasmParserError) -> Instruction {
        return try parseBinaryInstruction(decoder: &self)
    }

    @usableFromInline
    mutating func parseConstExpression() throws(WasmParserError) -> ConstExpression {
        var insts: [Instruction] = []
        while true {
            let instruction = try self.parseInstruction()
            insts.append(instruction)
            if case .end = instruction { break }
        }
        return insts
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#sections>
extension Parser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#custom-section>
    @usableFromInline
    func parseCustomSection(size: UInt32) throws(WasmParserError) -> CustomSection {
        let preNameIndex = stream.currentIndex
        let name = try parseName()
        let nameSize = stream.currentIndex - preNameIndex
        let contentSize = Int(size) - nameSize

        guard contentSize >= 0 else {
            throw makeError(.invalidSectionSize(size))
        }

        let bytes = try stream.consume(count: contentSize)

        return CustomSection(name: name, bytes: bytes)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#type-section>
    @inlinable
    func parseTypeSection() throws(WasmParserError) -> [FunctionType] {
        return try parseVector { () throws(WasmParserError) in try parseFunctionType() }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#import-section>
    @usableFromInline
    func parseImportSection() throws(WasmParserError) -> [Import] {
        return try parseVector { () throws(WasmParserError) in
            let module = try parseName()
            let name = try parseName()
            let descriptor = try parseImportDescriptor()
            return Import(module: module, name: name, descriptor: descriptor)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-importdesc>
    func parseImportDescriptor() throws(WasmParserError) -> ImportDescriptor {
        let b = try stream.consume(Set(0x00...0x03))
        switch b {
        case 0x00: return try .function(parseUnsigned())
        case 0x01: return try .table(parseTableType())
        case 0x02: return try .memory(parseMemoryType())
        case 0x03: return try .global(parseGlobalType())
        default:
            preconditionFailure("should never reach here")
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#function-section>
    @inlinable
    func parseFunctionSection() throws(WasmParserError) -> [TypeIndex] {
        return try parseVector { () throws(WasmParserError) in try parseUnsigned() }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#table-section>
    @usableFromInline
    func parseTableSection() throws(WasmParserError) -> [Table] {
        return try parseVector { () throws(WasmParserError) in try Table(type: parseTableType()) }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#memory-section>
    @usableFromInline
    func parseMemorySection() throws(WasmParserError) -> [Memory] {
        return try parseVector { () throws(WasmParserError) in try Memory(type: parseLimits()) }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#global-section>
    @usableFromInline
    mutating func parseGlobalSection() throws(WasmParserError) -> [Global] {
        return try parseVector { () throws(WasmParserError) in
            let type = try parseGlobalType()
            let expression = try parseConstExpression()
            return Global(type: type, initializer: expression)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#export-section>
    @usableFromInline
    func parseExportSection() throws(WasmParserError) -> [Export] {
        return try parseVector { () throws(WasmParserError) in
            let name = try parseName()
            let descriptor = try parseExportDescriptor()
            return Export(name: name, descriptor: descriptor)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-exportdesc>
    func parseExportDescriptor() throws(WasmParserError) -> ExportDescriptor {
        let b = try stream.consume(Set(0x00...0x03))
        switch b {
        case 0x00: return try .function(parseUnsigned())
        case 0x01: return try .table(parseUnsigned())
        case 0x02: return try .memory(parseUnsigned())
        case 0x03: return try .global(parseUnsigned())
        default:
            preconditionFailure("should never reach here")
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#start-section>
    @usableFromInline
    func parseStartSection() throws(WasmParserError) -> FunctionIndex {
        return try parseUnsigned()
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#element-section>
    @inlinable
    mutating func parseElementSection() throws(WasmParserError) -> [ElementSegment] {
        return try parseVector { () throws(WasmParserError) in
            let flag = try ElementSegment.Flag(rawValue: parseUnsigned())

            let type: ReferenceType
            let initializer: [ConstExpression]
            let mode: ElementSegment.Mode

            if flag.contains(.isPassiveOrDeclarative) {
                if flag.contains(.isDeclarative) {
                    mode = .declarative
                } else {
                    mode = .passive
                }
            } else {
                let table: TableIndex

                if flag.contains(.hasTableIndex) {
                    table = try parseUnsigned()
                } else {
                    table = 0
                }

                let offset = try parseConstExpression()
                mode = .active(table: table, offset: offset)
            }

            if flag.segmentHasRefType {
                let valueType = try parseValueType()

                guard case .ref(let refType) = valueType else {
                    throw makeError(.expectedRefType(actual: valueType))
                }

                type = refType
            } else {
                type = .funcRef
            }

            if flag.segmentHasElemKind {
                // `elemkind` parsing as defined in the spec
                let elemKind = try parseUnsigned() as UInt32
                guard elemKind == 0x00 else {
                    throw makeError(.unexpectedElementKind(expected: 0x00, actual: elemKind))
                }
            }

            if flag.contains(.usesExpressions) {
                initializer = try parseVector { () throws(WasmParserError) in try parseConstExpression() }
            } else {
                initializer = try parseVector { () throws(WasmParserError) in
                    try [Instruction.refFunc(functionIndex: parseUnsigned() as UInt32)]
                }
            }

            return ElementSegment(type: type, initializer: initializer, mode: mode)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#code-section>
    @inlinable
    func parseCodeSection() throws(WasmParserError) -> [Code] {
        return try parseVector { () throws(WasmParserError) in
            let size = try parseUnsigned() as UInt32
            let bodyStart = stream.currentIndex
            let localTypes = try parseVector { () throws(WasmParserError) -> (n: UInt32, type: ValueType) in
                let n: UInt32 = try parseUnsigned()
                let t = try parseValueType()
                return (n, t)
            }
            let totalLocals = localTypes.reduce(UInt64(0)) { $0 + UInt64($1.n) }
            guard totalLocals < limits.maxFunctionLocals else {
                throw makeError(.tooManyLocals(totalLocals, limit: limits.maxFunctionLocals))
            }

            let locals = localTypes.flatMap { (n: UInt32, type: ValueType) in
                return Array(repeating: type, count: Int(n))
            }
            let expressionStart = stream.currentIndex
            let expressionBytes = try stream.consume(
                count: Int(size) - (expressionStart - bodyStart)
            )
            return Code(
                locals: locals, expression: expressionBytes,
                offset: expressionStart, features: features
            )
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#data-section>
    @inlinable
    mutating func parseDataSection() throws(WasmParserError) -> [DataSegment] {
        return try parseVector { () throws(WasmParserError) in
            let kind: UInt32 = try parseUnsigned()
            switch kind {
            case 0:
                let offset = try parseConstExpression()
                let initializer = try parseVectorBytes()
                return .active(.init(index: 0, offset: offset, initializer: initializer))

            case 1:
                return try .passive(parseVectorBytes())

            case 2:
                let index: UInt32 = try parseUnsigned()
                let offset = try parseConstExpression()
                let initializer = try parseVectorBytes()
                return .active(.init(index: index, offset: offset, initializer: initializer))
            default:
                throw makeError(.malformedDataSegmentKind(kind))
            }
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#data-count-section>
    @usableFromInline
    func parseDataCountSection() throws(WasmParserError) -> UInt32 {
        return try parseUnsigned()
    }
}

public enum ParsingPayload {
    case header(version: [UInt8])
    case customSection(CustomSection)
    case typeSection([FunctionType])
    case importSection([Import])
    case functionSection([TypeIndex])
    case tableSection([Table])
    case memorySection([Memory])
    case globalSection([Global])
    case exportSection([Export])
    case startSection(FunctionIndex)
    case elementSection([ElementSegment])
    case codeSection([Code])
    case dataSection([DataSegment])
    case dataCount(UInt32)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
extension Parser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-magic>
    @usableFromInline
    func parseMagicNumber() throws(WasmParserError) {
        let magicNumber = try stream.consume(count: 4)
        guard magicNumber.elementsEqual(WASM_MAGIC) else {
            throw makeError(.invalidMagicNumber(.init(magicNumber)))
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-version>
    @usableFromInline
    func parseVersion() throws(WasmParserError) -> [UInt8] {
        let version = try Array(stream.consume(count: 4))
        guard version == [0x01, 0x00, 0x00, 0x00] else {
            throw makeError(.unknownVersion(.init(version)))
        }
        return version
    }

    @usableFromInline
    struct OrderTracking {
        @usableFromInline
        enum Order: UInt8 {
            case initial = 0
            case type
            case _import
            case function
            case table
            case memory
            case tag
            case global
            case export
            case start
            case element
            case dataCount
            case code
            case data
        }

        @usableFromInline
        var last: Order = .initial

        @inlinable
        mutating func track(order: Order, parser: Parser) throws(WasmParserError) {
            guard last.rawValue < order.rawValue else {
                throw parser.makeError(.sectionOutOfOrder)
            }
            last = order
        }
    }

    /// Attempts to parse a chunk of the Wasm binary stream.
    ///
    /// - Returns: A `ParsingPayload` if the parsing was successful, otherwise `nil`.
    ///
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
    ///
    /// The following example demonstrates how to use the `Parser` to parse a Wasm binary stream:
    ///
    /// ```swift
    /// import WasmParser
    ///
    /// var parser = Parser(bytes: [
    ///     0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60,
    ///     0x01, 0x7e, 0x01, 0x7e, 0x03, 0x02, 0x01, 0x00, 0x07, 0x07, 0x01, 0x03,
    ///     0x66, 0x61, 0x63, 0x00, 0x00, 0x0a, 0x17, 0x01, 0x15, 0x00, 0x20, 0x00,
    ///     0x50, 0x04, 0x7e, 0x42, 0x01, 0x05, 0x20, 0x00, 0x20, 0x00, 0x42, 0x01,
    ///     0x7d, 0x10, 0x00, 0x7e, 0x0b, 0x0b
    /// ])
    ///
    /// while let payload = try parser.parseNext() {
    ///     switch payload {
    ///     case .header(let version):
    ///         print("Wasm version: \(version)")
    ///     default: break
    ///     }
    /// }
    /// ```
    @inlinable
    public mutating func parseNext() throws(WasmParserError) -> ParsingPayload? {
        switch nextParseTarget {
        case .header:
            try parseMagicNumber()
            let version = try parseVersion()
            self.nextParseTarget = .section
            return .header(version: version)
        case .section:
            guard try !stream.hasReachedEnd() else {
                return nil
            }
            let sectionID = try stream.consumeAny()
            let sectionSize: UInt32 = try parseUnsigned()
            let sectionStart = stream.currentIndex

            let payload: ParsingPayload
            let order: OrderTracking.Order?
            switch sectionID {
            case 0:
                order = nil
                payload = .customSection(try parseCustomSection(size: sectionSize))
            case 1:
                order = .type
                payload = .typeSection(try parseTypeSection())
            case 2:
                order = ._import
                payload = .importSection(try parseImportSection())
            case 3:
                order = .function
                payload = .functionSection(try parseFunctionSection())
            case 4:
                order = .table
                payload = .tableSection(try parseTableSection())
            case 5:
                order = .memory
                payload = .memorySection(try parseMemorySection())
            case 6:
                order = .global
                payload = .globalSection(try parseGlobalSection())
            case 7:
                order = .export
                payload = .exportSection(try parseExportSection())
            case 8:
                order = .start
                payload = .startSection(try parseStartSection())
            case 9:
                order = .element
                payload = .elementSection(try parseElementSection())
            case 10:
                order = .code
                payload = .codeSection(try parseCodeSection())
            case 11:
                order = .data
                payload = .dataSection(try parseDataSection())
            case 12:
                order = .dataCount
                payload = .dataCount(try parseDataCountSection())
            default:
                throw makeError(.malformedSectionID(sectionID))
            }
            if let order = order {
                try orderTracking.track(order: order, parser: self)
            }
            let expectedSectionEnd = sectionStart + Int(sectionSize)
            guard expectedSectionEnd == stream.currentIndex else {
                throw makeError(
                    .sectionSizeMismatch(
                        sectionID: sectionID,
                        expected: expectedSectionEnd,
                        actual: offset
                    )
                )
            }
            return payload
        }
    }
}

/// A map of names by its index.
public typealias NameMap = [UInt32: String]

/// Parsed names from a name section subsection.
public enum ParsedNames {
    /// Subsection 0: Module name.
    case moduleName(String)
    /// Subsection 1: Function names.
    case functions(NameMap)
    /// Subsection 2: Local names (funcIndex → [localIndex → name]).
    case locals([UInt32: NameMap])
    /// Subsection 3: Label names (funcIndex → [labelIndex → name]).
    case labels([UInt32: NameMap])
    /// Subsection 4: Type names.
    case types(NameMap)
    /// Subsection 5: Table names.
    case tables(NameMap)
    /// Subsection 6: Memory names.
    case memories(NameMap)
    /// Subsection 7: Global names.
    case globals(NameMap)
    /// Subsection 8: Element segment names.
    case elements(NameMap)
    /// Subsection 9: Data segment names.
    case dataSegments(NameMap)
}

/// A parser for the name custom section.
///
/// > Note: <https://webassembly.github.io/spec/core/appendix/custom.html#name-section>
public struct NameSectionParser<Stream: ByteStream> {
    let stream: Stream

    public init(stream: Stream) {
        self.stream = stream
    }

    /// Parses the entire name section.
    ///
    /// - Throws: If the stream is malformed or the section is invalid.
    /// - Returns: A list of parsed names.
    public func parseAll() throws(WasmParserError) -> [ParsedNames] {
        var results: [ParsedNames] = []
        while try !stream.hasReachedEnd() {
            let id = try stream.consumeAny()
            guard let result = try parseNameSubsection(type: id) else {
                continue
            }
            results.append(result)
        }
        return results
    }

    func parseNameSubsection(type: UInt8) throws(WasmParserError) -> ParsedNames? {
        let size = try stream.parseUnsigned(UInt32.self)
        switch type {
        case 0: return .moduleName(try stream.parseName())
        case 1: return .functions(try parseNameMap())
        case 2: return .locals(try parseIndirectNameMap())
        case 3: return .labels(try parseIndirectNameMap())
        case 4: return .types(try parseNameMap())
        case 5: return .tables(try parseNameMap())
        case 6: return .memories(try parseNameMap())
        case 7: return .globals(try parseNameMap())
        case 8: return .elements(try parseNameMap())
        case 9: return .dataSegments(try parseNameMap())
        default:
            _ = try stream.consume(count: Int(size))
            return nil
        }
    }

    func parseNameMap() throws(WasmParserError) -> NameMap {
        var nameMap: NameMap = [:]
        _ = try stream.parseVector { () throws(WasmParserError) in
            let index = try stream.parseUnsigned(UInt32.self)
            let name = try stream.parseName()
            nameMap[index] = name
        }
        return nameMap
    }

    func parseIndirectNameMap() throws(WasmParserError) -> [UInt32: NameMap] {
        var map: [UInt32: NameMap] = [:]
        _ = try stream.parseVector { () throws(WasmParserError) in
            let outerIndex = try stream.parseUnsigned(UInt32.self)
            map[outerIndex] = try parseNameMap()
        }
        return map
    }
}

// MARK: - File Type Detection

/// The type of a WebAssembly binary file.
public enum WasmFileType: Equatable, Sendable {
    /// A core WebAssembly module (version 1)
    case coreModule
    /// A WebAssembly component (version 0x0d, layer 1)
    case component
    /// Unknown or invalid WebAssembly file
    case unknown
}

/// Detect the type of a WebAssembly binary file by reading its header.
///
/// This function reads the 8-byte WebAssembly header to determine whether
/// the file contains a core module or a component. Uses stack allocation
/// only (no heap allocation for the header bytes).
///
/// - Parameter filePath: Path to the WebAssembly binary file
/// - Returns: The detected file type
/// - Throws: If the file cannot be opened or read
public func detectWasmFileType(filePath: FilePath) throws -> WasmFileType {
    let fileHandle = try FileDescriptor.open(filePath, .readOnly)
    defer { try? fileHandle.close() }

    // Use a tuple to avoid heap allocation - 8 bytes on stack
    // TODO: needs a `SmallArray` abstraction until `InlineArray` becomes available after dropping support for macOS 15.
    var header: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0)
    let bytesRead = try withUnsafeMutableBytes(of: &header) { buffer in
        try fileHandle.read(into: buffer)
    }

    // Need at least 8 bytes for a valid header
    guard bytesRead >= 8 else {
        return .unknown
    }

    // Check magic number: \0asm (uses WASM_MAGIC as source of truth)
    guard
        header.0 == WASM_MAGIC[0] && header.1 == WASM_MAGIC[1]
            && header.2 == WASM_MAGIC[2] && header.3 == WASM_MAGIC[3]
    else {
        return .unknown
    }

    // Check version and layer bytes:
    // - Core module: version=0x01, 0x00 and layer=0x00, 0x00
    // - Component:   version=0x0d, 0x00 and layer=0x01, 0x00
    switch (header.4, header.5, header.6, header.7) {
    case (0x01, 0x00, 0x00, 0x00):
        return .coreModule
    case (0x0d, 0x00, 0x01, 0x00):
        return .component
    default:
        return .unknown
    }
}
