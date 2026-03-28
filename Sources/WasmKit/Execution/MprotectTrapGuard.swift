#if os(macOS) || os(Linux)

    @preconcurrency import _CWasmKit

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
