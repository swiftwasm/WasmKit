import CWasmKitWASIThreads
import Synchronization
import WasmKit
import WasmParser
import WasmTypes

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

/// Configuration for a process-oriented WASI Threads group.
public struct WASIThreadsConfiguration: Sendable {
    /// Maximum concurrently live guest threads, including the main guest thread.
    public var maximumThreads: Int
    /// Optional native pthread stack size. `nil` uses the platform default.
    public var nativeStackSize: Int?

    public init(maximumThreads: Int = 64, nativeStackSize: Int? = nil) {
        self.maximumThreads = maximumThreads
        self.nativeStackSize = nativeStackSize
    }
}

/// Process-oriented callbacks used after the main guest returns or a ready
/// worker fails. Both callbacks must terminate and never return.
public struct WASIThreadsProcessControl: Sendable {
    public var terminateAfterMainReturn: @Sendable (UInt32) -> Never
    public var terminateAfterWorkerFailure: @Sendable (any Error) -> Never

    public init(
        terminateAfterMainReturn: @escaping @Sendable (UInt32) -> Never,
        terminateAfterWorkerFailure: @escaping @Sendable (any Error) -> Never
    ) {
        self.terminateAfterMainReturn = terminateAfterMainReturn
        self.terminateAfterWorkerFailure = terminateAfterWorkerFailure
    }
}

/// Errors raised while constructing a WASI Threads group.
public enum WASIThreadsError: Error, Sendable, CustomStringConvertible {
    case invalidMaximumThreads
    case nativeStackSizeTooSmall(minimum: Int)
    case unsupportedPlatform
    case incompatibleEngine(String)

    public var description: String {
        switch self {
        case .invalidMaximumThreads: "WASI Threads maximumThreads must be at least one"
        case .nativeStackSizeTooSmall(let minimum): "WASI Threads native stack size must be at least \(minimum) bytes"
        case .unsupportedPlatform: "WASI Threads requires a 64-bit macOS or Linux host"
        case .incompatibleEngine(let reason): "WASI Threads requires \(reason)"
        }
    }
}

/// A failure that crossed the worker startup handshake.
public struct WASIThreadsStartupError: Error, Sendable, CustomStringConvertible {
    public let diagnostic: String
    public var description: String { diagnostic }
}

/// Process-scoped WASI Threads composition.
///
/// The module must import exactly the conventional shared wasm32 memory as
/// `env.memory`. Other module-shape constraints are embedder preconditions.
/// This API is intended for short-lived CLI processes, not long-lived embeds.
public final class WASIThreads: @unchecked Sendable {
    public typealias ChildImportsBuilder = @Sendable (Store) throws -> Imports

    private struct GroupState {
        var nextTID: Int32 = 1
        var liveThreads: Int = 1
    }

    private final class Startup: @unchecked Sendable {
        private enum State { case pending, ready, failed(WASIThreadsStartupError) }
        private let state = Mutex<State>(.pending)
        private let event: OpaquePointer

        init?() {
            guard let event = wasmkit_wasi_threads_event_create() else { return nil }
            self.event = event
        }

        deinit {
            wasmkit_wasi_threads_event_destroy(event)
        }

        func ready() {
            complete(.ready)
        }

        func failed(_ error: WASIThreadsStartupError) {
            complete(.failed(error))
        }

        func wait() -> WASIThreadsStartupError? {
            wasmkit_wasi_threads_event_wait(event)
            return state.withLock { state in
                if case .failed(let error) = state { return error }
                return nil
            }
        }

        private func complete(_ newState: State) {
            let completed = state.withLock { state -> Bool in
                guard case .pending = state else { return false }
                state = newState
                return true
            }
            precondition(completed, "worker startup must complete exactly once")
            wasmkit_wasi_threads_event_signal(event)
        }
    }

    private let module: Module
    private let engine: Engine
    private let configuration: WASIThreadsConfiguration
    private let processControl: WASIThreadsProcessControl
    private let childImports: ChildImportsBuilder
    private let state = Mutex<GroupState>(.init())

    public let sharedMemory: SharedMemory

