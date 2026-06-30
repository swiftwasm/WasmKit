/// A compact runtime trace of one or more WebAssembly invocations.
///
/// This is execution evidence, not a proof that unobserved functions or data are
/// statically dead. It is intended to guide follow-up size-analysis work.
public struct WasmExecutionTrace: Equatable, Sendable {
    public struct FunctionEntry: Equatable, Sendable {
        public let name: String

        public init(name: String) {
            self.name = name
        }
    }

    public struct MemoryRange: Equatable, Sendable {
        public let memory: UInt32
        public let offset: UInt64
        public let length: UInt64

        public init(memory: UInt32, offset: UInt64, length: UInt64) {
            self.memory = memory
            self.offset = offset
            self.length = length
        }
    }

    public struct DataSegmentRange: Equatable, Sendable {
        public let segment: UInt32
        public let sourceOffset: UInt64
        public let destinationOffset: UInt64
        public let length: UInt64

        public init(segment: UInt32, sourceOffset: UInt64, destinationOffset: UInt64, length: UInt64) {
            self.segment = segment
            self.sourceOffset = sourceOffset
            self.destinationOffset = destinationOffset
            self.length = length
        }
    }

    public let executedFunctions: [FunctionEntry]
    public let memoryReads: [MemoryRange]
    public let memoryWrites: [MemoryRange]
    public let dataSegmentsInitialized: [DataSegmentRange]

    public init(
        executedFunctions: [FunctionEntry],
        memoryReads: [MemoryRange],
        memoryWrites: [MemoryRange],
        dataSegmentsInitialized: [DataSegmentRange]
    ) {
        self.executedFunctions = executedFunctions
        self.memoryReads = memoryReads
        self.memoryWrites = memoryWrites
        self.dataSegmentsInitialized = dataSegmentsInitialized
    }

    public var jsonString: String {
        """
        {
          "executedFunctions": \(Self.serialize(executedFunctions)),
          "memoryReads": \(Self.serialize(memoryReads)),
          "memoryWrites": \(Self.serialize(memoryWrites)),
          "dataSegmentsInitialized": \(Self.serialize(dataSegmentsInitialized))
        }
        """
    }
}

/// An opt-in runtime trace recorder for function execution and memory/data use.
public final class WasmExecutionTraceRecorder: EngineInterceptor {
    private var executedFunctionNames: Set<String> = []
    private var executedFunctions: [WasmExecutionTrace.FunctionEntry] = []
    private var memoryReads: [WasmExecutionTrace.MemoryRange] = []
    private var memoryWrites: [WasmExecutionTrace.MemoryRange] = []
    private var dataSegmentsInitialized: [WasmExecutionTrace.DataSegmentRange] = []

    public init() {}

    public func onEnterFunction(_ function: Function) {
        let name = function.store.nameRegistry.symbolicate(function.handle)
        if executedFunctionNames.insert(name).inserted {
            executedFunctions.append(.init(name: name))
        }
    }

    public func onMemoryRead(memory: UInt32, offset: UInt64, length: UInt64) {
        memoryReads.append(.init(memory: memory, offset: offset, length: length))
    }

    public func onMemoryWrite(memory: UInt32, offset: UInt64, length: UInt64) {
        memoryWrites.append(.init(memory: memory, offset: offset, length: length))
    }

    public func onDataSegmentInitialized(segment: UInt32, sourceOffset: UInt64, destinationOffset: UInt64, length: UInt64) {
        dataSegmentsInitialized.append(
            .init(
                segment: segment,
                sourceOffset: sourceOffset,
                destinationOffset: destinationOffset,
                length: length
            )
        )
    }

    public func snapshot() -> WasmExecutionTrace {
        WasmExecutionTrace(
            executedFunctions: executedFunctions,
            memoryReads: memoryReads,
            memoryWrites: memoryWrites,
            dataSegmentsInitialized: dataSegmentsInitialized
        )
    }
}

private extension WasmExecutionTrace {
    static func serialize(_ functions: [FunctionEntry]) -> String {
        "[" + functions.map { #"{"name":\#(serialize($0.name))}"# }.joined(separator: ", ") + "]"
    }

    static func serialize(_ ranges: [MemoryRange]) -> String {
        "[" + ranges.map {
            #"{"memory":\#($0.memory),"offset":\#($0.offset),"length":\#($0.length)}"#
        }.joined(separator: ", ") + "]"
    }

    static func serialize(_ ranges: [DataSegmentRange]) -> String {
        "[" + ranges.map {
            #"{"segment":\#($0.segment),"sourceOffset":\#($0.sourceOffset),"destinationOffset":\#($0.destinationOffset),"length":\#($0.length)}"#
        }.joined(separator: ", ") + "]"
    }

    static func serialize(_ value: String) -> String {
        var output = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\"":
                output += "\\\""
            case "\\":
                output += "\\\\"
            case "\u{08}":
                output += "\\b"
            case "\u{0c}":
                output += "\\f"
            case "\n":
                output += "\\n"
            case "\r":
                output += "\\r"
            case "\t":
                output += "\\t"
            case "\u{00}"..."\u{1f}":
                output += unicodeEscape(scalar.value)
            default:
                output.unicodeScalars.append(scalar)
            }
        }
        output += "\""
        return output
    }

    static func unicodeEscape(_ value: UInt32) -> String {
        let digits = Array("0123456789abcdef")
        return "\\u" + (0..<4).map { shift in
            let nibble = Int((value >> UInt32((3 - shift) * 4)) & 0xf)
            return String(digits[nibble])
        }.joined()
    }
}
