import ArgumentParser
import SystemPackage
import WasmKit
import WasmKitWASI
#if canImport(os.signpost)
import os.signpost
#endif

struct Run: ParsableCommand {
    @Flag
    var verbose = false

    @Option(
        name: .customLong("profile"),
        help: ArgumentHelp(
            "Output a profile of the execution to the given file in Google's Trace Event Format",
            valueName: "path"
        )
    )
    var profileOutput: String?

    @Flag(
        inversion: .prefixedEnableDisable,
        help: "Enable or disable Signpost logging (macOS only)"
    )
    var signpost: Bool = false

    struct EnvOption: ExpressibleByArgument {
        let key: String
        let value: String
        init?(argument: String) {
            var parts = argument.split(separator: "=", maxSplits: 2).makeIterator()
            guard let key = parts.next(), let value = parts.next() else { return nil }
            self.key = String(key)
            self.value = String(value)
        }
    }

    @Option(
        name: .customLong("env"),
        help: ArgumentHelp(
            "Pass an environment variable to the WASI program",
            valueName: "key=value"
        ))
    var environment: [EnvOption] = []

    @Option(name: .customLong("dir"), help: "Grant access to the given host directory")
    var directories: [String] = []

    enum ThreadingModel: String, ExpressibleByArgument {
        case direct
        case token
    }

    @Option(help: ArgumentHelp("The execution threading model to use", visibility: .hidden))
    var threadingModel: ThreadingModel?

    @Argument
    var path: String

    @Argument
    var arguments: [String] = []

    func run() throws {
        log("Started parsing module", verbose: true)

        let module: Module
        if verbose, #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            let (parsedModule, parseTime) = try measure {
                try parseWasm(filePath: FilePath(path))
            }
            log("Finished parsing module: \(parseTime)", verbose: true)
            module = parsedModule
        } else {
            module = try parseWasm(filePath: FilePath(path))
        }

        let (interceptor, finalize) = try deriveInterceptor()
        defer { finalize() }

        let invoke: () throws -> Void
        if module.exports.contains(where: { $0.name == "_start" }) {
            invoke = try instantiateWASI(module: module, interceptor: interceptor)
        } else {
            guard let entry = try instantiateNonWASI(module: module, interceptor: interceptor) else {
                return
            }
            invoke = entry
        }

        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            let (_, invokeTime) = try measure(execution: invoke)
            log("Finished invoking function \"\(path)\": \(invokeTime)", verbose: true)
        } else {
            try invoke()
        }
    }

    /// Derives the runtime interceptor based on the command line arguments
    func deriveInterceptor() throws -> (interceptor: RuntimeInterceptor?, finalize: () -> Void) {
        var interceptors: [RuntimeInterceptor] = []
        var finalizers: [() -> Void] = []

        if self.signpost {
            if let signpostTracer = deriveSignpostTracer() {
                interceptors.append(signpostTracer)
            }
        }
        if let outputPath = self.profileOutput {
            let fileHandle = try FileDescriptor.open(
                FilePath(outputPath), .writeOnly, options: .create,
                permissions: [.ownerReadWrite, .groupRead, .otherRead]
            )
            let profiler = GuestTimeProfiler { data in
                var data = data
                _ = data.withUTF8 { try! fileHandle.writeAll($0) }
            }
            interceptors.append(profiler)
            finalizers.append {
                profiler.finalize()
                try! fileHandle.close()
                print("\nProfile Completed: \(outputPath) can be viewed using https://ui.perfetto.dev/")
            }
        }
        // If no interceptors are present, return nil explicitly
        // Empty multiplexing interceptor enables runtime tracing but does not
        // do anything other than adding runtime overhead
        if interceptors.isEmpty {
            return (nil, {})
        }
        return (MultiplexingInterceptor(interceptors), { finalizers.forEach { $0() } })
    }

    private func deriveSignpostTracer() -> RuntimeInterceptor? {
        #if canImport(os.signpost)
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            let signposter = SignpostTracer(signposter: OSSignposter())
            return signposter
        }
        #endif
        log("warning: Signpost logging is not supported on this platform. Ignoring --enable-signpost")
        return nil
    }

    private func deriveRuntimeConfiguration() -> RuntimeConfiguration {
        let threadingModel: RuntimeConfiguration.ThreadingModel?
        switch self.threadingModel {
        case .direct: threadingModel = .direct
        case .token: threadingModel = .token
        case nil: threadingModel = nil
        }
        return RuntimeConfiguration(threadingModel: threadingModel)
    }

    func instantiateWASI(module: Module, interceptor: RuntimeInterceptor?) throws -> () throws -> Void {
        // Flatten environment variables into a dictionary (Respect the last value if a key is duplicated)
        let environment = environment.reduce(into: [String: String]()) {
            $0[$1.key] = $1.value
        }
        let preopens = directories.reduce(into: [String: String]()) {
            $0[$1] = $1
        }
        let wasi = try WASIBridgeToHost(args: [path] + arguments, environment: environment, preopens: preopens)
        let runtime = Runtime(hostModules: wasi.hostModules, interceptor: interceptor, configuration: deriveRuntimeConfiguration())
        let moduleInstance = try runtime.instantiate(module: module)
        return {
            let exitCode = try wasi.start(moduleInstance, runtime: runtime)
            throw ExitCode(Int32(exitCode))
        }
    }

    func instantiateNonWASI(module: Module, interceptor: RuntimeInterceptor?) throws -> (() throws -> Void)? {
        let functionName = arguments.first
        let arguments = arguments.dropFirst()

        var parameters: [Value] = []
        for argument in arguments {
            let parameter: Value
            let type = argument.prefix { $0 != ":" }
            let value = argument.drop { $0 != ":" }.dropFirst()
            switch type {
            case "i32": parameter = Value(signed: Int32(value)!)
            case "i64": parameter = Value(signed: Int64(value)!)
            case "f32": parameter = .f32(Float32(value)!.bitPattern)
            case "f64": parameter = .f64(Float64(value)!.bitPattern)
            default: fatalError("unknown type")
            }
            parameters.append(parameter)
        }
        guard let functionName else {
            log("Error: No function specified to run in a given module.")
            return nil
        }

        let runtime = Runtime(interceptor: interceptor, configuration: deriveRuntimeConfiguration())
        let moduleInstance = try runtime.instantiate(module: module)
        return {
            log("Started invoking function \"\(functionName)\" with parameters: \(parameters)", verbose: true)
            let results = try runtime.invoke(moduleInstance, function: functionName, with: parameters)
            print(results.description)
        }
    }

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    func measure<Result>(
        execution: () throws -> Result
    ) rethrows -> (Result, String) {
        var result: Result!
        let formattedTime = try ContinuousClock().measure {
            result = try execution()
        }

        return (result, formattedTime.description)
    }

    @Sendable func log(_ message: String, verbose: Bool = false) {
        if !verbose || self.verbose {
            try! FileDescriptor.standardError.writeAll((message + "\n").utf8)
        }
    }
}
