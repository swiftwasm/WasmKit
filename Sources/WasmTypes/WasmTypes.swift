/// Type of a WebAssembly function.
///
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#function-types>
public struct FunctionType: Equatable, Hashable, Sendable {
    public init(parameters: [ValueType], results: [ValueType] = []) {
        self.parameters = parameters
        self.results = results
    }

    /// The types of the function parameters.
    public let parameters: [ValueType]
    /// The types of the function results.
    public let results: [ValueType]
}

/// An abstract heap type. The raw value is the type's binary encoding.
public enum AbstractHeapType: UInt8, Equatable, Hashable, Sendable {
    /// A reference to any kind of function.
    case funcRef = 0x70  // -> to be renamed func

    /// An external host data.
    case externRef = 0x6F  // -> to be renamed extern

    /// A reference to an exception.
    case exnRef = 0x69

    /// The top of the GC hierarchy of internal references.
    case any = 0x6E
    /// A reference that `ref.eq` can compare: an `i31`, a struct or an array.
    case eq = 0x6D
    /// An unboxed 31-bit integer.
    case i31 = 0x6C
    /// A reference to a GC struct.
    case structRef = 0x6B
    /// A reference to a GC array.
    case arrayRef = 0x6A
    /// The bottom of the GC hierarchy of internal references. `none` would read as `nil` in an
    /// `AbstractHeapType?` context.
    case noneRef = 0x71
    /// The bottom of the external hierarchy.
    case noExtern = 0x72
    /// The bottom of the function hierarchy.
    case noFunc = 0x73
    /// The bottom of the exception hierarchy.
    case noExn = 0x74
}

public enum HeapType: Equatable, Hashable, Sendable {
    case abstract(AbstractHeapType)
    case concrete(typeIndex: UInt32)

    public static var funcRef: HeapType {
        return .abstract(.funcRef)
    }

    public static var externRef: HeapType {
        return .abstract(.externRef)
    }

    public static var exnRef: HeapType {
        return .abstract(.exnRef)
    }
}

/// Reference types
public struct ReferenceType: Equatable, Hashable, Sendable {
    public var isNullable: Bool
    public var heapType: HeapType

    public static var funcRef: ReferenceType {
        ReferenceType(isNullable: true, heapType: .funcRef)
    }

    public static var externRef: ReferenceType {
        ReferenceType(isNullable: true, heapType: .externRef)
    }

    public static var exnRef: ReferenceType {
        ReferenceType(isNullable: true, heapType: .exnRef)
    }

    public init(isNullable: Bool, heapType: HeapType) {
        self.isNullable = isNullable
        self.heapType = heapType
    }
}

public enum ValueType: Equatable, Hashable, Sendable {
    /// 32-bit signed or unsigned integer.
    case i32
    /// 64-bit signed or unsigned integer.
    case i64
    /// 32-bit IEEE 754 floating-point number.
    case f32
    /// 64-bit IEEE 754 floating-point number.
    case f64
    /// 128-bit vector of packed integer or floating-point data.
    case v128
    /// Reference value type.
    case ref(ReferenceType)
}

/// A packed integer type, which only a struct field or an array element can have.
public enum PackedType: Equatable, Hashable, Sendable {
    case i8
    case i16
}

/// The type a struct field or an array element stores.
public enum StorageType: Equatable, Hashable, Sendable {
    case value(ValueType)
    case packed(PackedType)
}

/// The type of a struct field or an array element.
public struct FieldType: Equatable, Hashable, Sendable {
    public var storage: StorageType
    public var isMutable: Bool

    public init(storage: StorageType, isMutable: Bool) {
        self.storage = storage
        self.isMutable = isMutable
    }
}

/// A GC struct type.
public struct StructType: Equatable, Hashable, Sendable {
    public var fields: [FieldType]

    public init(fields: [FieldType]) {
        self.fields = fields
    }
}

/// A GC array type.
public struct ArrayType: Equatable, Hashable, Sendable {
    public var element: FieldType

    public init(element: FieldType) {
        self.element = element
    }
}

/// The body of a type definition.
///
/// > Note:
/// <https://webassembly.github.io/gc/core/syntax/types.html#composite-types>
public enum CompositeType: Equatable, Hashable, Sendable {
    case function(FunctionType)
    case structType(StructType)
    case arrayType(ArrayType)
}

/// A type definition with its declared supertypes.
///
/// > Note:
/// <https://webassembly.github.io/gc/core/syntax/types.html#recursive-types>
public struct SubType: Equatable, Hashable, Sendable {
    /// Whether no other type may declare this one as its supertype.
    public var isFinal: Bool
    public var supertypes: [UInt32]
    public var body: CompositeType

