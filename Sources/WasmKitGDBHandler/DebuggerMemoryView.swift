//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if WasmDebuggingSupport

    import WasmKit

    package struct DebuggerMemoryView: ~Copyable {
        /// Addresses tag their space in bits 63:62: 0 is linear memory, 1 the object
        /// space holding the module image.
        private static let objectSpaceTag = UInt64(1) << 62

        /// The id of the only module instance the debugger runs, carried in bits 61:32
        /// of the addresses reported for it.
        package static let moduleInstanceID = UInt64(0)

        package static let executableCodeOffset = objectSpaceTag | (moduleInstanceID << 32)

        package enum Error: Swift.Error {
            /// The module image mapped at ``executableCodeOffset`` is read-only.
            case codeIsNotWritable(UInt64)

            /// The address exceeds the target's pointer width.
            case addressNotRepresentable(UInt64)

            /// The address lies outside every mapped region.
            case addressUnmapped(UInt64)
        }

        /// WebAssembly binary loaded into memory for execution
        /// and for disassembly by the debugger.
        private let wasmBinary: [UInt8]

        package init(wasmBinary: [UInt8]) {
            self.wasmBinary = wasmBinary
        }

        /// The bytes at `addressInProtocolSpace`, narrowed to the end of the region containing it.
        package func readMemory(
            debugger: borrowing Debugger,
            addressInProtocolSpace: UInt64,
            length: UInt
        ) throws -> [UInt8] {
            // An empty read touches nothing, so it needs no mapping to answer.
            guard length > 0 else { return [] }

            if addressInProtocolSpace >= Self.executableCodeOffset {
                let codeAddress = addressInProtocolSpace - Self.executableCodeOffset
                guard codeAddress < UInt64(wasmBinary.count) else {
                    throw Error.addressUnmapped(addressInProtocolSpace)
                }

                let start = Int(codeAddress)
                let count = Int(min(UInt64(length), UInt64(wasmBinary.count - start)))
                return Array(wasmBinary[start..<(start + count)])
            } else {
                guard let address = UInt(exactly: addressInProtocolSpace) else {
                    throw Error.addressNotRepresentable(addressInProtocolSpace)
                }

                let mapped = UInt(debugger.linearMemoryByteCount)
                guard address < mapped else {
                    throw Error.addressUnmapped(addressInProtocolSpace)
                }

                return try debugger.readLinearMemory(address: address, length: min(length, mapped - address)) {
                    Array($0)
                }
            }
        }

        package func writeMemory(
            debugger: inout Debugger,
            addressInProtocolSpace: UInt64,
            bytes: some Collection<UInt8>
        ) throws {
            guard addressInProtocolSpace < Self.executableCodeOffset else {
                throw Error.codeIsNotWritable(addressInProtocolSpace)
            }

            guard let address = UInt(exactly: addressInProtocolSpace) else {
                throw Error.addressNotRepresentable(addressInProtocolSpace)
            }

            try debugger.writeLinearMemory(address: address, bytes: bytes)
        }

        /// A range of the address space a debugger host sees, mapped or not.
        package struct MemoryRegion {
            package let start: UInt64
            package let size: UInt64

            /// Nil when unmapped: the protocol omits the key for unmapped regions.
            package let permissions: String?
            package let name: String?
        }

        /// Linear memory is bounded by what the guest can see, not the underlying reservation,
        /// because access beyond it faults instead of trapping.
        private func mappedRegions(debugger: borrowing Debugger) -> [MemoryRegion] {
            [
                MemoryRegion(
                    start: 0,
                    size: UInt64(debugger.linearMemoryByteCount),
                    permissions: "rw",
                    name: "memory"
                ),
                MemoryRegion(
                    start: Self.executableCodeOffset,
                    size: UInt64(self.wasmBinary.count),
                    permissions: "rx",
                    name: "module"
                ),
            ].filter { $0.size > 0 }
        }

        /// The region containing `addressInProtocolSpace`. Unmapped regions span to the next
        /// mapped region or the top of the address space.
        package func memoryRegion(
            debugger: borrowing Debugger,
            containing addressInProtocolSpace: UInt64
        ) -> MemoryRegion {
            let mapped = self.mappedRegions(debugger: debugger)

            if let region = mapped.first(where: {
                addressInProtocolSpace >= $0.start && addressInProtocolSpace - $0.start < $0.size
            }) {
                return region
            }

            let next = mapped.lazy.map(\.start).filter { $0 > addressInProtocolSpace }.min()
            return MemoryRegion(
                start: addressInProtocolSpace,
                size: (next ?? UInt64.max) - addressInProtocolSpace,
                permissions: nil,
                name: nil
            )
        }
    }

#endif
