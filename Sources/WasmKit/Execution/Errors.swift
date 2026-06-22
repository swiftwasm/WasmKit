import WasmTypes

import struct WasmParserCore.Import

/// The backtrace of the trap.
public struct Backtrace: Sendable {
    public struct Symbol: @unchecked Sendable {
        public let name: String?
        let address: Pc
    }
    public let symbols: [Symbol]
}

#if !$Embedded
extension Backtrace: CustomStringConvertible {
    public var description: String {
        symbols.enumerated().map { (index, symbol) in
            let name = symbol.name ?? "unknown"
            return "    \(index): (\(symbol.address)) \(name)"
        }.joined(separator: "\n")
    }
}
#endif

/// An error that occurs during execution of a WebAssembly module.
public struct Trap: Error {
    package private(set) var reason: TrapReason
    private(set) var backtrace: Backtrace?

    init(_ code: TrapReason, backtrace: Backtrace? = nil) {
        self.reason = code
        self.backtrace = backtrace
    }

    init(_ message: TrapReason.Message, backtrace: Backtrace? = nil) {
        self.init(.message(message), backtrace: backtrace)
    }

    func withBacktrace(_ backtrace: Backtrace) -> Trap {
        var trap = self
        trap.backtrace = backtrace
        return trap
    }
}

#if !$Embedded
extension Trap: CustomStringConvertible {
    public var description: String {
        var desc = "Trap: \(reason)"
        if let backtrace = backtrace { desc += "\n\(backtrace)" }
        return desc
    }
}
#endif

/// An uncaught WebAssembly exception that propagated out of a module.
public struct WasmKitException: Error {
    let tagIdentity: Int
    let payload: [Value]

    init(tag: InternalTag, payload: [Value]) {
        self.tagIdentity = tag.bitPattern
        self.payload = payload
    }

    func hasTag(_ tag: InternalTag) -> Bool { tagIdentity == tag.bitPattern }
}

#if !$Embedded
extension WasmKitException: CustomStringConvertible {
    public var description: String { "wasm exception (payload: \(payload))" }
}
#endif

/// A reason for a trap that occurred during execution of a WebAssembly module.
package enum TrapReason: Error {
    package struct Message {
        let text: String
        init(_ text: String) { self.text = text }
    }
    case message(Message)
    case unreachable
    case callStackExhausted
    case tableOutOfBounds(Int)
    case memoryOutOfBounds
    case unalignedAtomic
    case indirectCallToNull(Int)
    case typeMismatchCall(actual: FunctionType, expected: FunctionType)
    case integerDividedByZero
    case integerOverflow
    case invalidConversionToInteger
}

#if !$Embedded
extension TrapReason: CustomStringConvertible {
    package var description: String {
        switch self {
        case .message(let message): return message.text
        case .unreachable: return "unreachable"
        case .callStackExhausted: return "call stack exhausted"
        case .memoryOutOfBounds: return "out of bounds memory access"
        case .unalignedAtomic: return "unaligned atomic"
        case .integerDividedByZero: return "integer divide by zero"
        case .integerOverflow: return "integer overflow"
        case .invalidConversionToInteger: return "invalid conversion to integer"
        case .indirectCallToNull(let elementIndex):
            return "indirect call to null element (uninitialized element \(elementIndex))"
        case .typeMismatchCall(let actual, let expected):
            return "indirect call type mismatch, expected \(expected), got \(actual)"
        case .tableOutOfBounds(let index):
            return "out of bounds table access at \(index) (undefined element)"
        }
    }
}
#endif

