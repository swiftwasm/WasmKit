import Foundation
import Logging
import SwiftCLI
import WAKit

private let logger = Logger(label: "com.WAKit.CLI")

final class RunCommand: Command {
    let name = "run"

    let isVerbose = Flag("-v")
    let path = Parameter()
    let functionName = Parameter()
    let arguments = OptionalCollectedParameter()

    func execute() throws {
        let isVerbose = self.isVerbose.value

        LoggingSystem.bootstrap {
            var handler = StreamLogHandler.standardOutput(label: $0)
            handler.logLevel = isVerbose ? .info : .warning
            return handler
        }

        let path = self.path.value
        let functionName = self.functionName.value

        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            logger.error("File \"\(path)\" could not be opened")
            return
        }
        defer { fileHandle.closeFile() }

        let stream = FileHandleStream(fileHandle: fileHandle)

        logger.info("Started to parse module")

        let (module, parseTime) = try measure(if: isVerbose) {
            try WasmParser.parse(stream: stream)
        }

        logger.info("Ended to parse module: \(parseTime)")

        let runtime = Runtime()
        let moduleInstance = try runtime.instantiate(module: module, externalValues: [])

        var parameters: [Value] = []
        for argument in arguments.value {
            let parameter: Value
            let type = argument.prefix { $0 != ":" }
            let value = argument.drop { $0 != ":" }.dropFirst()
            switch type {
            case "i32": parameter = I32(Int32(value)!)
            case "i64": parameter = I64(Int64(value)!)
            case "f32": parameter = F32(Float(value)!)
            case "f64": parameter = F64(Double(value)!)
            default: fatalError("unknown type")
            }
            parameters.append(parameter)
        }

        logger.info("Started invoking function \"\(functionName)\" with parameters: \(parameters)")

        let (results, invokeTime) = try measure(if: isVerbose) {
            try runtime.invoke(moduleInstance, function: functionName, with: parameters)
        }

        logger.info("Ended invoking function \"\(functionName)\": \(invokeTime)")

        stdout <<< results.description
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
