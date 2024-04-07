/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-code>
public struct Code {
    let locals: [ValueType]
    let expression: ArraySlice<UInt8>
}

extension Code: Equatable {
    public static func == (lhs: Code, rhs: Code) -> Bool {
        return lhs.locals == rhs.locals && lhs.expression == rhs.expression
    }
}

public struct MemArg: Equatable {
    public let offset: UInt64
    public let align: UInt32

    public init(offset: UInt64, align: UInt32) {
        self.offset = offset
        self.align = align
    }
}

public enum BlockType: Equatable {
    case empty
    case type(ValueType)
    case funcType(UInt32)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#function-types>
public struct FunctionType: Equatable {
    public init(parameters: [ValueType], results: [ValueType] = []) {
        self.parameters = parameters
        self.results = results
    }

    public let parameters: [ValueType]
    public let results: [ValueType]
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#limits>
public struct Limits: Equatable {
    public let min: UInt64
    public let max: UInt64?
    public let isMemory64: Bool

    public init(min: UInt64, max: UInt64?, isMemory64: Bool = false) {
        self.min = min
        self.max = max
        self.isMemory64 = isMemory64
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#memory-types>
public typealias MemoryType = Limits

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#table-types>
public struct TableType: Equatable {
    public let elementType: ReferenceType
    public let limits: Limits
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
public enum Mutability: Equatable {
    case constant
    case variable
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
public struct GlobalType: Equatable {
    public let mutability: Mutability
    public let valueType: ValueType
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#external-types>
public enum ExternalType {
    case function(FunctionType)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}

/// Reference types
public enum ReferenceType: Equatable {
    /// A nullable reference type to a function.
    case funcRef
    /// A nullable external reference type.
    case externRef
}

public enum ValueType: Equatable {
    /// 32-bit signed or unsigned integer.
    case i32
    /// 64-bit signed or unsigned integer.
    case i64
    /// 32-bit IEEE 754 floating-point number.
    case f32
    /// 64-bit IEEE 754 floating-point number.
    case f64
    /// Reference value type.
    case ref(ReferenceType)
}

public enum IEEE754 {
    public struct Float32: Equatable {
        public let bitPattern: UInt32
    }
    public struct Float64: Equatable {
        public let bitPattern: UInt64
    }
}

public struct BrTable: Equatable {
    public let labelIndices: [UInt32]
    public let defaultIndex: UInt32
}


public struct CustomSection: Equatable {
    public let name: String
    public let bytes: ArraySlice<UInt8>
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#syntax-typeidx>
typealias TypeIndex = UInt32
typealias FunctionIndex = UInt32
typealias TableIndex = UInt32
typealias DataIndex = UInt32
typealias ElementIndex = UInt32

public struct ConstExpression: Equatable, ExpressibleByArrayLiteral {
    public let instructions: [Instruction]

    public init(instructions: [Instruction]) {
        self.instructions = instructions
    }
    public init(arrayLiteral elements: Instruction...) {
        self.instructions = elements
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#tables>
public struct Table: Equatable {
    public let type: TableType
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#memories>
public struct Memory: Equatable {
    public let type: MemoryType
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#globals>
public struct Global: Equatable {
    let type: GlobalType
    let initializer: ConstExpression
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#element-segments>
public struct ElementSegment: Equatable {
    struct Flag: OptionSet {
        let rawValue: UInt32

        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        var segmentHasElemKind: Bool {
            !contains(.usesExpressions) && rawValue != 0
        }

        var segmentHasRefType: Bool {
            contains(.usesExpressions) && rawValue != 4
        }

        static let isPassiveOrDeclarative = Flag(rawValue: 1 << 0)
        static let isDeclarative = Flag(rawValue: 1 << 1)
        static let hasTableIndex = Flag(rawValue: 1 << 1)
        static let usesExpressions = Flag(rawValue: 1 << 2)
    }

    enum Mode: Equatable {
        case active(table: UInt32, offset: ConstExpression)
        case declarative
        case passive
    }

    public let type: ReferenceType
    let initializer: [ConstExpression]
    let mode: Mode
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#data-segments>
public enum DataSegment: Equatable {
    public struct Active: Equatable {
        let index: UInt32
        let offset: ConstExpression
        let initializer: ArraySlice<UInt8>
    }

    case passive([UInt8])
    case active(Active)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#exports>
public struct Export: Equatable {
    public let name: String
    public let descriptor: ExportDescriptor
}

public enum ExportDescriptor: Equatable {
    case function(UInt32)
    case table(UInt32)
    case memory(UInt32)
    case global(UInt32)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#imports>
public struct Import: Equatable {
    public let module: String
    public let name: String
    public let descriptor: ImportDescriptor
}

public enum ImportDescriptor: Equatable {
    case function(UInt32)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}


protocol RawUnsignedInteger: FixedWidthInteger & UnsignedInteger {
    associatedtype Signed: RawSignedInteger where Signed.Unsigned == Self
    init(bitPattern: Signed)
}

protocol RawSignedInteger: FixedWidthInteger & SignedInteger {
    associatedtype Unsigned: RawUnsignedInteger where Unsigned.Signed == Self
    init(bitPattern: Unsigned)
}

extension UInt8: RawUnsignedInteger {
    typealias Signed = Int8
}

extension UInt16: RawUnsignedInteger {
    typealias Signed = Int16
}

extension UInt32: RawUnsignedInteger {
    typealias Signed = Int32
}

extension UInt64: RawUnsignedInteger {
    typealias Signed = Int64
}

extension Int8: RawSignedInteger {}
extension Int16: RawSignedInteger {}
extension Int32: RawSignedInteger {}
extension Int64: RawSignedInteger {}

extension RawUnsignedInteger {
    var signed: Signed {
        .init(bitPattern: self)
    }
}

extension RawSignedInteger {
    var unsigned: Unsigned {
        .init(bitPattern: self)
    }
}
