#if WasmDebuggingSupport

    import NIOCore
    import WasmKit

    let debuggerCodeOffset = UInt64(0x4000_0000_0000_0000)

    struct DebuggerMemoryCache: ~Copyable {
        private let allocator: ByteBufferAllocator
        private let stackOffsetInProtocolSpace: UInt64

        private let wasmBinary: ByteBuffer

        /// Mapping from frame index to a buffer with packed representation of a frame with its layout.
        private var stackFrames = [Int: (ByteBuffer, DebuggerStackFrame.Layout)]()

        init(allocator: ByteBufferAllocator, wasmBinary: ByteBuffer) {
            self.allocator = allocator

            var stackOffset = Int(debuggerCodeOffset) + wasmBinary.readableBytes
            // Untyped raw Wasm values in VM's stack are stored as `UInt64`.
            stackOffset.roundUpToAlignment(for: UInt64.self)

            self.stackOffsetInProtocolSpace = UInt64(stackOffset)
            self.wasmBinary = wasmBinary
        }

        func getAddressOfLocal(debugger: inout Debugger, frameIndex: Int, localIndex: Int) throws -> UInt64 {
                let (buffer, layout) = try debugger.packedStackFrame(frameIndex: frameIndex) { span, layout in
                    var buffer = self.allocator.buffer(capacity: span.byteCount)
                    buffer.writeBytes(span)
                    return (buffer, layout)
                }

                self.stackFrames[frameIndex] = (buffer, layout)
                // FIXME: adjust the address so that frame indices are accounted for
                let responseAddress = self.stackOffsetInProtocolSpace + UInt64(layout.localOffsets[localIndex])
                // let localPointer = try self.debugger.getLocalPointer(address: localAddress)
                // print("localPointer is \(localPointer)")
                // let responseAddress = self.stackOffsetInProtocolSpace + UInt64(localPointer - self.debugger.stackMemory.baseAddress!)

                return responseAddress

        }

        func readMemory(debugger: borrowing Debugger,
            addressInProtocolSpace: UInt64,
            length: Int
        ) -> ByteBufferView {
            var length = length

            if addressInProtocolSpace >= self.stackOffsetInProtocolSpace {
                print("stackMemory")
                let stackAddress = Int(addressInProtocolSpace - self.stackOffsetInProtocolSpace)
                print("stackAddress is \(stackAddress)")
                if stackAddress + length > debugger.stackMemory.count {
                    length = debugger.stackMemory.count - stackAddress
                }

                return ByteBuffer(
                        bytes: debugger.stackMemory[stackAddress..<(stackAddress + length)]
                    ).readableBytesView
            } else if addressInProtocolSpace >= debuggerCodeOffset {
                print("wasmBinary")
                let codeAddress = Int(addressInProtocolSpace - debuggerCodeOffset)
                if codeAddress + length > wasmBinary.readableBytes {
                    length = wasmBinary.readableBytes - codeAddress
                }

                return wasmBinary.readableBytesView[codeAddress..<(codeAddress + length)]
            } else {
                fatalError("Linear memory reads are not implemented in the debugger yet.")
            }
        }

        mutating func invalidate() {
            self.stackFrames = [:]
        }
    }

#endif
