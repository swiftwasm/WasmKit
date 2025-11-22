#if WasmDebuggingSupport

    import NIOCore
    import WasmKit

    let executableCodeOffset = UInt64(0x4000_0000_0000_0000)

    struct DebuggerMemoryCache: ~Copyable {
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

        init(allocator: ByteBufferAllocator, wasmBinary: ByteBuffer) {
            self.allocator = allocator

            var stackOffset = Int(executableCodeOffset) + wasmBinary.readableBytes
            // Untyped raw Wasm values in VM's stack are stored as `UInt64`.
            stackOffset.roundUpToAlignment(for: UInt64.self)

            self.stackOffsetInProtocolSpace = UInt64(stackOffset)
            self.wasmBinary = wasmBinary
            self.stackFrames = allocator.buffer(capacity: 0)
        }

        mutating func getAddressOfLocal(debugger: inout Debugger, frameIndex: Int, localIndex: Int) throws -> UInt64 {
            let (frameBase, layout) = try debugger.packedStackFrame(frameIndex: frameIndex) { span, layout in
                self.stackFrames.writeBytes(span)
                return (self.stackFrames.writerIndex, layout)
            }

            self.stackFrameLayouts[frameIndex] = (frameBase, layout)

            // FIXME: adjust the address so that frame indices are accounted for
            let responseAddress = self.stackOffsetInProtocolSpace + UInt64(layout.localOffsets[localIndex])
            // let localPointer = try self.debugger.getLocalPointer(address: localAddress)
            // print("localPointer is \(localPointer)")
            // let responseAddress = self.stackOffsetInProtocolSpace + UInt64(localPointer - self.debugger.stackMemory.baseAddress!)

            return responseAddress
        }

        func readMemory(
            debugger: borrowing Debugger,
            addressInProtocolSpace: UInt64,
            length: Int
        ) -> ByteBufferView {
            var length = length

            if addressInProtocolSpace >= self.stackOffsetInProtocolSpace {
                print("stackMemory")
                let stackAddress = Int(addressInProtocolSpace - self.stackOffsetInProtocolSpace)
                print("stackAddress is \(stackAddress)")
                if stackAddress + length > self.stackFrames.readableBytes {
                    length = self.stackFrames.readableBytes - stackAddress
                }

                return self.stackFrames.readableBytesView[stackAddress..<(stackAddress + length)]
            } else if addressInProtocolSpace >= executableCodeOffset {
                print("wasmBinary")
                let codeAddress = Int(addressInProtocolSpace - executableCodeOffset)
                if codeAddress + length > wasmBinary.readableBytes {
                    length = wasmBinary.readableBytes - codeAddress
                }

                return wasmBinary.readableBytesView[codeAddress..<(codeAddress + length)]
            } else {
                fatalError("Linear memory reads are not implemented in the debugger yet.")
            }
        }

        mutating func invalidate() {
            self.stackFrames = self.allocator.buffer(capacity: 0)
            self.stackFrameLayouts = [:]
        }
    }

#endif
