#if WasmDebuggingSupport

    import Foundation
    import GDBRemoteProtocol
    import Logging
    import NIOCore
    import SystemPackage
    import Testing
    import WAT

    @testable import WasmKit
    @testable import WasmKitGDBHandler

    @Suite
    struct WasmKitGDBHandlerTests {
        // A user breakpoint on the callee's first instruction is consumed by
        // runPreservingCurrentBreakpoint (it is the entrypoint's step-over target). `$f` does real
        // work before an elided `local.get` so the divergent site sits past that, and the trailing
        // arithmetic leaves an emitted instruction for a single step to land on.
        static let wat = """
            (module
              (func (export "_start") (result i32)
                (call $f))
              (func $f (result i32)
                (local $x i32)
                (i32.const 1)
                (drop)
                (local.set $x (i32.const 7))
                (local.get $x)
                (i32.const 5)
                (i32.add)
                (local.set $x)
                (local.get $x)
                (i32.const 2)
                (i32.mul)
                (drop)
                (i32.const 42)))
            """

        private let offset = DebuggerMemoryView.executableCodeOffset
        private let allocator = ByteBufferAllocator()

        private func divergentAddresses() throws -> (requested: Int, resolved: Int) {
            let bytes = try wat2wasm(Self.wat)
            let module = try parseWasm(bytes: bytes)
            let base = module.functions[1].code.originalAddress

            let firstEmitted = try resolve(module: module, address: base)
            var site: (requested: Int, resolved: Int)?
            for delta in 1..<0x40 {
                let requested = base + delta
                guard let resolved = try? resolve(module: module, address: requested) else { continue }
                if resolved != requested && resolved > firstEmitted {
                    site = (requested, resolved)
                    break
                }
            }
            return try #require(site, "no elided-instruction site resolves forward in the fixture")
        }

        private func resolve(module: Module, address: Int) throws -> Int {
            let store = Store(engine: Engine())
            var debugger = try Debugger(module: module, store: store, imports: [:])
            return try debugger.enableBreakpoint(address: address)
        }

        // Closes on both paths because WASIBridgeToHost's deinit preconditions on close() having run.
        private func withHandler<R>(_ body: (WasmKitGDBHandler) async throws -> R) async throws -> R {
            let bytes = try wat2wasm(Self.wat)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("wasmkit-gdb-\(UUID().uuidString).wasm")
            try Data(bytes).write(to: url)
            var log = Logger(label: "test")
            log.logLevel = .critical
            let h = try await WasmKitGDBHandler(
                moduleFilePath: FilePath(url.path),
                engineConfiguration: EngineConfiguration(),
                logger: log, allocator: ByteBufferAllocator())
            do {
                let result = try await body(h)
                try await h.close()
                return result
            } catch {
                try await h.close()
                throw error
            }
        }

        private func pairs(_ r: GDBTargetResponse) -> [String: String] {
            guard case .keyValuePairs(let kvs) = r.kind else { return [:] }
            return Dictionary(kvs, uniquingKeysWith: { a, _ in a })
        }

        // The `Z0,<addr>,1` hex form LLDB sends, built by the same encoding path the handler uses
        // for stop replies so the expected value tracks any change to that encoding.
        private func hostHex(_ wasmAddr: Int) -> String {
            var buffer = self.allocator.buffer(capacity: MemoryLayout<UInt64>.size)
            buffer.writeInteger(UInt64(wasmAddr) + offset, endianness: .big)
            return buffer.hexDump(format: .compact)
        }

        private func insert(_ h: WasmKitGDBHandler, at wasmAddr: Int) async throws {
            _ = try await h.handle(
                command: .init(
                    kind: .insertSoftwareBreakpoint, arguments: "\(hostHex(wasmAddr)),1"))
        }

        @Test
        func breakpointStopReportsBreakpointReasonAtRequestedAddress() async throws {
            let (requested, resolved) = try divergentAddresses()
            try await withHandler { h in
                try await insert(h, at: requested)
                let stop = try await h.handle(command: .init(kind: .continue, arguments: ""))
                let kv = pairs(stop)
                #expect(kv["reason"] == "breakpoint")
                #expect(kv["thread-pcs"] == hostHex(requested))
                #expect(kv["thread-pcs"] != hostHex(resolved))
            }
        }

        @Test
        func removeBreakpointUninstallsAtResolvedAddress() async throws {
            let (requested, _) = try divergentAddresses()
            try await withHandler { h in
                try await insert(h, at: requested)
                _ = try await h.handle(
                    command: .init(
                        kind: .removeSoftwareBreakpoint, arguments: "\(hostHex(requested)),1"))
                let resp = try await h.handle(command: .init(kind: .continue, arguments: ""))
                // Run to completion yields a `W..` exit reply, not a key-value stop reply.
                if case .string(let s) = resp.kind {
                    #expect(s.hasPrefix("W"))
                } else {
                    Issue.record("expected exit reply after removing the only breakpoint, got \(resp.kind)")
                }
            }
        }

        @Test
        func stepLandingReportsTraceNotBreakpoint() async throws {
            let (requested, _) = try divergentAddresses()
            try await withHandler { h in
                try await insert(h, at: requested)
                _ = try await h.handle(command: .init(kind: .continue, arguments: ""))
                let step = try await h.handle(command: .init(kind: .resumeThreads, arguments: "s:1"))
                #expect(pairs(step)["reason"] == "trace")
            }
        }

        static let globalWAT = """
            (module
              (global $g (mut i32) (i32.const 7))
              (func (export "_start") (result i32) (global.get $g)))
            """

        private func withGlobalHandler<R>(_ body: (WasmKitGDBHandler) async throws -> R) async throws -> R {
            let bytes = try wat2wasm(Self.globalWAT)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("wasmkit-gdb-\(UUID().uuidString).wasm")
            try Data(bytes).write(to: url)
            var log = Logger(label: "test")
            log.logLevel = .critical
            let h = try await WasmKitGDBHandler(
                moduleFilePath: FilePath(url.path),
                engineConfiguration: EngineConfiguration(),
                logger: log, allocator: ByteBufferAllocator())
            do {
                let result = try await body(h)
                try await h.close()
                return result
            } catch {
                try await h.close()
                throw error
            }
        }

        @Test
        func wasmGlobalRepliesWithLittleEndianValue() async throws {
            try await withGlobalHandler { h in
                let resp = try await h.handle(command: .init(kind: .wasmGlobal, arguments: "0;0"))
                guard case .hexEncodedBinary(let view) = resp.kind else {
                    Issue.record("expected hexEncodedBinary, got \(resp.kind)")
                    return
                }
                var buffer = ByteBuffer(bytes: view)
                #expect(buffer.readInteger(endianness: .little, as: UInt64.self) == 7)
            }
        }

        @Test
        func wasmGlobalRejectsMissingIndex() async throws {
            _ = try await withGlobalHandler { h in
                await #expect(throws: WasmKitGDBHandler.Error.self) {
                    _ = try await h.handle(command: .init(kind: .wasmGlobal, arguments: "0;"))
                }
            }
        }
    }

#endif
