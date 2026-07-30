// The profiler writes its trace to a file, so it requires the FileSystem trait.
#if FileSystem
    #if canImport(Darwin)
        import Darwin
    #endif

    /// A simple time-profiler for guest process to emit `chrome://tracing` format
    /// This profiler works only when WasmKit is built with debug configuration (`swift build -c debug`)
    @_documentation(visibility: internal)
    public class GuestTimeProfiler: EngineInterceptor {
        struct Event: Codable {
            enum Phase: String, Codable {
                case begin = "B"
                case end = "E"
            }
            let ph: Phase
            let pid: Int
            let name: String
            let ts: Int

            var jsonLine: String {
                #"{"ph":"\#(ph.rawValue)","pid":\#(pid),"name":\#(JSON.serialize(name)),"ts":\#(ts)}"#
            }
        }

        private var output: (_ line: String) -> Void
        private var hasFirstEvent: Bool = false

        #if canImport(Darwin)
            // ContinuousClock requires a macOS 13+ deployment target, which builds
            // outside SwiftPM (e.g. the CMake toolchain build) don't guarantee, so
            // use the always-available raw-monotonic clock on Darwin.
            private typealias Instant = UInt64

            private static func getTimestamp() -> UInt64 {
                clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) / 1_000
            }

            private func getDurationSinceStart() -> Int {
                Int(Self.getTimestamp() - startTime)
            }

        #else

            private typealias Instant = ContinuousClock.Instant

            private static func getTimestamp() -> Instant {
                ContinuousClock.now
            }

            private func getDurationSinceStart() -> Int {
                let duration = self.startTime.duration(to: .now)
                let (seconds, attoseconds) = duration.components
                // Convert to microseconds
                return Int(seconds * 1_000_000 + attoseconds / 1_000_000_000_000)
            }
        #endif

        private let startTime: Instant

        public init(output: @escaping (_ line: String) -> Void) {
            self.output = output
            self.startTime = Self.getTimestamp()
            self.output("[\n")
        }

        private func addEventLine(_ event: Event) {
            let line = event.jsonLine
            if !hasFirstEvent {
                self.output(line)
                hasFirstEvent = true
            } else {
                self.output(",\n")
                self.output(line)
            }
        }

        public func onEnterFunction(_ function: Function) {
            let event = Event(
                ph: .begin, pid: 1,
                name: function.store.nameRegistry.symbolicate(function.handle),
                ts: getDurationSinceStart()
            )
            addEventLine(event)
        }

        public func onExitFunction(_ function: Function) {
            let event = Event(
                ph: .end, pid: 1,
                name: function.store.nameRegistry.symbolicate(function.handle),
                ts: getDurationSinceStart()
            )
            addEventLine(event)
        }

        public func finalize() {
            output("\n]")
        }
    }

    /// Foundation-less JSON serialization
    private enum JSON {
        static func serialize(_ value: String) -> String {
            // https://www.ietf.org/rfc/rfc4627.txt
            var output = "\""
            for scalar in value.unicodeScalars {
                switch scalar {
                case "\"":
                    output += "\\\""
                case "\\":
                    output += "\\\\"
                case "\u{08}":
                    output += "\\b"
                case "\u{0C}":
                    output += "\\f"
                case "\n":
                    output += "\\n"
                case "\r":
                    output += "\\r"
                case "\t":
                    output += "\\t"
                case "\u{20}"..."\u{21}", "\u{23}"..."\u{5B}", "\u{5D}"..."\u{10FFFF}":
                    output.unicodeScalars.append(scalar)
                default:
                    var hex = String(scalar.value, radix: 16, uppercase: true)
                    hex = String(repeating: "0", count: 4 - hex.count) + hex
                    output += "\\u" + hex
                }
            }
            output += "\""
            return output
        }
    }
#endif  // FileSystem
