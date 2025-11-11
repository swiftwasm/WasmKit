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
    import Logging
    import NIOCore
    import NIOFileSystem
    import SystemPackage
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

    extension Debugger.LocalAddress {
        package init(raw: UInt64) {
            let rawAdjusted = raw - localOffset
            self.init(frameIndex: UInt32(truncatingIfNeeded: rawAdjusted >> 32), localIndex: UInt32(truncatingIfNeeded: rawAdjusted))
        }
    }

    private let codeOffset = UInt64(0x4000_0000_0000_0000)
    private let stackOffset = UInt64(0x8000_0000_0000_0000)
    private let localOffset = UInt64(0xC000_0000_0000_0000)

    package actor WasmKitGDBHandler {
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
            case hostCommandNotImplemented(GDBHostCommand.Kind)
            case exitCodeUnknown([Value])
            case killRequestReceived
            case unknownHexEncodedArguments(String)
            case unknownWasmLocalArguments(String)
        }

        private let wasmBinary: ByteBuffer
        private let moduleFilePath: FilePath
        private let logger: Logger
        private let allocator: ByteBufferAllocator
        private var debugger: Debugger

        package init(
            moduleFilePath: FilePath,
            engineConfiguration: EngineConfiguration,
            logger: Logger,
            allocator: ByteBufferAllocator
        ) async throws {
            self.logger = logger
            self.allocator = allocator

            self.wasmBinary = try await FileSystem.shared.withFileHandle(forReadingAt: moduleFilePath) {
                try await $0.readToEnd(maximumSizeAllowed: .unlimited)
            }

            self.moduleFilePath = moduleFilePath

            let store = Store(engine: Engine(configuration: engineConfiguration))
            var imports = Imports()
            let wasi = try WASIBridgeToHost()
            wasi.link(to: &imports, store: store)

            self.debugger = try Debugger(module: parseWasm(bytes: .init(buffer: self.wasmBinary)), store: store, imports: imports)
            try self.debugger.stopAtEntrypoint()
            try self.debugger.run()
            guard case .stoppedAtBreakpoint = self.debugger.state else {
                throw Error.stoppingAtEntrypointFailed
            }
        }

        private func hexDump<I: FixedWidthInteger>(_ value: I, endianness: Endianness) -> String {
            var buffer = self.allocator.buffer(capacity: MemoryLayout<I>.size)
            buffer.writeInteger(value, endianness: endianness)
            return buffer.hexDump(format: .compact)
        }

        private func firstHexArgument<I: FixedWidthInteger>(argumentsString: String, separator: Character, endianness: Endianness) throws -> I {
            guard let hexString = argumentsString.split(separator: separator).first else {
                throw Error.unknownHexEncodedArguments(argumentsString)
            }

            var hexBuffer = try self.allocator.buffer(plainHexEncodedBytes: String(hexString))

            guard let argument = hexBuffer.readInteger(endianness: endianness, as: I.self) else {
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
                    let pcInHostAddressSpace = UInt64(pc) + codeOffset
                    result.append(("thread-pcs", self.hexDump(pcInHostAddressSpace, endianness: .big)))
                    result.append(("00", self.hexDump(pcInHostAddressSpace, endianness: .little)))
                    result.append(("reason", "trace"))
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
            logger.trace("handling GDB host command", metadata: ["GDBHostCommand": .string(command.kind.rawValue)])

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
                        l<library-list>
                            <library name="\(self.moduleFilePath.string)"><section address="0x4000000000000000"/></library>
                        </library-list>
                        """)
                } else {
                    throw Error.unknownTransferArguments
                }

            case .readMemory:
                let argumentsArray = command.arguments.split(separator: ",")
                guard
                    argumentsArray.count == 2,
                    let address = UInt64(hexEncoded: argumentsArray[0]),
                    var length = Int(hexEncoded: argumentsArray[1])
                else { throw Error.unknownReadMemoryArguments }

                if address > localOffset {
                    let localRaw = address - localOffset
                    let localAddress = Debugger.LocalAddress(frameIndex:)
                } else if address > stackOffset {
                    fatalError("Stack reads are not implemented in the debugger yet")
                } else if address > codeOffset {
                    let binaryOffset = address - stackOffset
                    if binaryOffset + length > wasmBinary.readableBytes {
                        length = wasmBinary.readableBytes - binaryOffset
                    }

                    responseKind = .hexEncodedBinary(wasmBinary.readableBytesView[binaryOffset..<(binaryOffset + length)])
                } else {
                    fatalError("Linear memory reads are not implemented in the debugger yet.")
                }

            case .wasmCallStack:
                let callStack = self.debugger.currentCallStack
                var buffer = self.allocator.buffer(capacity: callStack.count * 8)
                for pc in callStack {
                    buffer.writeInteger(UInt64(pc) + codeOffset, endianness: .little)
                }
                responseKind = .hexEncodedBinary(buffer.readableBytesView)

            case .resumeThreads:
                // TODO: support multiple threads each with its own action here.
                let threadActions = command.arguments.components(separatedBy: ":")
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
                    try self.debugger.run()
                }

                responseKind = try self.currentThreadStopInfo

            case .continue:
                try self.debugger.run()

                responseKind = try self.currentThreadStopInfo

            case .kill:
                throw Error.killRequestReceived

            case .insertSoftwareBreakpoint:
                try self.debugger.enableBreakpoint(
                    address: Int(
                        self.firstHexArgument(
                            argumentsString: command.arguments,
                            separator: ",",
                            endianness: .big
                        ) - codeOffset)
                )
                responseKind = .ok

            case .removeSoftwareBreakpoint:
                try self.debugger.disableBreakpoint(
                    address: Int(
                        self.firstHexArgument(
                            argumentsString: command.arguments,
                            separator: ",",
                            endianness: .big
                        ) - codeOffset)
                )
                responseKind = .ok

            case .wasmLocal:
                let arguments = command.arguments.split(separator: ";")
                guard arguments.count == 2,
                    let frameIndexString = arguments.first,
                    let frameIndex = UInt32(frameIndexString),
                    let localIndexString = arguments.last,
                    let localIndex = UInt32(localIndexString)
                else {
                    throw Error.unknownWasmLocalArguments(command.arguments)
                }

                var response = self.allocator.buffer(capacity: 64)
                response.writeInteger(frameIndex, endianness: .little)
                response.writeInteger(localIndex, endianness: .little)

                responseKind = .hexEncodedBinary(response)

            case .generalRegisters:
                throw Error.hostCommandNotImplemented(command.kind)
            }

            logger.trace("handler produced a response", metadata: ["GDBTargetResponse": .string("\(responseKind)")])

            return .init(kind: responseKind, isNoAckModeActive: isNoAckModeActive)
        }
    }

#endif
