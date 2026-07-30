import Benchmark
import WasmKit
import Foundation
import WasmKitWASI

let benchmarks: @Sendable () -> () = {
    let macrosDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Vendor/swift-stringify-macro.wasm/Sources")

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
        atPath: macrosDir.path
    ) {
        guard file.hasSuffix(".wasm") else { continue }

        struct Setup {
            let hostToPlugin: FileHandle
            let pluginToHost: FileHandle
            /// The guest-side pipe ends, retained so their descriptors stay
            /// open: a `FileHandle` closes its descriptor when deallocated.
            let guestStdin: FileHandle
            let guestStdout: FileHandle
            let pump: Function
            let expandMessage: String
            let bridge: WASIBridgeToHost

            init(filePath: String, expandMessage: String) throws {
                let engine = Engine()
                let store = Store(engine: engine)
                let module = try parseWasm(filePath: filePath)

                let hostToPluginPipes = Pipe()
                let pluginToHostPipes = Pipe()
                let bridge = try WASIBridgeToHost(
                  stdin: hostToPluginPipes.fileHandleForReading.fileDescriptor,
                  stdout: pluginToHostPipes.fileHandleForWriting.fileDescriptor,
                  stderr: 2
                )
                do {
                    var imports = Imports()
                    bridge.link(to: &imports, store: store)
                    let instance = try module.instantiate(store: store, imports: imports)
                    try instance.exports[function: "_start"]!()
                    let pump = instance.exports[function: "swift_wasm_macro_v1_pump"]!

                    self.hostToPlugin = hostToPluginPipes.fileHandleForWriting
                    self.pluginToHost = pluginToHostPipes.fileHandleForReading
                    self.guestStdin = hostToPluginPipes.fileHandleForReading
                    self.guestStdout = pluginToHostPipes.fileHandleForWriting
                    self.pump = pump
                    self.expandMessage = expandMessage
                    self.bridge = bridge
                } catch {
                    try bridge.close()
                    throw error
                }
            }

            func writeMessage(_ message: String) throws {
                let bytes = Data(message.utf8)
                try withUnsafeBytes(of: UInt64(bytes.count).littleEndian) {
                  try hostToPlugin.write(contentsOf: Data($0))
                }
                try hostToPlugin.write(contentsOf: bytes)
            }
            func readMessage() throws -> [UInt8] {
                guard let lengthData = try pluginToHost.read(upToCount: 8), lengthData.count == 8 else {
                    fatalError()
                }
                let lengthRaw = lengthData.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }
                let length = Int(UInt64(littleEndian: lengthRaw))
                guard let message = try pluginToHost.read(upToCount: length), message.count == length else {
                    fatalError()
                }
                return [UInt8](message)
            }

            func tick() throws {
                try writeMessage(expandMessage)
                try pump()
                _ = try readMessage()
            }

            func close() throws {
                try bridge.close()
            }
        }

        guard let expandMessage = expandMessages[file] else {
            fatalError("Expand message definition not found for \(file)")
        }

        Benchmark("Startup \(file)") { benchmark in
            let setup = try Setup(filePath: macrosDir.appendingPathComponent(file).path, expandMessage: expandMessage)
            try setup.writeMessage(handshakeMessage)
            try setup.tick()
            try setup.close()
        }

        Benchmark("Expand \(file)") { benchmark, setup in
            try setup.tick()
            try setup.close()
        } setup: { () -> Setup in
            let setup = try Setup(
                filePath: macrosDir.appendingPathComponent(file).path,
                expandMessage: expandMessage
            )
            try setup.writeMessage(handshakeMessage)

            // Warmup
            try setup.tick()

            return setup
        }
    }
}
