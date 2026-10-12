import _CWasmKit
import _CWasmKit.Platform

import struct WasmParser.WasmFeatureSet

/// A WebAssembly execution engine.
///
/// An engine is responsible storing the configuration for the execution of
/// WebAssembly code such as interpreting mode, enabled features, etc.
/// Typically, you will need a single engine instance per application.
public final class Engine {
    static let isAddressSanitizerEnabled = wasmkit_address_sanitizer_enabled() == 1

    /// The engine configuration.
    public let configuration: EngineConfiguration
    let interceptor: EngineInterceptor?
    let funcTypeInterner: Interner<FunctionType>

    /// The head slot of the `returnCrossInstance` handler under this engine's
    /// threading model.
    ///
    /// `_return` hands a cross-instance return off by re-dispatching to that
    /// handler. Looking the slot up from a handler would mean a call (the
    /// handler table is a lazily initialised global), and a call means a
    /// stack frame on the hottest return path, so it is computed once here
    /// and read through the execution state instead.
    let crossInstanceReturnSlot: CodeSlot

    /// The epoch of this engine, advanced by ``incrementEpoch()`` from any thread.
    let epochCounter = Cell<UInt64>(0)

    /// Whether this engine has an interceptor which is unsafe to share with
    /// concurrently executing stores.
    package var hasInterceptor: Bool { interceptor != nil }

    /// Create a new execution engine.
    ///
    /// - Parameters:
    ///   - configuration: The engine configuration.
    ///   - interceptor: An optional runtime interceptor to intercept execution of instructions.
    public init(
        configuration: EngineConfiguration = EngineConfiguration(),
        interceptor: EngineInterceptor? = nil
    ) {
        var configuration = configuration

        // If mprotect-based memory bounds checking is unavailable on the current platform,
        // incompatible with AddressSanitizer, or explicitly requested with token threading,
        // fall back to software bounds checking.
        if WASMKIT_MPROTECT_BOUND_CHECKING == 0
            || Engine.isAddressSanitizerEnabled
            || (configuration.memoryBoundsChecking == .mprotect && configuration.threadingModel == .token)
        {
            configuration.memoryBoundsChecking = .software
        }

        self.configuration = configuration
        self.interceptor = interceptor
        self.funcTypeInterner = Interner()
        self.crossInstanceReturnSlot = Instruction.returnCrossInstance(.init()).headSlot(
            threadingModel: configuration.threadingModel
        )
    }

    /// Advances this engine's epoch by one tick.
    ///
    /// Safe to call from any thread, including while stores on this engine run guest code: this
    /// is how another thread stops them. With ``EngineConfiguration/epochInterruption``, guest
    /// code checks the epoch at every function entry and loop header, and stops once it reaches
    /// the deadline set by ``Store/setEpochDeadline(ticksBeyondCurrent:)``. A ``ResumableCall``
    /// suspends there, and any other call traps.
    ///
    /// A tick is whatever the embedder makes it, typically a timer firing. The check does not
    /// synchronize with the increment, so a running guest notices the new epoch shortly after,
    /// not at once.
    public func incrementEpoch() {
        wasmkit_epoch_increment(epochCounter.address)
    }

    /// Migration aid for the old ``Runtime/instantiate(module:)``
    @available(*, unavailable, message: "Use ``Module/instantiate(store:imports:)`` instead")
    public func instantiate(module: Module) -> Instance { fatalError() }
}

// `configuration` is immutable, `funcTypeInterner` synchronizes its mutable
// state, and `epochCounter` is only accessed atomically. Concurrent clients must reject engines with interceptors, whose
// implementations are not currently Sendable.
extension Engine: @unchecked Sendable {}

/// The configuration for the WebAssembly execution engine.
public struct EngineConfiguration: Sendable {
    /// The threading model, which determines how to dispatch instruction
    /// execution, to use for the virtual machine interpreter.
    public enum ThreadingModel: Sendable {
        /// Direct threaded code
        /// - Note: This is the default model for platforms that support
        /// `musttail` calls.
        case direct
        /// Indirect threaded code
        /// - Note: This is a fallback model for platforms that do not support
        /// `musttail` calls.
        case token

        static var useDirectThreadedCode: Bool {
            return WASMKIT_USE_DIRECT_THREADED_CODE == 1
        }

        static var defaultForCurrentPlatform: ThreadingModel {
            #if $Embedded
                // Direct threading is available on an embedded target but not
                // chosen for it: whether the convention it is built with really
                // tail calls is a property of the target, and a wrong guess
                // there exhausts the stack rather than running slowly. An
                // embedded host asks for `.direct` deliberately.
                return .token
            #elseif arch(i386) || arch(x86_64) || arch(arm) || arch(arm64) || arch(arm64_32)
                return useDirectThreadedCode ? .direct : .token
            #else
                return .token
            #endif
        }
    }

    /// The threading model to use for the virtual machine interpreter.
    public var threadingModel: ThreadingModel

    /// The compilation mode of WebAssembly modules to the internal virtual
    /// machine instruction sequence.
    public enum CompilationMode: Sendable {
        /// Eager compilation, where the module is compiled to the internal
        /// instruction sequence immediately after instantiation.
        case eager

