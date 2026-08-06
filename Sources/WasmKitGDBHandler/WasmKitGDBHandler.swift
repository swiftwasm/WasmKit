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
        }

        private let moduleFilePath: String
        private let logger: GDBLogger
        private var debugger: Debugger

        private var memoryView: DebuggerMemoryView
        /// User-set breakpoints, keyed by the address the debugger host
        /// requested, with the engine's resolved address as the value.
        /// Stops at a resolved address are reported as breakpoint stops at
        /// the requested address, which is the location the host knows.
        private var userBreakpoints: [Int: Int] = [:]
        private let wasi: WASIBridgeToHost

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

        package func close() throws {
            try wasi.close()
        }

        enum Endianness {
            case big, little
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

        var currentThreadStopInfo: GDBTargetResponse.Kind {
            get throws {
                var result: [(String, String)] = [
                    ("T05thread", "1"),
                    ("threads", "1"),
                ]
                switch self.debugger.state {
                case .stoppedAtBreakpoint(let breakpoint):
                    let pc = breakpoint.wasmPc
                    let userBreakpoint = self.userBreakpoints.first(where: { $0.value == pc })?.key
                    // Report user-breakpoint stops at the address the host
                    // requested, so it can attribute the stop to its
                    // breakpoint even when the engine resolved the address
                    // to the next emitted instruction.
                    let reportedPc = UInt64(userBreakpoint ?? pc) + DebuggerMemoryView.executableCodeOffset
                    result.append(("thread-pcs", self.hexDump(reportedPc, endianness: .big)))
                    result.append(("00", self.hexDump(reportedPc, endianness: .little)))
                    result.append(("reason", userBreakpoint != nil ? "breakpoint" : "trace"))
                    return .keyValuePairs(result)

                case .entrypointReturned(let values):
                    guard !values.isEmpty else {
                        return .string("W\(self.hexDump(0 as UInt8, endianness: .big))")
                    }

                    guard case .i32(let exitCode) = values.first else {
                        throw Error.exitCodeUnknown(values)
                    }

                    return .string("W\(self.hexDump(exitCode, endianness: .big))")

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
                responseKind = .string("qXfer:libraries:read+;PacketSize=1000;")

            case .vContSupportedActions:
                responseKind = .vContSupportedActions([.continue, .step])

            case .isVAttachOrWaitSupported, .enableErrorStrings, .structuredDataPlugins, .readMemoryBinaryData,
                .symbolLookup, .jsonThreadsInfo, .jsonThreadExtendedInfo:
                responseKind = .empty

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
                    responseKind = .string("E45")
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
                let callStack = self.debugger.currentCallStack
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
                    try self.debugger.step()
                case .continue:
                    try self.debugger.runPreservingCurrentBreakpoint()
                }

                responseKind = try self.currentThreadStopInfo

            case .continue:
                try self.debugger.runPreservingCurrentBreakpoint()

                responseKind = try self.currentThreadStopInfo

            case .kill:
                throw Error.killRequestReceived

            case .detach:
                self.debugger.removeAllBreakpoints()
                self.userBreakpoints.removeAll()

                try self.debugger.run()
                throw Error.killRequestReceived

            case .insertSoftwareBreakpoint:
                let requested = Int(
                    try self.firstHexArgument(
                        argumentsString: command.arguments,
                        separator: ",",
                        endianness: .big
                    ) - DebuggerMemoryView.executableCodeOffset)
                self.userBreakpoints[requested] = try self.debugger.enableBreakpoint(address: requested)
                responseKind = .ok

            case .removeSoftwareBreakpoint:
                let requested = Int(
                    try self.firstHexArgument(
                        argumentsString: command.arguments,
                        separator: ",",
                        endianness: .big
                    ) - DebuggerMemoryView.executableCodeOffset)
                try self.debugger.disableBreakpoint(address: requested)
                self.userBreakpoints[requested] = nil
                responseKind = .ok

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
                // Keep empty fields so a malformed `<frame>;` is rejected rather than read as `<frame>`.
                let arguments = command.arguments.split(separator: ";", omittingEmptySubsequences: false)
                guard arguments.count == 2,
                    let globalIndex = UInt(arguments[1])
                else {
                    throw Error.unknownWasmGlobalArguments(command.arguments)
                }

                responseKind = .hexEncodedBinary(
                    try self.debugger.getGlobal(index: globalIndex).littleEndianBytes
                )

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