extension TrapReason.Message {
    static func initialTableSizeExceedsLimit(numberOfElements: Int) -> Self {
        #if !$Embedded
        Self("initial table size exceeds the resource limit: \(numberOfElements) elements")
        #else
        Self("initial table size exceeds the resource limit")
        #endif
    }
    static func initialMemorySizeExceedsLimit(byteSize: Int) -> Self {
        #if !$Embedded
        Self("initial memory size exceeds the resource limit: \(byteSize) bytes")
        #else
        Self("initial memory size exceeds the resource limit")
        #endif
    }
    // In Embedded mode, avoid String interpolation over [ValueType]/[Value] arrays
    // which pulls in collection description formatting (~4-8 KB of code).
    static func parameterTypesMismatch(expected: [ValueType], got: [Value]) -> Self {
        #if !$Embedded
        Self("parameter types don't match, expected \(expected), got \(got)")
        #else
        Self("(cannot print value in embedded Swift)")
        #endif
    }
    static func resultTypesMismatch(expected: [ValueType], got: [Value]) -> Self {
        #if !$Embedded
        Self("result types don't match, expected \(expected), got \(got)")
        #else
        Self("(cannot print value in embedded Swift)")
        #endif
    }
    static var cannotAssignToImmutableGlobal: Self {
        Self("cannot assign to an immutable global")
    }
    static func noGlobalExportWithName(globalName: String, instance: Instance) -> Self {
        #if !$Embedded
        Self("no global export with name \(globalName) in a module instance \(instance)")
        #else
        Self("no global export with name found in module instance")
        #endif
    }
    static func exportedFunctionNotFound(name: String, instance: Instance) -> Self {
        #if !$Embedded
        Self("exported function \(name) not found in instance \(instance)")
        #else
        Self("exported function not found in instance")
        #endif
    }
    static func unimplemented(feature: String) -> Self {
        Self("\(feature) is not implemented yet")
    }
}

package struct ImportError: Error {
    package struct Message {
        package let text: String

        init(_ text: String) {
            self.text = text
        }
    }

    package let message: Message

    init(_ message: Message) {
        self.message = message
    }
}

extension ImportError.Message {
    static func missing(moduleName: String, externalName: String) -> Self {
        Self("unknown import \(moduleName).\(externalName)")
    }
    static func incompatibleType(_ importEntry: Import, entity: InternalExternalValue) -> Self {
        let expected: String
        switch importEntry.descriptor {
        case .function:
            expected = "function"
        case .global:
            expected = "global"
        case .memory:
            expected = "memory"
        case .table:
            expected = "table"
        case .tag:
            expected = "tag"
        }
        let got: String
        switch entity {
        case .function:
            got = "function"
        case .global:
            got = "global"
        case .memory:
            got = "memory"
        case .table:
            got = "table"
        case .tag:
            got = "tag"
        }
        return Self("incompatible import type for \(importEntry.module).\(importEntry.name), expected \(expected), got \(got)")
    }
    static func incompatibleFunctionType(_ importEntry: Import, actual: FunctionType, expected: FunctionType) -> Self {
        Self("incompatible import type: function type for \(importEntry.module).\(importEntry.name), expected \(expected), got \(actual)")
    }
    static func incompatibleTableType(_ importEntry: Import, actual: TableType, expected: TableType) -> Self {
        Self("incompatible import type: table type for \(importEntry.module).\(importEntry.name), expected \(expected), got \(actual)")
    }
    static func incompatibleMemoryType(_ importEntry: Import, actual: MemoryType, expected: MemoryType) -> Self {
        Self("incompatible import type: memory type for \(importEntry.module).\(importEntry.name), expected \(expected), got \(actual)")
    }
    static func incompatibleGlobalType(_ importEntry: Import, actual: GlobalType, expected: GlobalType) -> Self {
        Self("incompatible import type: global type for \(importEntry.module).\(importEntry.name), expected \(expected), got \(actual)")
    }
    static func importedEntityFromDifferentStore(_ importEntry: Import) -> Self {
        Self("imported entity from different store: \(importEntry.module).\(importEntry.name)")
    }
    static func moduleInstanceAlreadyRegistered(_ name: String) -> Self {
        Self("a module instance is already registered under a name `\(name)")
    }
}