        /// Lazy compilation, where the module is compiled to the internal
        /// instruction sequence only when the first function is called.
        case lazy
    }

    /// The compilation mode to use for WebAssembly modules.
    public var compilationMode: CompilationMode

    /// The stack size in bytes for the virtual machine interpreter. (Default: 512KB)
    ///
    /// Note: Typically, there are three kinds of stacks in a WebAssembly execution:
    /// 1. The native stack, which is used for native function calls.
    /// 2. The interpreter stack, which is used for allocating "local"
    ///    variables in the WebAssembly function and call frames of the
    ///    WebAssembly-level function calls.
    /// 3. The shadow stack, which is used by WebAssembly programs compiled
    ///    by LLVM-based compilers to implement pointers to local variables.
    ///    This stack is allocated in the WebAssembly memory space by
    ///    wasm-ld, so the interpreter does not care about it.
    ///
    /// The stack size here refers to the second stack, the interpreter stack
    /// size, so you may need to increase this value if you see
    /// "call stack exhausted" ``Trap`` errors thrown by the interpreter.
    public var stackSize: Int

    /// The WebAssembly features that can be used by Wasm modules running on this engine.
    public var features: WasmFeatureSet

    /// Linear memory bounds checking strategy.
    public enum MemoryBoundsChecking: Sendable {
        /// Request `mprotect` + signal based traps, but fall back to software checks if unavailable.
        case mprotect
        /// Always use software bounds checks.
        case software

        static var canUseMprotectMemoryBoundsChecking: Bool {
            return WASMKIT_MPROTECT_BOUND_CHECKING == 1
        }

        static var defaultForCurrentPlatform: MemoryBoundsChecking {
            if canUseMprotectMemoryBoundsChecking {
                return .mprotect
            } else {
                return .software
            }
        }
    }

    /// Preferred linear memory bounds checking strategy.
    ///
    /// This value is advisory: the engine may use a different strategy when the
    /// requested one is unavailable, incompatible with other configuration (for
    /// example threading model), or otherwise not applicable.
    public var memoryBoundsChecking: MemoryBoundsChecking

    /// Whether the engine instruments translated code to consume fuel as it runs. (Default: `false`)
    ///
    /// When enabled, give a store a budget with ``Store/fuel``. Execution traps once the budget
    /// is exhausted, and the store stays usable: set a new budget and call again.
    ///
    /// This is a translation-time property. Code translated by an engine without fuel metering is
    /// never metered, which is why this lives on the engine rather than on the store.
    public var fuelMetering: Bool

    /// Whether the engine instruments translated code to check the engine's epoch. (Default: `false`)
    ///
    /// When enabled, every function entry and loop header compares the epoch advanced by
    /// ``Engine/incrementEpoch()`` with the store's deadline, set with
    /// ``Store/setEpochDeadline(ticksBeyondCurrent:)``. Another thread can then stop a running
    /// guest: a ``ResumableCall`` suspends, and any other call traps.
    ///
    /// Like ``fuelMetering``, this is a translation-time property.
    public var epochInterruption: Bool

    /// FIXME: Make it public once we add mprotect-based bounds checking with JIT.
    /// Extra reserved bytes after the 4 GiB wasm32 address space for future
    /// unchecked constant-offset accesses in JIT code.
    internal var memoryOffsetGuardSize: Int = 64 * 1024

    /// Initializes a new instance of `EngineConfiguration`.
    ///
    /// - Parameter threadingModel: The threading model to use for the virtual
    /// machine interpreter. If `nil`, the default threading model for the
    /// current platform will be used.
    /// - Parameter compilationMode: The compilation mode to use for WebAssembly
    /// modules. If `nil`, the default compilation mode (lazy) will be used.
    /// - Parameter stackSize: The stack size in bytes for the virtual machine
    /// interpreter. If `nil`, the default stack size (512KB) will be used.
    /// - Parameter features: The WebAssembly features that can be used by Wasm
    /// modules running on this engine.
    /// - Parameter fuelMetering: Whether translated code consumes fuel as it
    /// runs, so that execution can be bounded with ``Store/fuel``.
    /// - Parameter epochInterruption: Whether translated code checks the engine's epoch, so that
    /// another thread can stop execution with ``Engine/incrementEpoch()``.
    public init(
        threadingModel: ThreadingModel? = nil,
        compilationMode: CompilationMode? = nil,
        stackSize: Int? = nil,
        features: WasmFeatureSet = .default,
        memoryBoundsChecking: MemoryBoundsChecking? = nil,
        fuelMetering: Bool = false,
        epochInterruption: Bool = false,
    ) {
        self.threadingModel = threadingModel ?? .defaultForCurrentPlatform
        self.compilationMode = compilationMode ?? .lazy
        self.stackSize = stackSize ?? (1 << 19)
        self.features = features
        self.memoryBoundsChecking = memoryBoundsChecking ?? .defaultForCurrentPlatform
        self.fuelMetering = fuelMetering
        self.epochInterruption = epochInterruption
    }
}

extension Engine {
    func resolveType(_ type: InternedFuncType) -> FunctionType {
        return funcTypeInterner.resolve(type)
    }
    func internType(_ type: FunctionType) -> InternedFuncType {
        return funcTypeInterner.intern(type)
    }
}
