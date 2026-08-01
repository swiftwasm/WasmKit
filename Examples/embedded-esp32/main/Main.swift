@_spi(WASIPlatform) import WASI
import GDBRemoteProtocol
import WasmKitGDBHandler
import WasmKit
import WasmKitWASI

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


/// The WASI guest: writes a string to fd 1 via `fd_write`.
///
/// (module
///   (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
///   (memory (export "memory") 1)
///   (data (i32.const 64) "WASI guest says hello\n")
///   (func (export "_start") ... ))
let wasiGuestWasm: [UInt8] = [
    0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00, 0x01, 0x0C, 0x02, 0x60,
    0x04, 0x7F, 0x7F, 0x7F, 0x7F, 0x01, 0x7F, 0x60, 0x00, 0x00, 0x02, 0x23,
    0x01, 0x16, 0x77, 0x61, 0x73, 0x69, 0x5F, 0x73, 0x6E, 0x61, 0x70, 0x73,
    0x68, 0x6F, 0x74, 0x5F, 0x70, 0x72, 0x65, 0x76, 0x69, 0x65, 0x77, 0x31,
    0x08, 0x66, 0x64, 0x5F, 0x77, 0x72, 0x69, 0x74, 0x65, 0x00, 0x00, 0x03,
    0x02, 0x01, 0x01, 0x05, 0x03, 0x01, 0x00, 0x01, 0x07, 0x13, 0x02, 0x06,
    0x6D, 0x65, 0x6D, 0x6F, 0x72, 0x79, 0x02, 0x00, 0x06, 0x5F, 0x73, 0x74,
    0x61, 0x72, 0x74, 0x00, 0x01, 0x0A, 0x1E, 0x01, 0x1C, 0x00, 0x41, 0x00,
    0x41, 0xC0, 0x00, 0x36, 0x02, 0x00, 0x41, 0x04, 0x41, 0x16, 0x36, 0x02,
    0x00, 0x41, 0x01, 0x41, 0x00, 0x41, 0x01, 0x41, 0x08, 0x10, 0x00, 0x1A,
    0x0B, 0x0B, 0x1D, 0x01, 0x00, 0x41, 0xC0, 0x00, 0x0B, 0x16, 0x57, 0x41,
    0x53, 0x49, 0x20, 0x67, 0x75, 0x65, 0x73, 0x74, 0x20, 0x73, 0x61, 0x79,
    0x73, 0x20, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x0A, 0x00, 0x12, 0x04, 0x6E,
    0x61, 0x6D, 0x65, 0x01, 0x0B, 0x01, 0x00, 0x08, 0x66, 0x64, 0x5F, 0x77,
    0x72, 0x69, 0x74, 0x65,
]

/// Routes a WASI stream onto the ESP-IDF console.
///
/// Bare-metal targets have no host file descriptors, so stdio is injected as a
/// `WASIFile` instead. This is the seam an embedded consumer uses to point WASI
/// at a UART.
struct ConsoleFile: WASIFile {
    var isBorrowed: Bool { true }

    func attributes() throws -> WASIAbi.Filestat {
        WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .CHARACTER_DEVICE,
            nlink: 0, size: 0, atim: 0, mtim: 0, ctim: 0)
    }
    func fileType() throws -> WASIAbi.FileType { .CHARACTER_DEVICE }
    func status() throws -> WASIAbi.Fdflags { [] }
    func setTimes(atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp, fstFlags: WASIAbi.FstFlags) throws {}
    func advise(offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice) throws {}
    func close() throws {}

    func fdStat() throws -> WASIAbi.FdStat {
        WASIAbi.FdStat(
            fsFileType: .CHARACTER_DEVICE, fsFlags: [],
            fsRightsBase: [.FD_WRITE], fsRightsInheriting: [])
    }
    func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws {}
    func setFilestatSize(_ size: WASIAbi.FileSize) throws {}
    func sync() throws {}
    func datasync() throws {}
    func tell() throws -> WASIAbi.FileSize { 0 }
    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
        throw WASIAbi.Errno.ESPIPE
    }

    func write(vectored buffers: GuestBuffers) throws -> WASIAbi.Size {
        var total: WASIAbi.Size = 0
        for index in 0..<buffers.count {
            try buffers.withHostBuffer(at: index) { bytes in
                var line = ""
                for byte in bytes.bindMemory(to: UInt8.self) where byte != 0x0A {
                    line.append(Character(UnicodeScalar(byte)))
                }
                print(line)
                total += WASIAbi.Size(bytes.count)
                return bytes.count
            }
        }
        return total
    }
    func pwrite(vectored buffers: GuestBuffers, offset: WASIAbi.FileSize) throws -> WASIAbi.Size {
        throw WASIAbi.Errno.ESPIPE
    }
    func read(into buffers: GuestBuffers) throws -> WASIAbi.Size { 0 }
    func pread(into buffers: GuestBuffers, offset: WASIAbi.FileSize) throws -> WASIAbi.Size {
        throw WASIAbi.Errno.ESPIPE
    }
}

