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
        package static let executableCodeOffset = UInt64(0x4000_0000_0000_0000)

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

    }

#endif