    public init(
        module: Module,
        engine: Engine,
        configuration: WASIThreadsConfiguration = .init(),
        resourceLimiter: any ResourceLimiter = DefaultResourceLimiter(),
        processControl: WASIThreadsProcessControl,
        childImports: @escaping ChildImportsBuilder
    ) throws {
        guard configuration.maximumThreads >= 1 else { throw WASIThreadsError.invalidMaximumThreads }
        #if !MultiThread
            throw WASIThreadsError.incompatibleEngine("the MultiThread package trait")
        #endif
        #if os(macOS) || os(Linux)
            #if arch(x86_64) || arch(arm64)
            #else
                throw WASIThreadsError.unsupportedPlatform
            #endif
        #else
            throw WASIThreadsError.unsupportedPlatform
        #endif
        if let nativeStackSize = configuration.nativeStackSize, nativeStackSize < Int(PTHREAD_STACK_MIN) {
            throw WASIThreadsError.nativeStackSizeTooSmall(minimum: Int(PTHREAD_STACK_MIN))
        }
        guard engine.configuration.features.contains(.threads) else {
            throw WASIThreadsError.incompatibleEngine("the WebAssembly threads feature")
        }
        guard engine.configuration.threadingModel == .direct else {
            throw WASIThreadsError.incompatibleEngine("the direct threading model")
        }
        guard engine.configuration.memoryBoundsChecking == .mprotect else {
            throw WASIThreadsError.incompatibleEngine("mprotect memory bounds checking")
        }
        guard !engine.hasInterceptor else {
            throw WASIThreadsError.incompatibleEngine("an engine without an interceptor")
        }
        guard let memoryImport = module.imports.first(where: { $0.module == "env" && $0.name == "memory" }),
              case .memory(let memoryType) = memoryImport.descriptor,
              memoryType.shared,
              !memoryType.isMemory64
        else {
            preconditionFailure("WASI Threads requires a shared wasm32 memory import named env.memory")
        }

        self.module = module
        self.engine = engine
        self.configuration = configuration
        self.processControl = processControl
        self.childImports = childImports
        self.sharedMemory = try SharedMemory(engine: engine, type: memoryType, resourceLimiter: resourceLimiter)
    }

    /// Creates the imports for one store, including `env.memory` and
    /// `wasi.thread-spawn`.
    public func makeImports(store: Store) throws -> Imports {
        var imports = try childImports(store)
        imports.define(module: "env", name: "memory", Memory(store: store, sharedMemory: sharedMemory))
        imports.define(
            module: "wasi", name: "thread-spawn",
            Function(store: store, parameters: [.i32], results: [.i32]) { [self] _, arguments in
                [.i32(UInt32(bitPattern: spawn(Int32(bitPattern: arguments[0].i32))))]
            }
        )
        return imports
    }

    /// Terminates the process after the main guest invocation returns.
    public func mainThreadDidExit(code: UInt32) -> Never {
        processControl.terminateAfterMainReturn(code)
    }

    private func spawn(_ argument: Int32) -> Int32 {
        guard module.exportedFunctionType(named: "wasi_thread_start") == FunctionType(parameters: [.i32, .i32], results: []) else {
            return -1
        }
        guard let tid = reserveThread() else { return -1 }
        guard let startup = Startup() else { return -1 }
        let result = PlatformThread.start(stackSize: configuration.nativeStackSize) { [self] in
            runWorker(tid: tid, argument: argument, startup: startup)
        }
        guard result == 0 else {
            releaseThread()
            return -1
        }
        if startup.wait() != nil {
            return -1
        }
        return tid
    }

    private func reserveThread() -> Int32? {
        state.withLock { state in
            guard state.liveThreads < configuration.maximumThreads, state.nextTID <= 0x1FFF_FFFF else { return nil }
            let tid = state.nextTID
            state.nextTID += 1
            state.liveThreads += 1
            return tid
        }
    }

    private func releaseThread() {
        state.withLock { $0.liveThreads -= 1 }
    }

    private func runWorker(tid: Int32, argument: Int32, startup: Startup) {
        do {
            let store = Store(engine: engine)
            let imports = try makeImports(store: store)
            let instance = try module.instantiate(store: store, imports: imports)
            guard let entry = instance.exports[function: "wasi_thread_start"],
                  entry.type == FunctionType(parameters: [.i32, .i32], results: [])
            else {
                startup.failed(.init(diagnostic: "missing or incompatible wasi_thread_start export"))
                releaseThread()
                return
            }
            startup.ready()
            do {
                _ = try entry([.i32(UInt32(bitPattern: tid)), .i32(UInt32(bitPattern: argument))])
            } catch {
                processControl.terminateAfterWorkerFailure(error)
            }
            releaseThread()
        } catch {
            startup.failed(.init(diagnostic: String(describing: error)))
            releaseThread()
        }
    }
}