/// Runs the WASI guest, linking only the capabilities it needs.
///
/// Set WASMKIT_LINK_ALL_WASI to link the whole preview1 surface instead, which
/// is how the size difference between the two is measured.
func runWASIGuest() throws {
    // A second engine runs alongside the demo one above, and the guest's linear
    // memory costs another 64 KiB, so keep this VM stack small: the C3 has only
    // a few hundred KiB of DRAM and a failed allocation faults rather than
    // throwing.
    var configuration = EngineConfiguration()
    configuration.stackSize = 16 * 1024
    let store = Store(engine: Engine(configuration: configuration))
    let bridge = try WASIBridgeToHost(
        fileSystem: .memory(MemoryFileSystem())
            .withStdio(stdin: ConsoleFile(), stdout: ConsoleFile(), stderr: ConsoleFile()))

    // runAndClose closes the bridge even when the body throws; the bridge
    // traps in deinit if it was never closed.
    try bridge.runAndClose { bridge in
        var imports = Imports()
        #if WASMKIT_LINK_ALL_WASI
            bridge.link(to: &imports, store: store, capabilities: WasmKitWASI.WASICapability.all)
        #else
            bridge.link(to: &imports, store: store, capabilities: [.stdio, .process])
        #endif

        let module = try parseWasm(bytes: wasiGuestWasm)
        let instance = try module.instantiate(store: store, imports: imports)
        _ = try bridge.start(instance)
    }
}

/// Drives the GDB stub with real remote-protocol packets.
///
/// The stub is sans-IO: it consumes decoded packets and produces responses, so
/// a transport (UART, USB-CDC, TCP) is the consumer's to supply. This feeds a
/// canned session through the same decoder/encoder a transport would use, which
/// proves the stub links and answers correctly on the device. It does not prove
/// a host `gdb` can attach -- that needs a real transport wired to a UART.
func runGDBStub() throws {
    var configuration = EngineConfiguration()
    configuration.stackSize = 16 * 1024

    // Inject the same console-backed stdio the WASI demo uses: the debuggee
    // writes through fd_write while stopped under the stub, and the host file
    // system the default initialiser would build is unavailable on bare metal.
    let wasi = try WASIBridgeToHost(
        fileSystem: .memory(MemoryFileSystem())
            .withStdio(stdin: ConsoleFile(), stdout: ConsoleFile(), stderr: ConsoleFile()))

    let handler = try WasmKitGDBHandler(
        wasmBinary: wasiGuestWasm,
        moduleFilePath: "/demo.wasm",
        wasi: wasi,
        engineConfiguration: configuration,
        logger: .disabled)

    // The handler owns a WASIBridgeToHost, which traps in deinit unless it is
    // closed, so close on every path.
    try withThrowingGDB(handler) {
        var decoder = GDBHostCommandDecoder(logger: .disabled)
        let encoder = GDBTargetResponseEncoder(logger: .disabled)

        // "+$c#63" -- ack then continue. The debuggee runs to completion and the stub
        // reports its exit status, the exchange a host debugger would see.
        decoder.feed(Array("+$c#63".utf8))
        while let packet = try decoder.next() {
            let response = try handler.handle(command: packet.payload)
            let bytes = encoder.encode(data: response)
            print("gdb reply: \(String(decoding: bytes, as: UTF8.self))")
        }
    }
}

