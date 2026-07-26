// Instruction-statistics collection, enabled only with the `EngineStats`
// package trait. Everything here, including the stderr output stream, is
// compiled out otherwise.
#if EngineStats

    #if os(Windows)
        import ucrt
    #elseif canImport(Darwin)
        import Darwin
    #elseif canImport(Musl)
        import Musl
    #elseif canImport(Glibc)
        import Glibc
    #elseif canImport(Android)
        import Android
    #elseif canImport(WASILibc)
        import WASILibc
    #endif

    /// Standard error output stream.
    struct _Stderr: TextOutputStream {
        func write(_ string: String) {
            if string.isEmpty { return }
            var string = string
            string.withUTF8 {
                _ = fwrite($0.baseAddress!, 1, $0.count, stderr)
            }
        }
    }

    extension Execution {
        /// A helper structure for collecting instruction statistics.
        /// - Note: This is used only when the `EngineStats` trait is enabled.
        struct StatsCollector {
            struct Trigram: Hashable {
                var a: UInt64
                var b: UInt64
                var c: UInt64
            }

            struct CircularBuffer<T> {
                private var buffer: [T?]
                private var index: Int = 0

                init(capacity: Int) {
                    buffer = Array(repeating: nil, count: capacity)
                }

                /// Accesses the element at the specified position counted from the oldest element.
                subscript(_ index: Int) -> T? {
                    get {
                        return buffer[(self.index + index) % buffer.count]
                    }
                    set {
                        buffer[(self.index + index) % buffer.count] = newValue
                    }
                }

                mutating func append(_ value: T) {
                    buffer[index] = value
                    index = (index + 1) % buffer.count
                }
            }

            /// A dictionary that stores the count of each trigram pattern.
            private var countByTrigram: [Trigram: Int] = [:]
            /// A circular buffer that stores the last three instructions.
            private var buffer = CircularBuffer<UInt64>(capacity: 3)

            /// Tracks the given instruction index. This function is called for each instruction execution.
            mutating func track(_ opcode: UInt64) {
                buffer.append(opcode)
                if let a = buffer[0], let b = buffer[1], let c = buffer[2] {
                    let trigram = Trigram(a: a, b: b, c: c)
                    countByTrigram[trigram, default: 0] += 1
                }
            }

            func dump<TargetStream: TextOutputStream>(target: inout TargetStream, limit: Int) {
                print("Instruction statistics:", to: &target)
                for (trigram, count) in countByTrigram.sorted(by: { $0.value > $1.value }).prefix(limit) {
                    print("  \(Instruction.name(opcode: trigram.a)) -> \(Instruction.name(opcode: trigram.b)) -> \(Instruction.name(opcode: trigram.c)) = \(count)", to: &target)
                }
            }

            /// Dumps the instruction statistics to the standard error output stream.
            func dump(limit: Int = 10) {
                var target = _Stderr()
                dump(target: &target, limit: limit)
            }
        }
    }
#endif  // EngineStats
