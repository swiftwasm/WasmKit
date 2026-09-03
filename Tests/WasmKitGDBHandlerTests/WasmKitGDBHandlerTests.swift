#if WasmDebuggingSupport

    import GDBRemoteProtocol
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

        private func pairs(_ r: GDBTargetResponse) -> [String: String] {
            guard case .keyValuePairs(let kvs) = r.kind else { return [:] }
            return Dictionary(kvs, uniquingKeysWith: { a, _ in a })
        }

        // The `Z0,<addr>,1` hex form LLDB sends, built by the same encoding path the handler uses
        // for stop replies so the expected value tracks any change to that encoding.
        private func hostHex(_ wasmAddr: Int) -> String {
            HexEncoding.encode((UInt64(wasmAddr) + offset).bigEndianBytes)
        }

        private func insert(_ h: WasmKitGDBHandler, at wasmAddr: Int) throws {
            _ = try h.handle(
                command: .init(
                    kind: .insertSoftwareBreakpoint, arguments: "\(hostHex(wasmAddr)),1"))
        }

        @Test
        func breakpointStopReportsBreakpointReasonAtRequestedAddress() throws {
            let (requested, resolved) = try divergentAddresses()
            try withHandler(debugging: Self.wat) { h in
                try insert(h, at: requested)
                let stop = try h.handle(command: .init(kind: .continue, arguments: ""))
                let kv = pairs(stop)
                #expect(kv["reason"] == "breakpoint")
                #expect(kv["thread-pcs"] == hostHex(requested))
                #expect(kv["thread-pcs"] != hostHex(resolved))
            }
        }

        @Test
        func removeBreakpointUninstallsAtResolvedAddress() throws {
            let (requested, _) = try divergentAddresses()
            try withHandler(debugging: Self.wat) { h in
                try insert(h, at: requested)
                _ = try h.handle(
                    command: .init(
                        kind: .removeSoftwareBreakpoint, arguments: "\(hostHex(requested)),1"))
                let resp = try h.handle(command: .init(kind: .continue, arguments: ""))
                // Run to completion yields a `W..` exit reply, not a key-value stop reply.
                if case .string(let s) = resp.kind {
                    #expect(s.hasPrefix("W"))
                } else {
                    Issue.record("expected exit reply after removing the only breakpoint, got \(resp.kind)")
                }
            }
        }

        @Test
        func stepLandingReportsTraceNotBreakpoint() throws {
            let (requested, _) = try divergentAddresses()
            try withHandler(debugging: Self.wat) { h in
                try insert(h, at: requested)
                _ = try h.handle(command: .init(kind: .continue, arguments: ""))
                let step = try h.handle(command: .init(kind: .resumeThreads, arguments: "s:1"))
                #expect(pairs(step)["reason"] == "trace")
            }
        }

        @Test
        func detachRunsTheGuestToCompletion() throws {
            let (requested, _) = try divergentAddresses()
            try withHandler(debugging: Self.wat) { h in
                try insert(h, at: requested)
                #expect(pairs(try h.handle(command: .init(kind: .continue, arguments: "")))["reason"] == "breakpoint")

                try h.detach()

                let status = try h.handle(command: .init(kind: .targetStatus, arguments: ""))
                guard case .string(let reply) = status.kind else {
                    Issue.record("expected an exit reply after detaching, got \(status.kind)")
                    return
                }
                #expect(reply.hasPrefix("W"))
            }
        }

        @Test
        func detachOnDisconnectIsRequestedByDefaultAndSelectable() throws {
            try withHandler(debugging: Self.wat) { h in
                #expect(h.detachesOnDisconnect)

                let off = try h.handle(command: .init(kind: .setDetachOnError, arguments: "0"))
                if case .ok = off.kind {
                } else {
                    Issue.record("expected OK, got \(off.kind)")
                }
                #expect(!h.detachesOnDisconnect)

                _ = try h.handle(command: .init(kind: .setDetachOnError, arguments: "1"))
                #expect(h.detachesOnDisconnect)
            }
        }

        @Test
        func setDetachOnErrorRejectsValuesOtherThanZeroOrOne() throws {
            _ = try withHandler(debugging: Self.wat) { h in
                #expect(throws: WasmKitGDBHandler.Error.self) {
                    _ = try h.handle(command: .init(kind: .setDetachOnError, arguments: "2"))
                }
                #expect(h.detachesOnDisconnect)
            }
        }

        // Distinct global values, so a reply pins down which field of a `qWasmGlobal`
        // request was read as the global index.
        static let globalWAT = """
            (module
              (global $g (mut i32) (i32.const 7))
              (global $h (mut i32) (i32.const 11))
              (func (export "_start") (result i32) (global.get $g)))
            """

        @Test
        func wasmGlobalRepliesWithLittleEndianValue() throws {
            try withHandler(debugging: Self.globalWAT) { h in
                let resp = try h.handle(command: .init(kind: .wasmGlobal, arguments: "0;0"))
                guard case .hexEncodedBinary(let bytes) = resp.kind else {
                    Issue.record("expected hexEncodedBinary, got \(resp.kind)")
                    return
                }
                #expect(UInt64(littleEndianBytes: bytes) == 7)
            }
        }

        @Test
        func wasmGlobalIgnoresTheFrameIndex() throws {
            try withHandler(debugging: Self.globalWAT) { h in
                let resp = try h.handle(command: .init(kind: .wasmGlobal, arguments: "0;1"))
                guard case .hexEncodedBinary(let bytes) = resp.kind else {
                    Issue.record("expected hexEncodedBinary, got \(resp.kind)")
                    return
                }
                #expect(UInt64(littleEndianBytes: bytes) == 11)
            }
        }

        @Test
        func wasmGlobalRejectsMissingIndex() throws {
            _ = try withHandler(debugging: Self.globalWAT) { h in
                #expect(throws: WasmKitGDBHandler.Error.self) {
                    _ = try h.handle(command: .init(kind: .wasmGlobal, arguments: "0;"))
                }
            }
        }

        @Test
        func supportedFeaturesAdvertisesInstanceNamedWasmGlobal() throws {
            try withHandler(debugging: Self.globalWAT) { h in
                let resp = try h.handle(command: .init(kind: .supportedFeatures, arguments: ""))
                guard case .string(let features) = resp.kind else {
                    Issue.record("expected a feature string, got \(resp.kind)")
                    return
                }
                #expect(features.split(separator: ";").contains("qWasmInstance+"))
            }
        }

        @Test
        func wasmGlobalReadsTheGlobalOfAnInstanceNamedRequest() throws {
            try withHandler(debugging: Self.globalWAT) { h in
                let resp = try h.handle(
                    command: .init(
                        kind: .wasmGlobal,
                        arguments: "1;instance:\(DebuggerMemoryView.moduleInstanceID);"))
                guard case .hexEncodedBinary(let bytes) = resp.kind else {
                    Issue.record("expected hexEncodedBinary, got \(resp.kind)")
                    return
                }
                #expect(UInt64(littleEndianBytes: bytes) == 11)
            }
        }

        @Test
        func wasmGlobalAcceptsAnInstanceWithoutATrailingDelimiter() throws {
            try withHandler(debugging: Self.globalWAT) { h in
                let resp = try h.handle(
                    command: .init(
                        kind: .wasmGlobal,
                        arguments: "1;instance:\(DebuggerMemoryView.moduleInstanceID)"))
                guard case .hexEncodedBinary(let bytes) = resp.kind else {
                    Issue.record("expected hexEncodedBinary, got \(resp.kind)")
                    return
                }
                #expect(UInt64(littleEndianBytes: bytes) == 11)
            }
        }

        @Test
        func wasmGlobalRefusesAnInstanceItDoesNotRun() throws {
            try withHandler(debugging: Self.globalWAT) { h in
                let unknown = DebuggerMemoryView.moduleInstanceID + 1
                let resp = try h.handle(
                    command: .init(kind: .wasmGlobal, arguments: "0;instance:\(unknown);"))
                guard case .string(let reply) = resp.kind else {
                    Issue.record("expected an error reply, got \(resp.kind)")
                    return
                }
                #expect(reply.hasPrefix("E"))
            }
        }

        @Test
        func wasmGlobalRejectsAnUnparsableInstance() throws {
            _ = try withHandler(debugging: Self.globalWAT) { h in
                #expect(throws: WasmKitGDBHandler.Error.self) {
                    _ = try h.handle(command: .init(kind: .wasmGlobal, arguments: "0;instance:;"))
                }
            }
        }

        // Both forms at once names the global ambiguously, so neither reading may be served.
        @Test
        func wasmGlobalRejectsARequestMixingAFrameIndexAndAnInstance() throws {
            _ = try withHandler(debugging: Self.globalWAT) { h in
                #expect(throws: WasmKitGDBHandler.Error.self) {
                    _ = try h.handle(
                        command: .init(
                            kind: .wasmGlobal,
                            arguments: "0;1;instance:\(DebuggerMemoryView.moduleInstanceID);"))
                }
            }
        }

        // Addresses reported to a host are offsets from this base, making its value part
        // of the protocol rather than an implementation detail.
        @Test
        func executableCodeStartsAtTheObjectSpaceTag() {
            #expect(DebuggerMemoryView.executableCodeOffset == 0x4000_0000_0000_0000)
        }
    }

#endif
