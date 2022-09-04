import ArgumentParser
import Foundation
import Logging
import WAKit

private let logger = Logger(label: "com.WAKit.CLI")

struct Run: ParsableCommand {
    @Flag
    var verbose = false

    @Argument
    var path: String

    @Argument
    var functionName: String

    @Argument
    var arguments: [String]

    func run() throws {
        LoggingSystem.bootstrap {
            var handler = StreamLogHandler.standardOutput(label: $0)
            handler.logLevel = verbose ? .info : .warning
            return handler
        }

        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            logger.error("File \"\(path)\" could not be opened")
            return
        }
        defer { fileHandle.closeFile() }

        let stream = FileHandleStream(fileHandle: fileHandle)

        logger.info("Started to parse module")

        let (module, parseTime) = try measure(if: verbose) {
            try WasmParser.parse(stream: stream)
        }

        logger.info("Ended to parse module: \(parseTime)")

        let runtime = Runtime()
        let moduleInstance = try runtime.instantiate(module: module, externalValues: [])

        var parameters: [Value] = []
        for argument in arguments {
            let parameter: Value
            let type = argument.prefix { $0 != ":" }
            let value = argument.drop { $0 != ":" }.dropFirst()
            switch type {
            case "i32": parameter = Value(signed: Int32(value)!)
            case "i64": parameter = Value(signed: Int64(value)!)
            case "f32": parameter = .f32(Float(value)!)
            case "f64": parameter = .f64(Double(value)!)
            default: fatalError("unknown type")
            }
            parameters.append(parameter)
        }

        logger.info("Started invoking function \"\(functionName)\" with parameters: \(parameters)")

        let (results, invokeTime) = try measure(if: verbose) {
            try runtime.invoke(moduleInstance, function: functionName, with: parameters)
        }

        logger.info("Ended invoking function \"\(functionName)\": \(invokeTime)")

        print(results.description)
    }

    func measure<Result>(
        if _: @autoclosure () -> Bool,
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
}
