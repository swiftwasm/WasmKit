/// This example demonstrates how to pass a UTF-8 string between the host and a WebAssembly module.

import Foundation
import WasmKit
import WAT

@main
struct Example {
    static func main() throws {
        let examplesDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // StringPassing
            .deletingLastPathComponent() // Sources
            .deletingLastPathComponent() // Examples
        let watURL = examplesDirectory.appendingPathComponent("wasm/string_passing.wat")

        let module = try parseWasm(
            bytes: try wat2wasm(String(contentsOf: watURL))
        )

        let engine = Engine()
        let store = Store(engine: engine)

        let instance = try module.instantiate(
            store: store,
            imports: [
                "printer": [
                    "print_str": Function(store: store, parameters: [.i32, .i32]) { caller, args in
                        let stringPtr = Int(args[0].i32)
                        let stringLength = Int(args[1].i32)
                        guard let memory = caller.instance?.exports[memory: "memory"] else {
                            fatalError("Missing \"memory\" export")
                        }
                        let string = memory.withUnsafeMutableBufferPointer(
                            offset: UInt(stringPtr),
                            count: stringLength
                        ) { buffer in
                            String(decoding: buffer.bindMemory(to: UInt8.self), as: UTF8.self)
                        }
                        print(string, terminator: "")
                        return []
                    }
                ]
            ]
        )

        // WebAssembly -> host: print a static string from the module's linear memory.
        try instance.exports[function: "print_hello"]!()

        // Host -> WebAssembly: allocate space in the module's linear memory and write a string.
        let message = "Hello from host!\n"
        let messageBytes = Array(message.utf8)
        let alloc = instance.exports[function: "alloc"]!
        let ptr = Int(try alloc([Value(signed: Int32(messageBytes.count))])[0].i32)

        let memory = instance.exports[memory: "memory"]!
        memory.withUnsafeMutableBufferPointer(offset: UInt(ptr), count: messageBytes.count) { buffer in
            messageBytes.withUnsafeBytes { src in
                buffer.baseAddress!.copyMemory(from: src.baseAddress!, byteCount: src.count)
            }
        }

        // Let WebAssembly compute a simple checksum over the bytes we wrote.
        let checksum = instance.exports[function: "checksum"]!
        let sum = try checksum([
            Value(signed: Int32(ptr)),
            Value(signed: Int32(messageBytes.count))
        ])[0].i32
        print("checksum(messageBytes) = \(sum)")
    }
}
