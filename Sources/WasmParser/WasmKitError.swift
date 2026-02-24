import WasmTypes

/// A universal error type thrown by WasmKit.
public struct WasmKitError: Swift.Error {
    public struct Message: Sendable {
        package let text: String

        package init(_ text: String) {
            self.text = text
        }
    }

    @usableFromInline
    package enum Kind: Sendable {
        case message(Message)
        case parserUnexpectedEnd(expected: Set<UInt8>?)
        case parserUnexpectedByte(UInt8, expected: Set<UInt8>?)
        case unclassified(any Error)
        case leb(LEBError)
    }

    package enum Location {
        case offset(Int)
        case utf8Index(WasmTypes.Location)
    }

    package let kind: Kind
    package var location: Location?

    @usableFromInline
    package init(kind: Kind, offset: Int? = nil) {
        self.kind = kind
        if let offset {
            self.location = .offset(offset)
        } else {
            self.location = nil
        }
    }
}

extension WasmKitError {
    @usableFromInline
    package init(message: Message, offset: Int? = nil) {
        self.kind = .message(message)
        if let offset {
            self.location = .offset(offset)
        } else {
            self.location = nil
        }
    }

    @usableFromInline
    package init(_ string: String, offset: Int? = nil) {
        self.kind = .message(.init(string))
        if let offset {
            self.location = .offset(offset)
        } else {
            self.location = nil
        }
    }

    @usableFromInline
    package init(_ string: String, location: WasmTypes.Location?) {
        self.kind = .message(.init(string))
        if let location {
            self.location = .utf8Index(location)
        } else {
            self.location = nil
        }
    }

    @usableFromInline
    static func leb(_ error: LEBError, offset: Int) -> WasmKitError {
        WasmKitError(kind: .leb(error), offset: offset)
    }

    @usableFromInline
    package static func unclassified(_ error: any Error, offset: Int? = nil) -> WasmKitError {
        WasmKitError(kind: .unclassified(error), offset: offset)
    }
}

extension BinaryInteger {
    var hexString: String {
        "0x\(String(self, radix: 16))"
    }
}

extension WasmKitError: CustomStringConvertible {
    public var description: String {
        switch self.kind {
        case .message(let message):
            if case .offset(let offset) = self.location {
                return "\"\(message)\" at offset 0x\(String(offset, radix: 16))"
            } else {
                return message.text
            }
        case .parserUnexpectedEnd(let expected):
            var result = "Unexpected end of byte sequence."
            if case .offset(let offset) = self.location {
                result.append(contentsOf: " at offset \(offset.hexString)")
            }
            if let expected, expected.count > 0 {
                result.append(contentsOf: " Expected one of \(expected.map {$0.hexString})")
            }
            return result
        case .parserUnexpectedByte(let byte, let expected):
            var result = "Unexpected byte \(byte.hexString)"
            if case .offset(let offset) = self.location {
                result.append(contentsOf: " at offset \(offset.hexString)")
            }
            result.append(".")
            if let expected, expected.count > 0 {
                result.append(contentsOf: " Expected one of \(expected.map {$0.hexString})")
            }
            return result
        case .unclassified(let error):
            return "\(error)"
        case .leb(let error):
            return "\(error)"
        }
    }
}

extension WasmKitError.Message {
    @usableFromInline
    static func invalidMagicNumber(_ bytes: [UInt8]) -> Self {
        Self("magic header not detected: expected \(WASM_MAGIC) but got \(bytes)")
    }

    @usableFromInline
    static func unknownVersion(_ bytes: [UInt8]) -> Self {
        Self("unknown binary version: \(bytes)")
    }

    static func invalidUTF8(_ bytes: [UInt8]) -> Self {
        Self("malformed UTF-8 encoding: \(bytes)")
    }

    @usableFromInline
    static func invalidSectionSize(_ size: UInt32) -> Self {
        // TODO: Remove size parameter
        Self("unexpected end-of-file")
    }

    @usableFromInline
    static func malformedSectionID(_ id: UInt8) -> Self {
        Self("malformed section id: \(id)")
    }

    @usableFromInline
    static func malformedValueType(_ byte: UInt8) -> Self {
        Self("malformed value type: \(byte)")
    }

    @usableFromInline static func zeroExpected(actual: UInt8) -> Self {
        Self("Zero expected but got \(actual)")
    }

    @usableFromInline
    static func tooManyLocals(_ count: UInt64, limit: UInt64) -> Self {
        Self("Too many locals: \(count) vs \(limit)")
    }

    @usableFromInline static func expectedRefType(actual: ValueType) -> Self {
        Self("Expected reference type but got \(actual)")
    }

    @usableFromInline
    static func unexpectedElementKind(expected: UInt32, actual: UInt32) -> Self {
        Self("Unexpected element kind: expected \(expected) but got \(actual)")
    }

    @usableFromInline
    static let integerRepresentationTooLong = Self("Integer representation is too long")

    @usableFromInline
    static let endOpcodeExpected = Self("`end` opcode expected but not found")

    @usableFromInline
    static let unexpectedEnd = Self("Unexpected end of the stream")

    @usableFromInline
    static func sectionSizeMismatch(sectionID: UInt8, expected: Int, actual: Int) -> Self {
        Self("Section size mismatch for section \(sectionID): expected \(expected) but got \(actual)")
    }

    @usableFromInline static func unknownCanonOptionTag(_ tag: UInt8) -> Self {
        Self("Unknown canonical option tag: \(tag)")
    }

    @usableFromInline static func illegalOpcode(_ opcode: [UInt8]) -> Self {
        Self("Illegal opcode: \(opcode)")
    }

    @usableFromInline
    static func malformedMutability(_ byte: UInt8) -> Self {
        Self("Malformed mutability: \(byte)")
    }

    @usableFromInline
    static func malformedFunctionType(_ byte: UInt8) -> Self {
        Self("Malformed function type: \(byte)")
    }

    @usableFromInline
    static let sectionOutOfOrder = Self("Sections in the module are out of order")

    @usableFromInline
    static func malformedLimit(_ byte: UInt8) -> Self {
        Self("Malformed limit: \(byte)")
    }

    @usableFromInline static let malformedIndirectCall = Self("Malformed indirect call")

    @usableFromInline static func malformedDataSegmentKind(_ kind: UInt32) -> Self {
        Self("Malformed data segment kind: \(kind)")
    }

    @usableFromInline static func invalidResultArity(expected: Int, actual: Int) -> Self {
        Self("invalid result arity: expected \(expected) but got \(actual)")
    }

    @usableFromInline static func invalidFunctionType(_ index: Int64) -> Self {
        Self("invalid function type index: \(index), expected a unsigned 32-bit integer")
    }
}
