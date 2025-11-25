#if WasmDebuggingSupport

    import NIOCore
    import Testing
    import WAT
    import WasmKit
    import WasmKitGDBHandler

    private let manyLocalsWAT = """
        (module
            (func (export "_start") (result i32) (local $x i32)
                (i32.const 42)
                (i32.const 0)
                (i32.eqz)
                (drop)
                (local.set $x)
                (local.get $x)
                (call $f)
            )

            (func $f (param $a i32) (result i32)
                (local.get $a)
            )
        )
        """

    @Suite
    struct DebuggerMemoryCacheTests {

        @Test
        func localAddress() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(manyLocalsWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            var memoryCache = DebuggerMemoryCache(allocator: .init(), wasmBinary: .init(bytes: bytes))

            let breakpointAddress = try debugger.enableBreakpoint(module: module, function: 1)
            try debugger.run()

            let localAddress = try memoryCache.getAddressOfLocal(debugger: &debugger, frameIndex: 0, localIndex: 0)
            var buffer = ByteBuffer(memoryCache.readMemory(debugger: debugger, addressInProtocolSpace: localAddress, length: 4))
            let value = buffer.readInteger(endianness: .little, as: UInt32.self)
            #expect(value == 42)
        }
    }
#endif
