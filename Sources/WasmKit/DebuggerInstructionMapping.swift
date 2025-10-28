
/// Two-way mapping between Wasm and internal iseq bytecode instructions. The implementation of the mapping
/// is private and is empty when `WasmDebuggingSupport` package trait is disabled.
struct DebuggerInstructionMapping {
#if WasmDebuggingSupport

    /// Mapping from iseq Pc to instruction addresses in the original binary.
    /// Used for handling current call stack requests issued by a ``Debugger`` instance.
    private var iseqToWasm = [Pc: Int]()

    /// Mapping from Wasm instruction addresses in the original binary to iseq instruction addresses.
    /// Used for handling breakpoint requests issued by a ``Debugger`` instance.
    private var wasmToIseq = [Int: Pc]()

    /// Wasm addresses sorted in ascending order for binary search when of the next closest mapped
    /// instruction, when no key is found in `wasmToIseqMapping`.
    private var wasmMappings = [Int]()

    mutating func add(wasm: Int, iseq: Pc) {
        // Don't override the existing mapping, only store a new pair if there's no mapping for a given key.
        if self.iseqToWasm[iseq] == nil {
            self.iseqToWasm[iseq] = wasm
        }
        if self.wasmToIseq[wasm] == nil {
            self.wasmToIseq[wasm] = iseq
        }
        self.wasmMappings.append(wasm)
    }

    /// Computes an address of WasmKit's iseq bytecode instruction that matches a given Wasm instruction address.
    /// - Parameter address: the Wasm instruction to find a mapping for.
    /// - Returns: A tuple with an address of found iseq instruction and the original Wasm instruction or next
    /// closest match if no direct match was found.
    func findIseq(forWasmAddress address: Int) -> (iseq: Pc, wasm: Int)? {
        // Look in the main mapping
        if let iseq = self.wasmToIseq[address] {
            return (iseq, address)
        }

        // If nothing found, find the closest Wasm address using binary search
        guard let nextAddress = self.wasmMappings.binarySearch(nextClosestTo: address),
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
#endif
}


#if WasmDebuggingSupport
    extension [Int] {
        /// Uses binary search to find an element in `self` that's next closest to a given value.
        /// - Parameter value: the array element to search for or to use as a baseline when searching.
        /// - Returns: array element `result`, where `result - value` is the smallest possible, while
        /// `result > value` also holds.
        package func binarySearch(nextClosestTo value: Int) -> Int? {
            switch self.count {
            case 0:
                return nil
            default:
                var slice = self[0..<self.count]
                while slice.count > 1 {
                    let middle = (slice.endIndex - slice.startIndex) / 2
                    if slice[middle] < value {
                        // Not found anything in the lower half, assigning higher half to `slice`.
                        slice = slice[(middle + 1)..<slice.endIndex]
                    } else {
                        // Not found anything in the higher half, assigning lower half to `slice`.
                        slice = slice[slice.startIndex..<middle]
                    }
                }

                return self[slice.startIndex]
            }
        }
    }

#endif
