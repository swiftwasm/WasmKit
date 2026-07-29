import WasmKit

// (module
//   (import "host" "mul" (func $mul (param i32 i32) (result i32)))
//   (import "host" "boom" (func $boom))
//   (func (export "add") (param i32 i32) (result i32)
//     local.get 0
//     local.get 1
//     i32.add)
//   (func (export "mul3") (param i32) (result i32)
//     local.get 0
//     i32.const 3
//     call $mul)
//   (func (export "callBoom")
//     call $boom))
let demoWasm: [UInt8] = [
    0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00, 0x01, 0x0F, 0x03, 0x60,
    0x02, 0x7F, 0x7F, 0x01, 0x7F, 0x60, 0x00, 0x00, 0x60, 0x01, 0x7F, 0x01,
    0x7F, 0x02, 0x18, 0x02, 0x04, 0x68, 0x6F, 0x73, 0x74, 0x03, 0x6D, 0x75,
    0x6C, 0x00, 0x00, 0x04, 0x68, 0x6F, 0x73, 0x74, 0x04, 0x62, 0x6F, 0x6F,
    0x6D, 0x00, 0x01, 0x03, 0x04, 0x03, 0x00, 0x02, 0x01, 0x07, 0x19, 0x03,
    0x03, 0x61, 0x64, 0x64, 0x00, 0x02, 0x04, 0x6D, 0x75, 0x6C, 0x33, 0x00,
    0x03, 0x08, 0x63, 0x61, 0x6C, 0x6C, 0x42, 0x6F, 0x6F, 0x6D, 0x00, 0x04,
    0x0A, 0x17, 0x03, 0x07, 0x00, 0x20, 0x00, 0x20, 0x01, 0x6A, 0x0B, 0x08,
    0x00, 0x20, 0x00, 0x41, 0x03, 0x10, 0x00, 0x0B, 0x04, 0x00, 0x10, 0x01,
    0x0B,
]

/// An engine-unknown error type thrown by a host function; WasmKit must
/// rethrow it with its identity intact.
struct DemoHostError: Error {
    let code: UInt32
}

@_cdecl("app_main")
func app_main() {
    print("WasmKit on ESP32-C6")
    do {
        let module = try parseWasm(bytes: demoWasm)
        // The default 512 KiB VM stack does not fit in on-chip SRAM.
        var configuration = EngineConfiguration()
        configuration.stackSize = 64 * 1024
        let engine = Engine(configuration: configuration)
        let store = Store(engine: engine)

        var imports = Imports()
        imports.define(
            module: "host", name: "mul",
            Function(store: store, parameters: [.i32, .i32], results: [.i32]) { _, arguments in
                [.i32(arguments[0].i32 &* arguments[1].i32)]
            })
        imports.define(
            module: "host", name: "boom",
            Function(store: store, parameters: []) { _, _ in
                throw DemoHostError(code: 42)
            })

        let instance = try module.instantiate(store: store, imports: imports)

        guard let add = instance.exports[function: "add"],
            let mul3 = instance.exports[function: "mul3"],
            let callBoom = instance.exports[function: "callBoom"]
        else {
            print("missing export")
            return
        }

        if case .i32(let value) = try add([.i32(2), .i32(3)])[0] {
            print("2 + 3 = \(value)")
        }
        // Guest -> host call.
        if case .i32(let value) = try mul3([.i32(7)])[0] {
            print("7 * 3 = \(value)")
        }
        // Host error identity round-trips through the interpreter.
        do {
            _ = try callBoom()
        } catch let error as DemoHostError {
            print("host error \(error.code)")
        }
    } catch {
        print("wasm error")
    }
}