    public init(isFinal: Bool, supertypes: [UInt32], body: CompositeType) {
        self.isFinal = isFinal
        self.supertypes = supertypes
        self.body = body
    }
}

/// A group of type definitions that may refer to each other. A type definition outside a `rec` group
/// is a group of its own.
public struct RecursiveGroup: Equatable, Hashable, Sendable {
    public var types: [SubType]

    public init(types: [SubType]) {
        self.types = types
    }
}

/// A 128-bit vector value, represented by its raw bytes.
public struct V128: Equatable, Hashable, Sendable {
    public static let byteCount = 16

    public let bytes: [UInt8]

    public init(bytes: [UInt8]) {
        precondition(bytes.count == Self.byteCount, "V128 must be exactly \(Self.byteCount) bytes")
        self.bytes = bytes
    }
}

/// The 16 lane indices used by `i8x16.shuffle`.
public struct V128ShuffleMask: Equatable, Hashable, Sendable {
    public static let laneCount = 16

    public let lanes: [UInt8]

    public init(lanes: [UInt8]) {
        precondition(lanes.count == Self.laneCount, "V128ShuffleMask must be exactly \(Self.laneCount) bytes")
        self.lanes = lanes
    }
}

/// Runtime representation of a WebAssembly function reference.
public typealias FunctionAddress = Int
/// Runtime representation of an external entity reference.
public typealias ExternAddress = Int
/// Runtime representation of an exception reference.
public typealias ExceptionAddress = Int

@available(*, unavailable, message: "Address-based APIs has been removed; use `Table` instead")
public typealias TableAddress = Int
@available(*, unavailable, message: "Address-based APIs has been removed; use `Memory` instead")
public typealias MemoryAddress = Int
@available(*, unavailable, message: "Address-based APIs has been removed; use `Global` instead")
public typealias GlobalAddress = Int
@available(*, unavailable, message: "Address-based APIs has been removed")
public typealias ElementAddress = Int
@available(*, unavailable, message: "Address-based APIs has been removed")
public typealias DataAddress = Int

public enum Reference: Hashable, Sendable {
    /// A reference to a function.
    case function(FunctionAddress?)
    /// A reference to an external entity.
    case extern(ExternAddress?)
    /// A reference to an exception.
    case exception(ExceptionAddress?)
}

/// Runtime representation of a value.
public enum Value: Hashable, Sendable {
    /// Value of a 32-bit signed or unsigned integer.
    case i32(UInt32)
    /// Value of a 64-bit signed or unsigned integer.
    case i64(UInt64)
    /// Value of a 32-bit IEEE 754 floating-point number.
    case f32(UInt32)
    /// Value of a 64-bit IEEE 754 floating-point number.
    case f64(UInt64)
    /// 128-bit vector of packed integer or floating-point data.
    case v128(V128)
    /// Reference value.
    case ref(Reference)
}

extension Value {
    /// Create a new value from a signed 32-bit integer.
    public init(signed value: Int32) {
        self = .i32(UInt32(bitPattern: value))
    }

    /// Create a new value from a signed 64-bit integer.
    public init(signed value: Int64) {
        self = .i64(UInt64(bitPattern: value))
    }

    /// Create a new value from a 32-bit floating-point number.
    public static func fromFloat32(_ value: Float32) -> Value {
        return .f32(value.bitPattern)
    }

    /// Create a new value from a 64-bit floating-point number.
    public static func fromFloat64(_ value: Float64) -> Value {
        return .f64(value.bitPattern)
    }

    /// Returns the value as a 32-bit signed integer.
    /// - Precondition: The value is of type `i32`.
    public var i32: UInt32 {
        guard case .i32(let result) = self else { fatalError() }
        return result
    }

    /// Returns the value as a 64-bit signed integer.
    /// - Precondition: The value is of type `i64`.
    public var i64: UInt64 {
        guard case .i64(let result) = self else { fatalError() }
        return result
    }

    /// Returns the value as a 32-bit floating-point number.
    /// - Precondition: The value is of type `f32`.
    public var f32: UInt32 {
        guard case .f32(let result) = self else { fatalError() }
        return result
    }

    /// Returns the value as a 64-bit floating-point number.
    /// - Precondition: The value is of type `f64`.
    public var f64: UInt64 {
        guard case .f64(let result) = self else { fatalError() }
        return result
    }
}