private func withThrowingGDB(_ handler: WasmKitGDBHandler, _ body: () throws -> Void) throws {
    do {
        try body()
    } catch {
        try? handler.close()
        throw error
    }
    try handler.close()
}

// The C UART shim, declared directly rather than through the bridging header:
// each ESP-IDF component contributes its own `-import-bridging-header` and the
// last one on the command line wins, so main's header is not the effective one.
@_silgen_name("gdb_uart_init")
func gdbUARTInit()
@_silgen_name("gdb_uart_read")
func gdbUARTRead(_ buffer: UnsafeMutablePointer<UInt8>?, _ length: Int, _ timeoutMs: UInt32) -> Int32
@_silgen_name("gdb_uart_write")
func gdbUARTWrite(_ buffer: UnsafePointer<UInt8>?, _ length: Int) -> Int32

/// Serves the GDB stub over UART1 so a real debugger can attach.
///
/// The stub is sans-IO, so the transport is ours to provide: read bytes, feed
/// the decoder, write encoded responses back. UART0 is the console, so this
/// uses UART1 -- which QEMU exposes as a socket, letting lldb connect with
/// `gdb-remote`.
func serveGDBOverUART() throws {
    gdbUARTInit()

    var configuration = EngineConfiguration()
    configuration.stackSize = 16 * 1024

    let wasi = try WASIBridgeToHost(
        fileSystem: .memory(MemoryFileSystem())
            .withStdio(stdin: ConsoleFile(), stdout: ConsoleFile(), stderr: ConsoleFile()))
    let handler = try WasmKitGDBHandler(
        wasmBinary: wasiGuestWasm,
        moduleFilePath: "/demo.wasm",
        wasi: wasi,
        engineConfiguration: configuration,
        logger: .disabled)

    print("gdb: listening on UART1")

    var decoder = GDBHostCommandDecoder(logger: .disabled)
    let encoder = GDBTargetResponseEncoder(logger: .disabled)
    var buffer = [UInt8](repeating: 0, count: 256)

    try withThrowingGDB(handler) {
        while true {
            let count = buffer.withUnsafeMutableBufferPointer { raw in
                Int(gdbUARTRead(raw.baseAddress, raw.count, 100))
            }
            guard count > 0 else { continue }
            decoder.feed(Array(buffer[0..<count]))
            while let packet = try decoder.next() {
                let response = try handler.handle(command: packet.payload)
                let bytes = encoder.encode(data: response)
                _ = bytes.withUnsafeBufferPointer { raw in
                    gdbUARTWrite(raw.baseAddress, raw.count)
                }
            }
        }
    }
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

        // WASI guest, linked with only the capabilities it uses.
        do {
            try runWASIGuest()
            // GDB stub answering real protocol packets on-device.
            do {
                #if WASMKIT_GDB_UART
                    // Serve a real debugger over UART1 instead of a canned
                    // session; this does not return.
                    try serveGDBOverUART()
                #else
                    try runGDBStub()
                #endif
            } catch let error as WasmKitGDBHandler.Error {
                switch error {
                case .stoppingAtEntrypointFailed: print("gdb: stoppingAtEntrypointFailed")
                case .exitCodeUnknown: print("gdb: exitCodeUnknown")
                case .killRequestReceived: print("gdb: killRequestReceived")
                case .multipleThreadsNotSupported: print("gdb: multipleThreadsNotSupported")
                case .unknownThreadAction(let a): print("gdb: unknownThreadAction \(a)")
                default: print("gdb: other handler error")
                }
            } catch let error as WasmKitError {
                print("gdb stub wasmkit error: \(error.description)")
            } catch let error as WASIAbi.Errno {
                print("gdb stub errno \(error.rawValue)")
            } catch {
                print("gdb stub error (unknown type)")
            }
        } catch let error as WASIAbi.Errno {
            print("wasi errno \(error.rawValue)")
        } catch let error as WASIError {
            print("wasi host error: \(error.description)")
        } catch let error as WasmKitError {
            print("wasmkit error: \(error.description)")
        } catch {
            print("wasi error (unknown type)")
        }
    } catch {
        print("wasm error")
    }
}
