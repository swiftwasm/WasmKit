#if WASMKIT_MPROTECT_BOUND_CHECKING && !os(WASI)

    @preconcurrency import _CWasmKit

    final class WasmKitTokenThreadedTrapGuardBox {
        var execution: UnsafeMutablePointer<Execution>
        var sp: UnsafeMutablePointer<Sp>
        var pc: UnsafeMutablePointer<Pc>
        var md: UnsafeMutablePointer<Md>
        var ms: UnsafeMutablePointer<Ms>
        var thrownError: Error?

        init(
            execution: UnsafeMutablePointer<Execution>,
            sp: UnsafeMutablePointer<Sp>,
            pc: UnsafeMutablePointer<Pc>,
            md: UnsafeMutablePointer<Md>,
            ms: UnsafeMutablePointer<Ms>
        ) {
            self.execution = execution
            self.sp = sp
            self.pc = pc
            self.md = md
            self.ms = ms
            self.thrownError = nil
        }
    }

    let wasmkit_token_threaded_trap_guard_entry: @convention(c) (UnsafeMutableRawPointer?) -> Void = { raw in
        guard let raw else { return }
        let box = Unmanaged<WasmKitTokenThreadedTrapGuardBox>.fromOpaque(raw).takeUnretainedValue()

        let instance = box.execution.pointee.currentInstance(sp: box.sp.pointee)
        if let memory = instance.memories.first {
            memory.withValue { memoryEntity in
                box.md.pointee = memoryEntity.baseAddress
                box.ms.pointee = memoryEntity.byteCount
                wasmkit_trap_guard_set_current_memory(box.md.pointee, memoryEntity.trapGuardReservationSize)
            }
        } else {
            wasmkit_trap_guard_set_current_memory(nil, 0)
        }

        do {
            try box.execution.pointee.runTokenThreadedImpl(
                sp: &box.sp.pointee,
                pc: &box.pc.pointee,
                md: &box.md.pointee,
                ms: &box.ms.pointee
            )
        } catch {
            box.thrownError = error
        }
    }

    struct WasmKitDirectThreadedTrapGuardContext {
        var exec: wasmkit_tc_exec
        var sp: Sp
        var pc: Pc
        var md: Md
        var ms: Ms
        var state: UnsafeMutableRawPointer
    }

    let wasmkit_direct_threaded_trap_guard_entry: @convention(c) (UnsafeMutableRawPointer?) -> Void = { raw in
        guard let raw else { return }
        let context = raw.assumingMemoryBound(to: WasmKitDirectThreadedTrapGuardContext.self)

        let execution = context.pointee.state.assumingMemoryBound(to: Execution.self)
        let instance = execution.pointee.currentInstance(sp: context.pointee.sp)
        if let memory = instance.memories.first {
            memory.withValue { memoryEntity in
                wasmkit_trap_guard_set_current_memory(context.pointee.md, memoryEntity.trapGuardReservationSize)
            }
        } else {
            wasmkit_trap_guard_set_current_memory(nil, 0)
        }

        wasmkit_tc_start(
            context.pointee.exec,
            context.pointee.sp,
            context.pointee.pc,
            context.pointee.md,
            context.pointee.ms,
            context.pointee.state
        )
    }

#endif
