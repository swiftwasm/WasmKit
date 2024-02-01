import ArgumentParser
import Foundation
import SystemPackage
import WASI
import WasmKit

struct Run: ParsableCommand {
    @Flag
    var verbose = false

    @Option
    var profileOutput: String?

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

    @Argument
    var path: String

    @Argument
    var arguments: [String] = []

    func run() throws {
        log("Started parsing module", verbose: true)

        let module: Module
        if verbose {
            let (parsedModule, parseTime) = try measure {
                try parseWasm(filePath: FilePath(path))
            }
            log("Finished parsing module: \(parseTime)", verbose: true)
            module = parsedModule
        } else {
            module = try parseWasm(filePath: FilePath(path))
        }

        let interceptor = try deriveInterceptor()
        #if !DEBUG
        guard interceptor == nil else {
            fatalError("Internal Error: Interceptor API is unavailable with Release build due to performance reasons")
        }
        #endif
        defer { interceptor?.finalize() }

        let invoke: () throws -> Void
        if module.exports.contains(where: { $0.name == "_start" }) {
            invoke = try instantiateWASI(module: module, interceptor: interceptor?.interceptor)
        } else {
            guard let entry = try instantiateNonWASI(module: module, interceptor: interceptor?.interceptor) else {
                return
            }
            invoke = entry
        }

        let (_, invokeTime) = try measure(execution: invoke)

        log("Finished invoking function \"\(path)\": \(invokeTime)", verbose: true)
    }

    func deriveInterceptor() throws -> (interceptor: GuestTimeProfiler, finalize: () -> Void)? {
        guard let outputPath = self.profileOutput else { return nil }
        FileManager.default.createFile(atPath: outputPath, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputPath))
        let profiler = GuestTimeProfiler { data in
            try? fileHandle.write(contentsOf: data)
        }
        return (
            profiler,
            {
                profiler.finalize()
                try! fileHandle.synchronize()
                try! fileHandle.close()

                print("\nProfile Completed: \(outputPath) can be viewed using https://ui.perfetto.dev/")
            }
        )
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
        let runtime = Runtime(hostModules: wasi.hostModules, interceptor: interceptor)
        let moduleInstance = try runtime.instantiate(module: module)
        return {
            let exitCode = try wasi.start(moduleInstance, runtime: runtime)
            throw ExitCode(Int32(exitCode))
        }
    }

    func instantiateNonWASI(module: Module, interceptor: RuntimeInterceptor?) throws -> (() throws -> Void)? {
        var arguments = arguments
        let functionName = arguments.popLast()

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

        let runtime = Runtime(interceptor: interceptor)
        let moduleInstance = try runtime.instantiate(module: module)
        return {
            log("Started invoking function \"\(functionName)\" with parameters: \(parameters)", verbose: true)
            let results = try runtime.invoke(moduleInstance, function: functionName, with: parameters)
            print(results.description)
        }
    }

    func measure<Result>(
        execution: () throws -> Result
    ) rethrows -> (Result, String) {
        let start = DispatchTime.now()
        let result = try execution()
        let end = DispatchTime.now()

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let nanoseconds = NSNumber(value: end.uptimeNanoseconds - start.uptimeNanoseconds)
        let formattedTime = numberFormatter.string(from: nanoseconds)! + " ns"
        return (result, formattedTime)
    }

    @Sendable func log(_ message: String, verbose: Bool = false) {
        if !verbose || self.verbose {
            fputs(message + "\n", stderr)
        }
    }
}
