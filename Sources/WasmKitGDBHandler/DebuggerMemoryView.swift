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
        }

        /// WebAssembly binary loaded into memory for execution
        /// and for disassembly by the debugger.
        private let wasmBinary: [UInt8]

        package init(wasmBinary: [UInt8]) {
            self.wasmBinary = wasmBinary
        }

        package func readMemory(
            debugger: borrowing Debugger,
            addressInProtocolSpace: UInt64,
            length: UInt
        ) throws(Debugger.Error) -> [UInt8] {
            if addressInProtocolSpace >= Self.executableCodeOffset {
                var length = Int(length)
                let codeAddress = Int(addressInProtocolSpace - Self.executableCodeOffset)
                if codeAddress + length > wasmBinary.count {
                    length = wasmBinary.count - codeAddress
                }

                return Array(wasmBinary[codeAddress..<(codeAddress + length)])
            } else {
                return try debugger.readLinearMemory(address: UInt(addressInProtocolSpace), length: length) {
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
    }

#endif
