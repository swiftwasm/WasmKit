#if DEBUG

import Foundation
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

    private var output: (Data) -> Void
    private var hasFirstEvent: Bool = false
    private let encoder = JSONEncoder()
    private let startTime: UInt64

    public init(output: @escaping (Data) -> Void) {
        self.output = output
        self.startTime = Self.getTimestamp()
    }

    private func eventLine(_ event: Event) -> Data? {
        return try? encoder.encode(event)
    }

    private func addEventLine(_ event: Event) {
        guard let line = eventLine(event) else { return }
        if !hasFirstEvent {
            self.output("[\n".data(using: .utf8)!)
            self.output(line)
            hasFirstEvent = true
        } else {
            self.output(",\n".data(using: .utf8)!)
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
            name: functionName ?? "unknown function(\(String(format: "0x%x", address)))",
            ts: getDurationSinceStart()
        )
        addEventLine(event)
    }

    public func onExitFunction(_ address: FunctionAddress, store: Store) {
        let functionName = try? store.nameRegistry.lookup(address)
        let event = Event(
            ph: .end, pid: 1,
            name: functionName ?? "unknown function(\(String(format: "0x%x", address)))",
            ts: getDurationSinceStart()
        )
        addEventLine(event)
    }

    public func finalize() {
        output("\n]".data(using: .utf8)!)
    }
}

#endif
