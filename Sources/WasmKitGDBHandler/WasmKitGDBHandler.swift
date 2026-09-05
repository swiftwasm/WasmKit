//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if WasmDebuggingSupport

    import GDBRemoteProtocol
    import WASI
    import WasmKit
    import WasmKitWASI

    extension BinaryInteger {
        init?(hexEncoded: Substring) {
            var result = Self.zero
            for (offset, element) in hexEncoded.reversed().enumerated() {
                guard let digit = element.hexDigitValue else { return nil }
                result += Self(digit) << (offset * 4)
            }

            self = result
        }
    }

    /// The module instance and global index a `qWasmGlobal` request names.
    ///
    /// A debugger advertising `qWasmInstance+` specifies the instance owning
    /// the global index with an `instance:<id>` field. Older debuggers may send
    /// a frame index instead.
    struct WasmGlobalRequest {
        private static let instanceKey = "instance:"

        /// The instance owning the global index space, or nil where the request named a
        /// frame and the instance is whichever one that frame is executing.
        let instance: UInt64?

        let globalIndex: UInt

        /// Parses `<global>;instance:<id>` or the older `<frame>;<global>`.
        init?(arguments: String) {
            // Keep empty fields so a malformed `<frame>;` is rejected rather than read as `<frame>`.
            var fields = arguments.split(separator: ";", omittingEmptySubsequences: false)

            // A request may terminate its last field with the delimiter, yielding a
            // trailing empty field that carries no argument.
            if fields.count == 3 && fields[2].isEmpty {
                fields.removeLast()
            }

            // Exactly two fields, so a request mixing both forms is rejected rather than
            // read as one of them.
            guard fields.count == 2, let first = UInt(fields[0]) else { return nil }

            if fields[1].hasPrefix(Self.instanceKey) {
                guard let instance = UInt64(fields[1].dropFirst(Self.instanceKey.count)) else { return nil }
                self.instance = instance
                self.globalIndex = first
                return
            }

            guard let globalIndex = UInt(fields[1]) else { return nil }
            self.instance = nil
            self.globalIndex = globalIndex
        }
    }

    /// A sans-IO GDB remote-protocol target.
    package final class WasmKitGDBHandler {
        enum ResumeThreadsAction: String {
            case step = "s"
            case `continue` = "c"
        }

        package enum Error: Swift.Error {
            case unknownTransferArguments
            case unknownReadMemoryArguments
            case stoppingAtEntrypointFailed
            case multipleThreadsNotSupported
            case unknownThreadAction(String)

            case exitCodeUnknown([Value])
            case killRequestReceived
            case unknownHexEncodedArguments(String)
            case unknownWasmLocalArguments(String)
            case unknownWasmGlobalArguments(String)
            case unknownDetachOnErrorArgument(String)
        }

        private let moduleFilePath: String
        private let logger: GDBLogger
        private var debugger: Debugger

        /// Generic error reply. `QEnableErrorStrings` is unsupported, so a bare code is
        /// the only way to refuse a request the target understands but cannot answer.
        private static let errorReply = "E45"

        private var memoryView: DebuggerMemoryView
        /// User-set breakpoints, keyed by the address the debugger host
        /// requested, with the engine's resolved address as the value.
        /// Stops at a resolved address are reported as breakpoint stops at
        /// the requested address, which is the location the host knows.
        private var userBreakpoints: [Int: Int] = [:]
        private let wasi: WASIBridgeToHost

        /// Whether a client that goes away without `k` or `D` leaves the guest running to
        /// completion, as `QSetDetachOnError` selects.
        package private(set) var detachesOnDisconnect = true

        /// Creates a handler debugging the given WebAssembly binary.
        ///
        /// The handler is transport- and file-system-free: the caller supplies
        /// the module bytes (read from disk, flash, or anywhere else) and
        /// `moduleFilePath` is only reported to the debugger host for module
        /// identification.
        /// Debugs a module against a caller-supplied WASI instance.
        ///
        /// The handler takes ownership: ``close()`` closes `wasi`, and the
        /// initialiser closes it if setting the debuggee up fails.
        ///
        /// Bare-metal targets need this: the host file system is unavailable
        /// there, so stdio has to be injected as `WASIFile`s pointing at a
        /// UART. Building the bridge here rather than internally is what makes
        /// the stub usable on a device.
        package init(
            wasmBinary: [UInt8],
            moduleFilePath: String,
            wasi: WASIBridgeToHost,
            engineConfiguration: EngineConfiguration,
            logger: GDBLogger
        ) throws {
            self.logger = logger

            self.moduleFilePath = moduleFilePath

            let store = Store(engine: Engine(configuration: engineConfiguration))
            var imports = Imports()
            wasi.link(to: &imports, store: store)
            self.wasi = wasi

            do {
                self.debugger = try Debugger(module: parseWasm(bytes: wasmBinary), store: store, imports: imports)
                try self.debugger.stopAtEntrypoint()
                try self.debugger.run()
                guard case .stoppedAtBreakpoint = self.debugger.state else {
                    throw Error.stoppingAtEntrypointFailed
                }
            } catch {
                throw CleanupFailure.preserving(error, cleanup: wasi.close)
            }

            self.memoryView = DebuggerMemoryView(wasmBinary: wasmBinary)
        }

        /// Debugs a module against a host-backed WASI instance.
        package convenience init(
            wasmBinary: [UInt8],
            moduleFilePath: String,
            wasiConfiguration: WASIConfiguration,
            engineConfiguration: EngineConfiguration,
            logger: GDBLogger
        ) throws {
            try self.init(
                wasmBinary: wasmBinary,
                moduleFilePath: moduleFilePath,
                wasi: WASIBridgeToHost(configuration: wasiConfiguration),
                engineConfiguration: engineConfiguration,
                logger: logger
            )
        }

        /// How far to let the guest run.
        private enum Resume {
            /// One Wasm instruction.
            case step
            /// Until the next breakpoint.
            case untilBreakpoint
            /// Until the guest ends.
            case toCompletion
        }

        private func resume(_ resume: Resume) throws {
            do {
                switch resume {
                case .step: try self.debugger.step()
                case .untilBreakpoint: try self.debugger.runPreservingCurrentBreakpoint()
                case .toCompletion: try self.debugger.run()
                }
            } catch let exit as WASIExitCode {
                self.debugger.recordExit(status: exit.code)
            }
        }

        package func close() throws {
            try wasi.close()
        }

        /// Lets the guest run to completion, as `D` asks for. The resume is blocking, so a guest
        /// that never terminates keeps the caller here.
        package func detach() throws {
            self.debugger.removeAllBreakpoints()
            self.userBreakpoints.removeAll()

            // Resuming a guest that already returned would be a restart, which is unimplemented.
            guard case .stoppedAtBreakpoint = self.debugger.state else { return }

            try self.resume(.toCompletion)
        }

        enum Endianness {
            case big, little
        }

        /// Reply that the guest has exited with the given exit status.
        private static func exitReply(status: some FixedWidthInteger) -> GDBTargetResponse.Kind {
            .string("W\(HexEncoding.encode(UInt8(truncatingIfNeeded: status).bigEndianBytes))")
        }

        private func hexDump<I: FixedWidthInteger>(_ value: I, endianness: Endianness) -> String {
            switch endianness {
            case .big: return HexEncoding.encode(value.bigEndianBytes)
            case .little: return HexEncoding.encode(value.littleEndianBytes)
            }
        }

        private func firstHexArgument<I: FixedWidthInteger>(argumentsString: String, separator: Character, endianness: Endianness) throws -> I {
            guard let hexString = argumentsString.split(separator: separator).first else {
                throw Error.unknownHexEncodedArguments(argumentsString)
            }

            guard let hexBytes = HexEncoding.decode(hexString), hexBytes.count >= MemoryLayout<I>.size else {
                throw Error.unknownHexEncodedArguments(argumentsString)
            }

            let prefix = hexBytes.prefix(MemoryLayout<I>.size)
            let argument: I?
            switch endianness {
            case .big: argument = I(bigEndianBytes: prefix)
            case .little: argument = I(littleEndianBytes: prefix)
            }
            guard let argument else {
                throw Error.unknownHexEncodedArguments(argumentsString)
            }

            return argument
        }

        /// Matches on the resolved address that caused the trap, rather than the reported address.
        private func isStoppedAtUserBreakpoint(_ breakpoint: Debugger.BreakpointState) -> Bool {
            self.userBreakpoints.contains { $0.value == breakpoint.wasmPc }
        }

        var currentThreadStopInfo: GDBTargetResponse.Kind {
            get throws {
                var result: [(String, String)] = [
                    ("T05thread", "1"),
                    ("threads", "1"),
                ]
                switch self.debugger.state {
                case .stoppedAtBreakpoint(let breakpoint):
                    let reportedPc = UInt64(breakpoint.reportedPc) + DebuggerMemoryView.executableCodeOffset
                    result.append(("thread-pcs", self.hexDump(reportedPc, endianness: .big)))
                    result.append(("00", self.hexDump(reportedPc, endianness: .little)))
                    result.append(("reason", self.isStoppedAtUserBreakpoint(breakpoint) ? "breakpoint" : "trace"))
                    return .keyValuePairs(result)

                case .entrypointReturned(let values):
                    guard !values.isEmpty else {
                        return Self.exitReply(status: 0)
                    }

                    guard case .i32(let exitCode) = values.first else {
                        throw Error.exitCodeUnknown(values)
                    }

                    return Self.exitReply(status: exitCode)

                case .exited(let status):
                    return Self.exitReply(status: status)

                case .trapped(let trapReason):
                    result.append(("reason", "trap"))
                    result.append(("description", trapReason))
                    return .keyValuePairs(result)

                case .instantiated:
                    return .empty
                }
            }
        }

        package func handle(command: GDBHostCommand) throws -> GDBTargetResponse {
            let responseKind: GDBTargetResponse.Kind
            logger.trace("handling GDB host command: \(command.kind.rawValue)")

            var isNoAckModeActive = false
            switch command.kind {
            case .startNoAckMode:
                isNoAckModeActive = true
                fallthrough

            case .isThreadSuffixSupported, .listThreadsInStopReply:
                responseKind = .ok

            case .hostInfo:
                responseKind = .keyValuePairs([
                    ("arch", "wasm32"),
                    ("ptrsize", "4"),
                    ("endian", "little"),
                    ("ostype", "wasip1"),
                    ("vendor", "WasmKit"),
                ])

            case .supportedFeatures:
                responseKind = .string("qXfer:libraries:read+;qWasmInstance+;PacketSize=1000;")

            case .vContSupportedActions:
                responseKind = .vContSupportedActions([.continue, .step])

            case .isVAttachOrWaitSupported, .enableErrorStrings, .structuredDataPlugins, .readMemoryBinaryData,
                .symbolLookup, .jsonThreadsInfo, .jsonThreadExtendedInfo:
                responseKind = .empty

            case .setDetachOnError:
                switch command.arguments {
                case "0":
                    self.detachesOnDisconnect = false
                case "1":
                    self.detachesOnDisconnect = true
                default:
                    throw Error.unknownDetachOnErrorArgument(command.arguments)
                }

                responseKind = .ok

            case .processInfo:
                responseKind = .keyValuePairs([
                    ("pid", "1"),
                    ("parent-pid", "1"),
                    ("arch", "wasm32"),
                    ("endian", "little"),
                    ("ptrsize", "4"),
                ])

            case .currentThreadID:
                responseKind = .string("QC1")

            case .firstThreadInfo:
                responseKind = .string("m1")

            case .subsequentThreadInfo:
                responseKind = .string("l")

            case .targetStatus, .threadStopInfo:
                responseKind = try self.currentThreadStopInfo

            case .registerInfo:
                if command.arguments == "0" {
                    responseKind = .keyValuePairs([
                        ("name", "pc"),
                        ("bitsize", "64"),
                        ("offset", "0"),
                        ("encoding", "uint"),
                        ("format", "hex"),
                        ("set", "General Purpose Registers"),
                        ("gcc", "16"),
                        ("dwarf", "16"),
                        ("generic", "pc"),
                    ])
                } else {
                    responseKind = .string(Self.errorReply)
                }

            case .transfer:
                if command.arguments.starts(with: "libraries:read:") {
                    responseKind = .string(
                        """
                        l<library-list>\
                        <library name="\(self.moduleFilePath)">\
                        <section address="0x\(String(DebuggerMemoryView.executableCodeOffset, radix: 16))"/>\
                        </library>\
                        </library-list>
                        """)
                } else {
                    throw Error.unknownTransferArguments
                }

            case .readMemory:
                let argumentsArray = command.arguments.split(separator: ",")
                guard
                    argumentsArray.count == 2,
                    let addressInProtocolSpace = UInt64(hexEncoded: argumentsArray[0]),
                    let length = UInt(hexEncoded: argumentsArray[1])
                else { throw Error.unknownReadMemoryArguments }

                responseKind = .hexEncodedBinary(
                    try self.memoryView.readMemory(
                        debugger: self.debugger,
                        addressInProtocolSpace: addressInProtocolSpace,
                        length: length
                    )
                )

            case .wasmCallStack:
                let callStack = self.debugger.reportedCallStack
                var buffer = [UInt8]()
                buffer.reserveCapacity(callStack.count * 8)
                for pc in callStack {
                    buffer.append(contentsOf: (UInt64(pc) + DebuggerMemoryView.executableCodeOffset).littleEndianBytes)
                }
                responseKind = .hexEncodedBinary(buffer)

            case .resumeThreads:
                // TODO: support multiple threads each with its own action here.
                let threadActions = command.arguments.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
                guard threadActions.count == 2, let threadActionString = threadActions.first else {
                    throw Error.multipleThreadsNotSupported
                }

                guard let threadAction = ResumeThreadsAction(rawValue: threadActionString) else {
                    throw Error.unknownThreadAction(threadActionString)
                }

                switch threadAction {
                case .step:
                    try self.resume(.step)
                case .continue:
                    try self.resume(.untilBreakpoint)
                }

                responseKind = try self.currentThreadStopInfo

            case .continue:
                try self.resume(.untilBreakpoint)

                responseKind = try self.currentThreadStopInfo

            case .kill:
                throw Error.killRequestReceived

            case .detach:
                try self.detach()
                throw Error.killRequestReceived

            case .insertSoftwareBreakpoint:
                let requested = Int(
                    try self.firstHexArgument(
                        argumentsString: command.arguments,
                        separator: ",",
                        endianness: .big
                    ) - DebuggerMemoryView.executableCodeOffset)
                // Report refusal as a GDB error instead of throwing to keep the connection open.
                do {
                    self.userBreakpoints[requested] = try self.debugger.enableBreakpoint(address: requested)
                    responseKind = .ok
                } catch let error as Debugger.Error {
                    logger.debug("refusing a breakpoint at \(requested): \(error)")
                    responseKind = .string(Self.errorReply)
                }

            case .removeSoftwareBreakpoint:
                let requested = Int(
                    try self.firstHexArgument(
                        argumentsString: command.arguments,
                        separator: ",",
                        endianness: .big
                    ) - DebuggerMemoryView.executableCodeOffset)
                do {
                    try self.debugger.disableBreakpoint(address: requested)
                    self.userBreakpoints[requested] = nil
                    responseKind = .ok
                } catch let error as Debugger.Error {
                    logger.debug("refusing to remove a breakpoint at \(requested): \(error)")
                    responseKind = .string(Self.errorReply)
                }

            case .wasmLocal:
                let arguments = command.arguments.split(separator: ";")
                guard arguments.count == 2,
                    let frameIndexString = arguments.first,
                    let frameIndex = UInt(frameIndexString),
                    let localIndexString = arguments.last,
                    let localIndex = UInt(localIndexString)
                else {
                    throw Error.unknownWasmLocalArguments(command.arguments)
                }

                responseKind = .hexEncodedBinary(
                    try self.debugger.getLocal(frameIndex: frameIndex, localIndex: localIndex).littleEndianBytes
                )

            case .wasmGlobal:
                guard let request = WasmGlobalRequest(arguments: command.arguments) else {
                    throw Error.unknownWasmGlobalArguments(command.arguments)
                }

                // A global index is meaningful only within one instance's global index
                // space, so a request naming another instance is refused rather than
                // answered from this one.
                if let instance = request.instance, instance != DebuggerMemoryView.moduleInstanceID {
                    responseKind = .string(Self.errorReply)
                } else {
                    responseKind = .hexEncodedBinary(
                        try self.debugger.getGlobal(index: request.globalIndex).littleEndianBytes
                    )
                }

            case .memoryRegionInfo:
                responseKind = .empty

            case .generalRegisters:
                responseKind = .empty

            case .unsupported:
                logger.debug("unsupported GDB host command: \(command.arguments)")
                responseKind = .empty
            }

            logger.trace("handler produced a response: \(responseKind)")

            return .init(kind: responseKind, isNoAckModeActive: isNoAckModeActive)
        }
    }

#endif
