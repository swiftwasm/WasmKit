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
                (call $g)
            )

            (func $f (param $a i32) (result i32)
                (local.get $a)
            )

            (func $g (param $a i32) (result i32) (local $x i32)
                (i32.const 24)
                (local.set $x)
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

            var breakpointAddress = try debugger.enableBreakpoint(module: module, function: 1)
            try debugger.enableBreakpoint(address: breakpointAddress)
            try debugger.run()

            var localAddress = try memoryCache.getAddressOfLocal(debugger: &debugger, frameIndex: 0, localIndex: 0)
            var buffer = ByteBuffer(memoryCache.readMemory(debugger: debugger, addressInProtocolSpace: localAddress, length: 4))
            var value = buffer.readInteger(endianness: .little, as: UInt32.self)
            #expect(value == 42)

            breakpointAddress = try debugger.enableBreakpoint(
                module: module,
                function: 2,
                // i32.const 2 bytes + local.set 4 bytes
                offsetWithinFunction: 6
            )
            try debugger.enableBreakpoint(address: breakpointAddress)
            try debugger.run()
            memoryCache.invalidate()

            localAddress = try memoryCache.getAddressOfLocal(debugger: &debugger, frameIndex: 0, localIndex: 1)
            buffer = ByteBuffer(memoryCache.readMemory(debugger: debugger, addressInProtocolSpace: localAddress, length: 4))
            value = buffer.readInteger(endianness: .little, as: UInt32.self)
            #expect(value == 24)
        }
    }
#endif
