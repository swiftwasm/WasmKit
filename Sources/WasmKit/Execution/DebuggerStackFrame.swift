#if WasmDebuggingSupport

struct DebuggerStackFrame: ~Copyable {
    var buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1, alignment: 8)

    init() {
        buffer.initializeMemory(as: Int.self, repeating: 0)
    }

    mutating func withFrames(sp: Sp, frameIndex: Int, store: Store, writer: (borrowing OutputRawSpan) -> ()) throws {
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

            let pessimisticByteCount = functionType.parameters.count * 8 + wasm.locals.count * 8 + iseq.maxStackHeight * 8

            if pessimisticByteCount > self.buffer.count {
                let newBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: pessimisticByteCount, alignment: 8)
                newBuffer.copyBytes(from: self.buffer)
                self.buffer.deallocate()
                self.buffer = newBuffer
            }

            var span = OutputRawSpan(buffer: self.buffer, initializedCount: 0)

            for (i, type) in functionType.parameters.enumerated() {
                switch type {
                case .i32, .f32:
                    span.append(frame.sp[i32: i], as: UInt32.self)
                case .i64, .f64:
                    span.append(frame.sp[i64: i], as: UInt64.self)
                case .v128:
                    fatalError("SIMD is not yet supported in the Wasm debugger")
                case .ref:
                    fatalError("References are not yet supported in the wasm debugger")
                }
            }

            _ = span.finalize(for: self.buffer)

            let localsCount = functionType.parameters.count + currentFunction.numberOfNonParameterLocals
            let localTypes = wasm.locals
            iseq.maxStackHeight

        }
    }

    deinit {
        buffer.deallocate()
    }
}

#endif
