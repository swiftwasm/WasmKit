import SystemExtras
import SystemPackage

/// A simple time-profiler for guest process to emit `chrome://tracing` format
/// This profiler works only when WasmKit is built with debug configuration (`swift build -c debug`)
@_documentation(visibility: internal)
public class GuestTimeProfiler: RuntimeInterceptor {
    struct Event: Codable {
        enum Phase: String, Codable {
            case begin = "B"
            case end = "E"
        }
        let ph: Phase
        let pid: Int
        let name: String
        let ts: Int
    }

    private let encode: (any Encodable) throws -> [UInt8]
    private let output: ([UInt8]) -> Void
    private var hasFirstEvent: Bool = false
    private let startTime: UInt64

    public init(
        encoder: some GuestTimeProfilerJSONEncoder,
        output: @escaping ([UInt8]) -> Void
    ) {
        self.encode = { try [UInt8](encoder.encode($0)) }
        self.output = output
        self.startTime = Self.getTimestamp()
    }

    private func eventLine(_ event: Event) -> [UInt8]? {
        return try? encode(event)
    }

    private func addEventLine(_ event: Event) {
        guard let line = eventLine(event) else { return }
        if !hasFirstEvent {
            self.output(Array("[\n".utf8))
            self.output(line)
            hasFirstEvent = true
        } else {
            self.output(Array(",\n".utf8))
            self.output(line)
        }
    }

    private static func getTimestamp() -> UInt64 {
        let clock: SystemExtras.Clock
        #if os(Linux)
            clock = .boottime
        #elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            clock = .rawMonotonic
        #elseif os(OpenBSD) || os(FreeBSD) || os(WASI)
            clock = .monotonic
        #else
            #error("Unsupported platform")
        #endif
        let timeSpec = try! clock.currentTime()
        return UInt64(timeSpec.nanoseconds / 1_000 + timeSpec.seconds * 1_000_000)
    }
    private func getDurationSinceStart() -> Int {
        Int(Self.getTimestamp() - startTime)
    }

    public func onEnterFunction(_ address: FunctionAddress, store: Store) {
        let functionName = try? store.nameRegistry.lookup(address)
        let event = Event(
            ph: .begin, pid: 1,
            name: functionName ?? "unknown function(0x\(String(address, radix: 16)))",
            ts: getDurationSinceStart()
        )
        addEventLine(event)
    }

    public func onExitFunction(_ address: FunctionAddress, store: Store) {
        let functionName = try? store.nameRegistry.lookup(address)
        let event = Event(
            ph: .end, pid: 1,
            name: functionName ?? "unknown function(0x\(String(address, radix: 16)))",
            ts: getDurationSinceStart()
        )
        addEventLine(event)
    }

    public func finalize() {
        output(Array("\n]".utf8))
    }
}

/// A top-level JSON encoder.
///
/// If you depend on `Foundation`, you can add a trivial conformance to this with
/// ```swift
/// extension JSONEncoder: GuestTimeProfilerJSONEncoder {}
/// ```
@_documentation(visibility: internal)
public protocol GuestTimeProfilerJSONEncoder {
    associatedtype Bytes: Collection<UInt8>
    func encode(_ output: some Encodable) throws -> Bytes
}
