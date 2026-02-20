/// Binary format constants for the WebAssembly Component Model.
/// These constants are shared between the encoder (`ComponentEncoder`) and parser (`ComponentParser`).
/// Reference: `Vendor/component-model/design/mvp/Binary.md`

/// Section IDs per Binary.md
public enum ComponentSectionID: UInt8 {
    case custom = 0x00
    case coreModule = 0x01
    case coreInstance = 0x02
    case coreType = 0x03
    case component = 0x04
    case instance = 0x05
    case alias = 0x06
    case type = 0x07
    case canon = 0x08
    case start = 0x09
    case `import` = 0x0A
    case export = 0x0B
    case value = 0x0C
}

// MARK: - Value Type Opcodes

/// Primitive value type opcodes (negative SLEB128 from 0x7f)
public enum PrimitiveValTypeOpcode: UInt8 {
    case bool = 0x7f
    case s8 = 0x7e
    case u8 = 0x7d
    case s16 = 0x7c
    case u16 = 0x7b
    case s32 = 0x7a
    case u32 = 0x79
    case s64 = 0x78
    case u64 = 0x77
    case float32 = 0x76
    case float64 = 0x75
    case char = 0x74
    case string = 0x73
    case errorContext = 0x64
}

/// Composite value type opcodes
public enum CompositeValTypeOpcode: UInt8 {
    case record = 0x72
    case variant = 0x71
    case list = 0x70
    case tuple = 0x6f
    case flags = 0x6e
    case `enum` = 0x6d
    case option = 0x6b
    case result = 0x6a
    case own = 0x69
    case borrow = 0x68
    case listFixed = 0x67  // fixed-length list (gated feature)
    case stream = 0x66
    case future = 0x65
}

/// Defined type opcodes (function, component, instance, resource)
public enum DefinedTypeOpcode: UInt8 {
    case funcSync = 0x40
    case componentType = 0x41
    case instanceType = 0x42
    case funcAsync = 0x43  // async function (gated feature)
    case resourceSync = 0x3f
    case resourceAsync = 0x3e  // async resource (gated feature)

    // Core module types
    case coreFunc = 0x60
    case coreModule = 0x50
}

// MARK: - Canonical Operations

/// Canonical operation opcodes
public enum CanonOpcode: UInt8 {
    // Basic lift/lower
    case lift = 0x00
    case lower = 0x01

    // Resource operations
    case resourceNew = 0x02
    case resourceDrop = 0x03
    case resourceRep = 0x04

    // Task operations (gated: async)
    case taskCancel = 0x05
    case subtaskCancel = 0x06
    case backpressureSet = 0x08  // deprecated
    case taskReturn = 0x09
    case contextGetI32 = 0x0a
    case contextSetI32 = 0x0b
    case threadYield = 0x0c
    case subtaskDrop = 0x0d

    // Stream operations (gated: async)
    case streamNew = 0x0e
    case streamRead = 0x0f
    case streamWrite = 0x10
    case streamCancelRead = 0x11
    case streamCancelWrite = 0x12
    case streamDropReadable = 0x13
    case streamDropWritable = 0x14

    // Future operations (gated: async)
    case futureNew = 0x15
    case futureRead = 0x16
    case futureWrite = 0x17
    case futureCancelRead = 0x18
    case futureCancelWrite = 0x19
    case futureDropReadable = 0x1a
    case futureDropWritable = 0x1b

    // Error context operations (gated: error-context)
    case errorContextNew = 0x1c
    case errorContextDebugMessage = 0x1d
    case errorContextDrop = 0x1e

    // Waitable set operations (gated: async)
    case waitableSetNew = 0x1f
    case waitableSetWait = 0x20
    case waitableSetPoll = 0x21
    case waitableSetDrop = 0x22
    case waitableJoin = 0x23

    // Backpressure (new style, gated: async)
    case backpressureInc = 0x24
    case backpressureDec = 0x25

    // Thread operations (gated: threading)
    case threadIndex = 0x26
    case threadNewIndirect = 0x27
    case threadSwitchTo = 0x28
    case threadSuspend = 0x29
    case threadResumeLater = 0x2a
    case threadYieldTo = 0x2b
    case threadSpawnRef = 0x40
    case threadSpawnIndirect = 0x41
    case threadAvailableParallelism = 0x42
}

/// Canonical option tags
public enum CanonOptionTag: UInt8 {
    case stringEncodingUtf8 = 0x00
    case stringEncodingUtf16 = 0x01
    case stringEncodingLatin1Utf16 = 0x02
    case memory = 0x03
    case realloc = 0x04
    case postReturn = 0x05
    case async = 0x06
    case callback = 0x07
}

// MARK: - Sort Values

/// Core sort values (used in aliases and extern descs)
public enum CoreSortOpcode: UInt8 {
    case function = 0x00
    case table = 0x01
    case memory = 0x02
    case global = 0x03
    case type = 0x10
    case module = 0x11
    case instance = 0x12
}

/// Component sort values (used in aliases and extern descs)
public enum ComponentSortOpcode: UInt8 {
    case core = 0x00
    case function = 0x01
    case value = 0x02
    case type = 0x03
    case component = 0x04
    case instance = 0x05
}

/// Alias target kinds
public enum AliasTargetOpcode: UInt8 {
    case export = 0x00
    case coreExport = 0x01
    case outer = 0x02
}

/// Extern descriptor kinds (for imports/exports)
public enum ExternDescKind: UInt8 {
    case coreModule = 0x00
    case function = 0x01
    case value = 0x02
    case type = 0x03
    case component = 0x04
    case instance = 0x05
}

/// Type bound kinds
public enum TypeBoundOpcode: UInt8 {
    /// Exact type match: `(eq $type)`
    case eq = 0x00
    /// Subtype bound: `(sub resource)`
    case subResource = 0x01
}

/// Tags for declarations inside instance/component type definitions
public enum TypeDeclTag: UInt8 {
    /// Core type declaration (in instancedecl)
    case coreType = 0x00
    /// Component type declaration
    case type = 0x01
    /// Alias declaration
    case alias = 0x02
    /// Import declaration (only in componentdecl)
    case `import` = 0x03
    /// Export declaration
    case export = 0x04
}

/// Instance expression forms
public enum InstanceForm: UInt8 {
    /// Instantiate: `(instantiate $module ...)`
    case instantiate = 0x00
    /// Inline exports: `(instance (export ...) ...)`
    case inlineExports = 0x01
}

/// Result type encoding markers
public enum ResultMarker: UInt8 {
    /// Has a single unnamed result
    case hasResult = 0x00
    /// Named results (followed by count; count=0 means no results)
    case namedResults = 0x01
}

/// Optional value markers
public enum OptionalMarker: UInt8 {
    case absent = 0x00
    case present = 0x01
}

/// Import/export name encoding variants
public enum NameVariant: UInt8 {
    /// Plain name without version suffix
    case plain = 0x00
    /// Name with version suffix (gated: versioning)
    case withVersion = 0x01
}
