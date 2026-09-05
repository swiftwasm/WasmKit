/// Two-way mapping between Wasm and internal iseq bytecode instructions. The implementation of the mapping
/// is private and is empty when `WasmDebuggingSupport` package trait is disabled.
struct DebuggerInstructionMapping {
    #if WasmDebuggingSupport

        /// Mapping from iseq Pc to instruction addresses in the original binary.
        /// Used for handling current call stack requests issued by a ``Debugger`` instance.
        private var iseqToWasm = [Pc: Int]()

        /// Map from iseq Pc to the start of its instruction run.
        private var iseqToCanonicalWasm = [Pc: Int]()

        /// Mapping from Wasm instruction addresses in the original binary to iseq instruction addresses.
        /// Used for handling breakpoint requests issued by a ``Debugger`` instance.
        private var wasmToIseq = [Int: Pc]()

        /// Last iseq slot emitted for a Wasm address when multiple instructions share an address.
        private var lastWasmToIseq = [Int: Pc]()

        /// Sorted emitting Wasm addresses for binary search when an address has no direct mapping.
        private var wasmMappings = [Int]()

        mutating func add(canonical: Int, emitting: Int, iseq: Pc) {
            // Don't override the existing mapping, only store a new pair if there's no mapping for a given key.
            if self.iseqToWasm[iseq] == nil {
                self.iseqToWasm[iseq] = emitting
            }
            if self.iseqToCanonicalWasm[iseq] == nil {
                self.iseqToCanonicalWasm[iseq] = canonical
            }
            if self.wasmToIseq[emitting] == nil {
                self.wasmToIseq[emitting] = iseq
            }
            self.lastWasmToIseq[emitting] = iseq
            // Insert in sorted order to maintain the binary search invariant.
            // With lazy compilation, functions may be compiled out of address order,
            // so simple append would break the sorted invariant.
            if let last = self.wasmMappings.last, emitting > last {
                // Fast path: appending in order (common within a single function)
                self.wasmMappings.append(emitting)
            } else if self.wasmMappings.last == emitting {
                // Duplicate of last entry, skip
            } else if self.wasmMappings.isEmpty {
                self.wasmMappings.append(emitting)
            } else {
                // Out-of-order insertion: find the sorted position
                let insertionIndex = self.wasmMappings.firstIndex(where: { $0 >= emitting }) ?? self.wasmMappings.endIndex
                if insertionIndex < self.wasmMappings.endIndex, self.wasmMappings[insertionIndex] == emitting {
                    // Already present, skip
                } else {
                    self.wasmMappings.insert(emitting, at: insertionIndex)
                }
            }
        }

        /// The bytecode slot for the Wasm instruction at exactly `address`, if it emitted any.
        func iseq(forWasmAddress address: Int) -> Pc? {
            self.wasmToIseq[address]
        }

        /// Computes an address of WasmKit's iseq bytecode instruction that matches a given Wasm instruction address.
        /// - Parameters:
        ///   - address: the Wasm instruction to find a mapping for.
        ///   - bound: Exclusive upper bound. Prevents resolving into a neighboring function.
        /// - Returns: A tuple with an address of found iseq instruction and the original Wasm instruction or next
        /// closest match if no direct match was found.
        func findIseq(forWasmAddress address: Int, before bound: Int) -> (iseq: Pc, wasm: Int)? {
            guard address < bound else { return nil }

            // Look in the main mapping
            if let iseq = self.wasmToIseq[address] {
                return (iseq, address)
            }

            // If nothing found, find the closest Wasm address using binary search
            guard let nextAddress = self.wasmMappings.binarySearch(nextClosestTo: address),
                nextAddress < bound,
                // Look in the main mapping again with the next closest address if binary search produced anything
                let iseq = self.wasmToIseq[nextAddress]
            else {
                return nil
            }

            return (iseq, nextAddress)
        }

        func findWasm(forIseqAddress pc: Pc) -> Int? {
            self.iseqToWasm[pc]
        }

        /// Start of the Wasm instruction run sharing this slot.
        func firstWasm(forIseqAddress pc: Pc) -> Int? {
            self.iseqToCanonicalWasm[pc]
        }

        func lastIseq(forWasmAddress address: Int) -> Pc? {
            self.lastWasmToIseq[address]
        }
    #endif
}

#if WasmDebuggingSupport
    extension RandomAccessCollection {
        /// Index of the first element for which `belongsInSecondPartition` is true, assuming
        /// the collection is partitioned by that predicate.
        func partitioningIndex(where belongsInSecondPartition: (Element) -> Bool) -> Index {
            var low = self.startIndex
            var high = self.endIndex
            while low < high {
                let middle = self.index(low, offsetBy: self.distance(from: low, to: high) / 2)
                if belongsInSecondPartition(self[middle]) {
                    high = middle
                } else {
                    low = self.index(after: middle)
                }
            }
            return low
        }
    }

    extension [Int] {
        /// Uses binary search to find an element in `self` that's next closest to a given value.
        /// - Parameter value: the array element to search for or to use as a baseline when searching.
        /// - Returns: array element `result`, where `result - value` is the smallest possible, while
        /// `result >= value` also holds.
        package func binarySearch(nextClosestTo value: Int) -> Int? {
            let index = self.partitioningIndex { $0 >= value }
            return index < self.endIndex ? self[index] : nil
        }
    }
#endif
