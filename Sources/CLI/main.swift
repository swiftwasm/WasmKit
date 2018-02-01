import Parser
import WAKit
import Foundation

let iterations: Double = 100
var parseTimes = [Double]()
var instantiationTimes = [Double]()
var executionTimes = [Double]()

let rootURL = URL(fileURLWithPath: #file)
let testURL = rootURL.appendingPathComponent("../../../Fixtures/test.wasm").standardizedFileURL
let bytes = Array(try Foundation.Data(contentsOf: testURL))

for _ in 0 ..< Int(iterations) {
    let startDate = Date()

    let stream = StaticByteStream(bytes: bytes)
    let parser = WASMParser(stream: stream)
    let module = try parser.parseModule()

    let parseEnd = Date()

    let runtime = Runtime()
    try runtime.instantiate(module: module, externalValues: [])

    let instantiationEnd = Date()

    let result = try runtime.invoke(function: 0, arguments: [])

    let executionEnd = Date()

    print(result)

    parseTimes.append(parseEnd.timeIntervalSince(startDate) * 1000)
    instantiationTimes.append(instantiationEnd.timeIntervalSince(parseEnd) * 1000)
    executionTimes.append(executionEnd.timeIntervalSince(instantiationEnd) * 1000)
}

print("parse: \n", parseTimes.reduce(0, +) / iterations)
print("instantiation: \n", instantiationTimes.reduce(0, +) / iterations)
print("exection: \n", executionTimes.reduce(0, +) / iterations)
