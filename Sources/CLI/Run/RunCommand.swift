import Foundation
import SwiftCLI
import WAKit
import Willow

final class RunCommand: Command {
    let name = "run"

    let isVerbose = Flag("-v")
    let path = Parameter()
    let functionName = Parameter()
    let arguments = OptionalCollectedParameter()

    lazy var logger: Logger = {
        Logger(
            logLevels: isVerbose.value ? [.error, .warn, .event, .info] : [.error, .warn],
            writers: [ConsoleWriter()]
        )
    }()

    func execute() throws {
        let isVerbose = self.isVerbose.value
        let path = self.path.value
        let functionName = self.functionName.value

        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            logger.errorMessage("File \"\(path)\" could not be opened")
            return
        }
        defer { fileHandle.closeFile() }

        let stream = FileHandleStream(fileHandle: fileHandle)

        logger.eventMessage("Started to parse module")

        let (module, parseTime) = try measure(if: isVerbose) {
            try WASMParser.parse(stream: stream)
        }

        logger.eventMessage("Ended to parse module: \(parseTime)")

        let runtime = Runtime()
        let moduleInstance = try runtime.instantiate(module: module, externalValues: [])

        guard case let .function(address)? = moduleInstance.exports[functionName] else {
            logger.errorMessage("Function with name \"\(functionName)\" not found")
            dump(moduleInstance.exports)
            return
        }

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

        logger.eventMessage("Started invoking function \"\(functionName)\" with parameters: \(parameters)")

        let (results, invokeTime) = try measure(if: isVerbose) {
            try runtime.invoke(functionAddress: address, with: parameters)
        }

        logger.infoMessage("Ended invoking function \"\(functionName)\": \(invokeTime)")

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
