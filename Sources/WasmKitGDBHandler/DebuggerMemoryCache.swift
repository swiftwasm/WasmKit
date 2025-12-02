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
        private let stackOffsetInProtocolSpace: UInt64

        /// WebAssembly binary loaded into memory for execution
        /// and for disassembly by the debugger.
        private let wasmBinary: ByteBuffer

        /// Cached packed stack frames that were previously requested.
        private var stackFrames: ByteBuffer

        /// Mapping from frame index to a base address of a frame in `stackFrames` buffer with
        /// its corresponding layout.
        private var stackFrameLayouts = [Int: (frameBase: Int, offsets: DebuggerStackFrame.Layout)]()

        package init(allocator: ByteBufferAllocator, wasmBinary: ByteBuffer) {
            self.allocator = allocator

            var stackOffset = Int(Self.executableCodeOffset) + wasmBinary.readableBytes
            // Untyped raw Wasm values in VM's stack are stored as `UInt64`.
            stackOffset.roundUpToAlignment(for: UInt64.self)

            self.stackOffsetInProtocolSpace = UInt64(stackOffset)
            self.wasmBinary = wasmBinary
            self.stackFrames = allocator.buffer(capacity: 0)
        }

        package mutating func getAddressOfLocal(debugger: inout Debugger, frameIndex: UInt, localIndex: UInt) throws -> UInt64 {
            let frameBase: Int
            let frameLayout: DebuggerStackFrame.Layout

            if let (base, layout) = self.stackFrameLayouts[Int(frameIndex)] {
                guard layout.localOffsets.count > localIndex else {
                    throw Debugger.Error.stackLocalIndexOOB(localIndex)
                }

                frameBase = base
                frameLayout = layout
            } else {
                let (base, layout) = try debugger.packedStackFrame(frameIndex: frameIndex) { span, layout in
                    let baseAddress = self.stackFrames.writerIndex
                    self.stackFrames.writeBytes(span)
                    return (baseAddress, layout)
                }

                self.stackFrameLayouts[Int(frameIndex)] = (base, layout)

                frameBase = base
                frameLayout = layout
            }

            return self.stackOffsetInProtocolSpace + UInt64(frameBase + frameLayout.localOffsets[Int(localIndex)])
        }

        package func readMemory(
            debugger: borrowing Debugger,
            addressInProtocolSpace: UInt64,
            length: UInt
        ) throws(Debugger.Error)-> ByteBufferView {

            if addressInProtocolSpace >= self.stackOffsetInProtocolSpace {
                var length = Int(length)
                let stackAddress = Int(addressInProtocolSpace - self.stackOffsetInProtocolSpace)
                if stackAddress + length > self.stackFrames.readableBytes {
                    length = self.stackFrames.readableBytes - stackAddress
                }

                return self.stackFrames.readableBytesView[stackAddress..<(stackAddress + length)]
            } else if addressInProtocolSpace >= Self.executableCodeOffset {
                var length = Int(length)
                let codeAddress = Int(addressInProtocolSpace - Self.executableCodeOffset)
                if codeAddress + length > wasmBinary.readableBytes {
                    length = wasmBinary.readableBytes - codeAddress
                }

                return wasmBinary.readableBytesView[codeAddress..<(codeAddress + length)]
            } else {
                return try debugger.readLinearMemory(address: UInt(addressInProtocolSpace), length: length) { span in
                    var buffer = self.allocator.buffer(capacity: span.byteCount)
                    span.withUnsafeBytes {
                        print(Array($0))
                    }
                    buffer.writeBytes(span)
                    return buffer.readableBytesView
                }
            }
        }

        package mutating func invalidate() {
            self.stackFrames = self.allocator.buffer(capacity: 0)
            self.stackFrameLayouts = [:]
        }
    }

#endif
