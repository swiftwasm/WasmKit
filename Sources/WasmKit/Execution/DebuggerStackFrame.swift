#if WasmDebuggingSupport

    /// Encapsulates a caching buffer that stores a stack frame in debugger-friendly
    /// memory layout that's distinct from WasmKit's iseq stack frame memory layout.
    package struct DebuggerStackFrame: ~Copyable {
        private var buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1, alignment: 8)

        package struct Layout {
            /// Array of byte offsets from frame base address for each local at a given index.
            package fileprivate(set) var localOffsets = [Int]()
        }

        init() {
            buffer.initializeMemory(as: Int.self, repeating: 0)
        }

        mutating func withFrames<T>(sp: Sp, frameIndex: Int, store: Store, reader: (borrowing RawSpan, Layout) -> T) throws -> T {
            self.buffer.initializeMemory(as: Int.self, repeating: 0)

            var i = 0
            for frame in Execution.CallStack(sp: sp) {
                guard frameIndex == i else {
                    i += 1
                    continue
                }

                guard let currentFunction = frame.sp.currentFunction else {
                    throw Debugger.Error.unknownCurrentFunctionForResumedBreakpoint(frame.sp)
                }

                try currentFunction.ensureCompiled(store: StoreRef(store))

                guard case .debuggable(let wasm, let iseq) = currentFunction.code else {
                    fatalError()
                }

                // Wasm function arguments are also addressed as locals.
                let functionType = store.engine.funcTypeInterner.resolve(currentFunction.type)

                let stackSlotByteCount = MemoryLayout<StackSlot>.size

                let pessimisticByteCount = functionType.parameters.count * stackSlotByteCount + wasm.locals.count * stackSlotByteCount + iseq.maxStackHeight * stackSlotByteCount

                if pessimisticByteCount > self.buffer.count {
                    let newBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: pessimisticByteCount, alignment: MemoryLayout<StackSlot>.alignment)
                    newBuffer.copyBytes(from: self.buffer)
                    self.buffer.deallocate()
                    self.buffer = newBuffer
                }

                var span = OutputRawSpan(buffer: self.buffer, initializedCount: 0)
                var layout = Layout()

                for (i, type) in functionType.parameters.enumerated() {
                    // See ``FrameHeaderLayout`` documentation for offset calculation details.
                    layout.localOffsets.append(span.byteCount)
                    type.append(to: &span, frame, offset: i - 3 - max(functionType.parameters.count, functionType.results.count))
                }

                for (i, type) in wasm.locals.enumerated() {
                    layout.localOffsets.append(span.byteCount)
                    type.append(to: &span, frame, offset: i)
                }

                // FIXME: copy over actual stack values
                span.append(repeating: 0, count: iseq.maxStackHeight, as: UInt64.self)

                _ = span.finalize(for: self.buffer)

                return reader(self.buffer.bytes, layout)
            }

            throw Debugger.Error.stackFrameIndexOOB(frameIndex)
        }

        deinit {
            buffer.deallocate()
        }
    }

    extension ValueType {
        fileprivate func append(
            to span: inout OutputRawSpan,
            _ frame: Execution.CallStack.FrameIterator.Element,
            offset: Int
        ) {
            switch self {
            case .i32, .f32:
                span.append(frame.sp[i32: offset], as: UInt32.self)
            case .i64, .f64:
                span.append(frame.sp[i64: offset], as: UInt64.self)
            case .v128:
                fatalError("SIMD is not yet supported in the Wasm debugger")
            case .ref:
                fatalError("References are not yet supported in the wasm debugger")
            }
        }
    }

#endif
