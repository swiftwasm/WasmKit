@preconcurrency import _CWasmKit

// Direct-threaded execution needs one of Swift's calling conventions, which
// Clang offers for the architectures listed here and no others; see
// `runDirectThreaded` in Execution.swift. The guard itself additionally needs an
// operating system to take the signal, so Embedded targets are out.
#if !$Embedded && (arch(i386) || arch(x86_64) || arch(arm) || arch(arm64) || arch(arm64_32))

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
