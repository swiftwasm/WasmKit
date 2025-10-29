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

    private let codeOffset = UInt64(0x4000_0000_0000_0000)

    package actor WasmKitGDBHandler {
        enum ResumeThreadsAction: String {
            case step = "s"
        }

        enum Error: Swift.Error {
            case unknownTransferArguments
            case unknownReadMemoryArguments
            case stoppingAtEntrypointFailed
            case multipleThreadsNotSupported
            case unknownThreadAction(String)
            case hostCommandNotImplemented(GDBHostCommand.Kind)
        }

        private let wasmBinary: ByteBuffer
        private let moduleFilePath: FilePath
        private let logger: Logger
        private let allocator: ByteBufferAllocator
        private var debugger: Debugger
        private var hasSteppedBefore = false

        package init(moduleFilePath: FilePath, logger: Logger, allocator: ByteBufferAllocator) async throws {
            self.logger = logger
            self.allocator = allocator

            self.wasmBinary = try await FileSystem.shared.withFileHandle(forReadingAt: moduleFilePath) {
                try await $0.readToEnd(maximumSizeAllowed: .unlimited)
            }

            self.moduleFilePath = moduleFilePath

            let store = Store(engine: Engine())
            var imports = Imports()
            let wasi = try WASIBridgeToHost()
            wasi.link(to: &imports, store: store)

            self.debugger = try Debugger(module: parseWasm(bytes: .init(buffer: self.wasmBinary)), store: store, imports: imports)
            try self.debugger.stopAtEntrypoint()
            guard try self.debugger.run() == nil else {
                throw Error.stoppingAtEntrypointFailed
            }
        }

        var currentThreadStopInfo: GDBTargetResponse.Kind {
            var result: [(String, String)] = [
                ("T05thread", "1"),
                ("reason", "trace"),
                ("threads", "1"),
            ]
            if let pc = self.debugger.currentCallStack.first {
                let pcInHostAddressSpace = UInt64(pc) + codeOffset
                var beBuffer = self.allocator.buffer(capacity: 8)
                beBuffer.writeInteger(pcInHostAddressSpace, endianness: .big)
                result.append(("thread-pcs", beBuffer.hexDump(format: .compact)))
                var leBuffer = self.allocator.buffer(capacity: 8)
                leBuffer.writeInteger(pcInHostAddressSpace, endianness: .little)
                result.append(("00", leBuffer.hexDump(format: .compact)))
            }

            return .keyValuePairs(result)
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
                responseKind = self.currentThreadStopInfo

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

                let binaryOffset = Int(address - codeOffset)

                if binaryOffset + length > wasmBinary.readableBytes {
                    length = wasmBinary.readableBytes - binaryOffset
                }

                responseKind = .hexEncodedBinary(wasmBinary.readableBytesView[binaryOffset..<(binaryOffset + length)])

            case .wasmCallStack:
                let callStack = self.debugger.currentCallStack
                var buffer = self.allocator.buffer(capacity: callStack.count * 8)
                for pc in callStack {
                    buffer.writeInteger(UInt64(pc) + codeOffset, endianness: .little)
                }
                responseKind = .hexEncodedBinary(buffer.readableBytesView)

            case .resumeThreads:
                guard !self.hasSteppedBefore else { fatalError() }

                // TODO: support multiple threads each with its own action here.
                let threadActions = command.arguments.components(separatedBy: ":")
                guard threadActions.count == 2, let threadActionString = threadActions.first else {
                    throw Error.multipleThreadsNotSupported
                }

                guard let threadAction = ResumeThreadsAction(rawValue: threadActionString) else {
                    throw Error.unknownThreadAction(threadActionString)
                }

                try self.debugger.step()
                self.hasSteppedBefore = true

                responseKind = self.currentThreadStopInfo

            case .generalRegisters:
                throw Error.hostCommandNotImplemented(command.kind)
            }

            logger.trace("handler produced a response", metadata: ["GDBTargetResponse": .string("\(responseKind)")])

            return .init(kind: responseKind, isNoAckModeActive: isNoAckModeActive)
        }
    }

#endif
