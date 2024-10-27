import Benchmark
import WasmKit
import SystemPackage
import Foundation
import WasmKitWASI

let benchmarks = {
    let macrosDir = FilePath(#filePath)
        .removingLastComponent()
        .removingLastComponent()
        .removingLastComponent()
        .removingLastComponent()
        .pushing("Vendor/swift-stringify-macro.wasm/Sources")

    let handshakeMessage = """
    {
        "getCapability":{
            "capability":{
                "protocolVersion":7
            }
        }
    }
    """
    let expandMessages = [
        "StringifyMacros.wasm": """
        {
           "expandFreestandingMacro":{
              "discriminator":"$s7Example0015mainswift_tzEGbfMX2_6_33_B384B672EB89465DCC67528E23350CF9Ll9stringifyfMf_",
              "lexicalContext":[
                 
              ],
              "macro":{
                 "moduleName":"StringifyMacros",
                 "name":"stringify",
                 "typeName":"StringifyMacro"
              },
              "macroRole":"expression",
              "syntax":{
                 "kind":"expression",
                 "location":{
                    "column":7,
                    "fileID":"Example/main.swift",
                    "fileName":"",
                    "line":3,
                    "offset":24
                 },
                 "source":"#stringify(1 + 1)"
              }
           }
        }
        """,
        "FoundationMacros.wasm": """
        {
           "expandFreestandingMacro":{
              "discriminator":"$s7Example0015mainswift_tzEGbfMX2_6_33_B384B672EB89465DCC67528E23350CF9Ll9stringifyfMf_",
              "lexicalContext":[
                 
              ],
              "macro":{
                 "moduleName":"FoundationMacros",
                 "name":"Expression",
                 "typeName":"ExpressionMacro"
              },
              "macroRole":"expression",
              "syntax":{
                 "kind":"expression",
                 "location":{
                    "column":7,
                    "fileID":"Example/main.swift",
                    "fileName":"",
                    "line":3,
                    "offset":24
                 },
                 "source":"#Expression<Int, Int> { $0 + 1 }"
              }
           }
        }
        """,
        "TestingMacros.wasm": """
        {
           "expandFreestandingMacro":{
              "discriminator":"$s7Example0015mainswift_tzEGbfMX2_6_33_B384B672EB89465DCC67528E23350CF9Ll9stringifyfMf_",
              "lexicalContext":[
                 
              ],
              "macro":{
                 "moduleName":"TestingMacros",
                 "name":"expect",
                 "typeName":"ExpectMacro"
              },
              "macroRole":"expression",
              "syntax":{
                 "kind":"expression",
                 "location":{
                    "column":7,
                    "fileID":"Example/main.swift",
                    "fileName":"",
                    "line":3,
                    "offset":24
                 },
                 "source":"#expect(1 == 2)"
              }
           }
        }
        """,
        "MMIOMacros.wasm": """
        {
          "expandAttachedMacro": {
            "attributeSyntax": {
              "kind": "attribute",
              "location": {
                "column": 12,
                "fileID": "MMIOMacrosExample/main.swift",
                "fileName": "swift-mmio/Sources/MMIOMacrosExample/main.swift",
                "line": 1,
                "offset": 11
              },
              "source": "\n@RegisterBlock "
            },
            "declSyntax": {
              "kind": "declaration",
              "location": {
                "column": 12,
                "fileID": "MMIOMacrosExample/main.swift",
                "fileName": "swift-mmio/Sources/MMIOMacrosExample/main.swift",
                "line": 1,
                "offset": 11
              },
              "source": "\n@RegisterBlock struct Example0 {}"
            },
            "discriminator": "$s17MMIOMacrosExample8Example013RegisterBlockfMm_",
            "lexicalContext": [],
            "macro": {
              "moduleName": "MMIOMacros",
              "name": "RegisterBlock ",
              "typeName": "RegisterBlockMacro"
            },
            "macroRole": "member"
          }
        }
        """
    ]

    for file in try! FileManager.default.contentsOfDirectory(
        atPath: macrosDir.string
    ) {
        guard file.hasSuffix(".wasm") else { continue }

        struct Setup {
            let hostToPlugin: FileDescriptor
            let pluginToHost: FileDescriptor
            let pump: Function
            let expandMessage: String

            init(filePath: FilePath, expandMessage: String) throws {
                let engine = Engine()
                let store = Store(engine: engine)
                let module = try parseWasm(filePath: filePath)

                let hostToPluginPipes = try FileDescriptor.pipe()
                let pluginToHostPipes = try FileDescriptor.pipe()
                let bridge = try WASIBridgeToHost(
                  stdin: hostToPluginPipes.readEnd,
                  stdout: pluginToHostPipes.writeEnd,
                  stderr: .standardError
                )
                var imports = Imports()
                bridge.link(to: &imports, store: store)
                let instance = try module.instantiate(store: store, imports: imports)
                try instance.exports[function: "_start"]!()
                let pump = instance.exports[function: "swift_wasm_macro_v1_pump"]!

                self.hostToPlugin = hostToPluginPipes.writeEnd
                self.pluginToHost = pluginToHostPipes.readEnd
                self.pump = pump
                self.expandMessage = expandMessage
            }

            func writeMessage(_ message: String) throws {
                let bytes = message.utf8
                try withUnsafeBytes(of: UInt64(bytes.count).littleEndian) {
                  _ = try hostToPlugin.writeAll($0)
                }
                try hostToPlugin.writeAll(bytes)
            }
            func readMessage() throws -> [UInt8] {
                let lengthRaw = try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 8) { buffer in
                    let lengthCount = try pluginToHost.read(into: UnsafeMutableRawBufferPointer(buffer))
                    guard lengthCount == 8 else { fatalError() }
                    return buffer.withMemoryRebound(to: UInt64.self, \.baseAddress!.pointee)
                }
                let length = Int(UInt64(littleEndian: lengthRaw))
                return try [UInt8](unsafeUninitializedCapacity: length) { buffer, size in
                    let received = try pluginToHost.read(into: UnsafeMutableRawBufferPointer(buffer))
                    guard received == length else {
                        fatalError()
                    }
                    size = received
                }
            }

            func tick() throws {
                try writeMessage(expandMessage)
                try pump()
                _ = try readMessage()
            }
        }

        guard let expandMessage = expandMessages[file] else {
            fatalError("Expand message definition not found for \(file)")
        }

        Benchmark("Startup \(file)") { benchmark in
            let setup = try Setup(filePath: macrosDir.appending(file), expandMessage: expandMessage)
            try setup.writeMessage(handshakeMessage)
            try setup.tick()
        }

        Benchmark("Expand \(file)") { benchmark, setup in
            try setup.tick()
        } setup: { () -> Setup in
            let setup = try Setup(
                filePath: macrosDir.appending(file),
                expandMessage: expandMessage
            )
            try setup.writeMessage(handshakeMessage)

            // Warmup
            try setup.tick()

            return setup
        }
    }
}
