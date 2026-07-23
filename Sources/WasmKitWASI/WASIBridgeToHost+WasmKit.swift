import WASI
import WasmKit

public typealias WASIBridgeToHost = WASI.WASIBridgeToHost
public typealias MemoryFileSystem = WASI.MemoryFileSystem

extension WASIBridgeToHost {

    /// Register the WASI implementation to the given `imports`.
    ///
    /// - Parameters:
    ///   - imports: The imports scope to register the WASI implementation.
    ///   - store: The store to create the host functions.
    public func link(to imports: inout Imports, store: Store) {
        for (moduleName, module) in wasiHostModules {
            for (name, function) in module.functions {
                imports.define(
                    module: moduleName,
                    name: name,
                    Function(store: store, type: function.type, body: makeHostFunction(function))
                )
            }
        }
    }

    @available(*, deprecated, renamed: "link(to:store:)", message: "Use `Engine`-based API instead")
    public var hostModules: [String: HostModule] {
        wasiHostModules.mapValues { (module: WASIHostModule) -> HostModule in
            HostModule(
                functions: module.functions.mapValues { function -> HostFunction in
                    HostFunction(type: function.type, implementation: makeHostFunction(function))
                })
        }
    }

    private func makeHostFunction(_ function: WASIHostFunction) -> Function.Implementation {
        { caller, values -> [Value] in
            guard case .memory(let memory) = caller.instance?.export("memory") else {
                throw WASIError(description: "Missing required \"memory\" export")
            }
            return try function.implementation(memory, values)
        }
    }

    // MARK: - wasi-threads support

    #if os(macOS) || os(Linux)
        /// Set up wasi-threads support for a module.
        ///
        /// Pre-allocates shared memories, creates a ``ThreadGroup``, and registers
        /// `thread-spawn` in the `"wasi"` namespace. Call ``link(to:store:)`` first
        /// to register `wasi_snapshot_preview1` functions.
        ///
        /// - Returns: A ``ThreadGroup`` for tracking spawned threads. The caller
        ///   must call ``ThreadGroup/joinAllThreads()`` after execution completes.
        package func linkThreads(
            to imports: inout Imports,
            store: Store,
            module: Module
        ) throws -> ThreadGroup {
            var sharedMemories: [SharedMemoryStorage?] = []
            for importEntry in module.imports {
                guard case .memory(let memoryType) = importEntry.descriptor else { continue }
                if memoryType.shared {
                    let memory = try Memory(store: store, type: memoryType)
                    imports.define(module: importEntry.module, name: importEntry.name, memory)
                    sharedMemories.append(memory.sharedStorage!)
                } else {
                    sharedMemories.append(nil)
                }
            }

            let threadGroup = ThreadGroup(
                module: module,
                engineConfiguration: store.engine.configuration,
                funcTypeInterner: store.engine.funcTypeInterner,
                sharedMemories: sharedMemories
            )

            // The parent Store participates in the same termination domain as
            // children: a trap or proc_exit in any thread terminates the parent too.
            store.terminationFlag = threadGroup.terminationFlag

            registerThreadSpawn(to: &imports, store: store, threadGroup: threadGroup)
            return threadGroup
        }

        private func registerThreadSpawn(
            to imports: inout Imports,
            store: Store,
            threadGroup: ThreadGroup
        ) {
            let type = FunctionType(parameters: [.i32], results: [.i32])
            imports.define(
                module: "wasi", name: "thread-spawn",
                Function(store: store, type: type) { [self] caller, args in
                    let startArg = Int32(bitPattern: args[0].i32)
                    let result = self.spawnThread(threadGroup: threadGroup, startArg: startArg)
                    return [.i32(UInt32(bitPattern: result))]
                }
            )
        }

        private func buildChildImports(
            store: Store,
            threadGroup: ThreadGroup
        ) -> Imports {
            var imports = Imports()
            link(to: &imports, store: store)

            var memoryIndex = 0
            for importEntry in threadGroup.module.imports {
                guard case .memory(let memoryType) = importEntry.descriptor else { continue }
                if memoryType.shared,
                    memoryIndex < threadGroup.sharedMemories.count,
                    let shared = threadGroup.sharedMemories[memoryIndex]
                {
                    let memory = Memory(store: store, type: memoryType, sharedStorage: shared)
                    imports.define(module: importEntry.module, name: importEntry.name, memory)
                }
                memoryIndex += 1
            }

            registerThreadSpawn(to: &imports, store: store, threadGroup: threadGroup)
            return imports
        }

        private func spawnThread(
            threadGroup: ThreadGroup,
            startArg: Int32
        ) -> Int32 {
            let tid = threadGroup.allocateTID()

            let thread: PlatformThread
            do {
                thread = try PlatformThread.spawn(stackSize: 0) { [self, threadGroup] in
                    do {
                        let childEngine = threadGroup.makeChildEngine()
                        let childStore = Store(engine: childEngine)
                        childStore.terminationFlag = threadGroup.terminationFlag
                        let childImports = self.buildChildImports(
                            store: childStore, threadGroup: threadGroup
                        )
                        let childInstance = try threadGroup.module.instantiateForThread(
                            store: childStore,
                            threadGroup: threadGroup,
                            imports: childImports
                        )

                        guard let threadStart = childInstance.exports[function: "wasi_thread_start"] else {
                            threadGroup.signalTrap()
                            return
                        }

                        _ = try threadStart.invoke([
                            .i32(UInt32(bitPattern: tid)),
                            .i32(UInt32(bitPattern: startArg)),
                        ])
                    } catch let exitCode as WASIExitCode {
                        threadGroup.signalExit(code: Int32(bitPattern: exitCode.code))
                    } catch is Trap {
                        threadGroup.signalTrap()
                    } catch {
                        threadGroup.signalTrap()
                    }
                }
            } catch {
                return -1
            }

            threadGroup.registerThread(thread)
            return tid
        }
    #endif

    // MARK: - Application ABI

    /// Start a WASI application as a `command` instance.
    ///
    /// See <https://github.com/WebAssembly/WASI/blob/main/legacy/application-abi.md>
    /// for more information about the WASI Preview 1 Application ABI.
    ///
    /// - Parameter instance: The WASI application instance.
    /// - Returns: The exit code returned by the WASI application.
    public func start(_ instance: Instance) throws -> UInt32 {
        do {
            guard let start = instance.exports[function: "_start"] else {
                throw WASIError(description: "Missing required \"_start\" function")
            }
            _ = try start()
        } catch let code as WASIExitCode {
            return code.code
        }
        return 0
    }

    /// Start a WASI application as a `reactor` instance.
    ///
    /// See <https://github.com/WebAssembly/WASI/blob/main/legacy/application-abi.md>
    /// for more information about the WASI Preview 1 Application ABI.
    ///
    /// - Parameter instance: The WASI application instance.
    public func initialize(_ instance: Instance) throws {
        if let initialize = instance.exports[function: "_initialize"] {
            // Call the optional `_initialize` function.
            _ = try initialize()
        }
    }

    @available(*, deprecated, message: "Use `Engine`-based API instead")
    public func start(_ instance: Instance, runtime: Runtime) throws -> UInt32 {
        return try start(instance)
    }
}
