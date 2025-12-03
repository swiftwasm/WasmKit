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

    import NIOCore
    import WasmKit

    package struct DebuggerMemoryCache: ~Copyable {
        package static let executableCodeOffset = UInt64(0x4000_0000_0000_0000)

        private let allocator: ByteBufferAllocator

        /// WebAssembly binary loaded into memory for execution
        /// and for disassembly by the debugger.
        private let wasmBinary: ByteBuffer

        package init(allocator: ByteBufferAllocator, wasmBinary: ByteBuffer) {
            self.allocator = allocator

            self.wasmBinary = wasmBinary
        }

        package func readMemory(
            debugger: borrowing Debugger,
            addressInProtocolSpace: UInt64,
            length: UInt
        ) throws(Debugger.Error) -> ByteBufferView {
            if addressInProtocolSpace >= Self.executableCodeOffset {
                var length = Int(length)
                let codeAddress = Int(addressInProtocolSpace - Self.executableCodeOffset)
                if codeAddress + length > wasmBinary.readableBytes {
                    length = wasmBinary.readableBytes - codeAddress
                }

                return wasmBinary.readableBytesView[codeAddress..<(codeAddress + length)]
            } else {
                return try debugger.readLinearMemory(address: UInt(addressInProtocolSpace), length: length) {
                    var buffer = self.allocator.buffer(capacity: $0.count)
                    buffer.writeBytes($0)
                    return buffer.readableBytesView
                }
            }
        }

    }

#endif
