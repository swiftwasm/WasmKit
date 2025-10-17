#if WasmDebuggingSupport

    import GDBRemoteProtocol
    import Logging
    import NIOCore
    import NIOFileSystem
    import Synchronization
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

    package actor WasmKitGDBHandler {
        enum Error: Swift.Error {
            case unknownTransferArguments
            case unknownReadMemoryArguments
            case entrypointFunctionNotFound
        }

        private let wasmBinary: ByteBuffer
        private let module: Module
        private let moduleFilePath: FilePath
        private let logger: Logger
        private let debugger: Debugger
        private let instance: Instance
        private let entrypointFunction: Function
        private let functionsRLE: [(wasmAddress: Int, iSeqAddress: Int)] = []

        package init(logger: Logger, moduleFilePath: FilePath) async throws {
            self.logger = logger

            self.wasmBinary = try await FileSystem.shared.withFileHandle(forReadingAt: moduleFilePath) {
                try await $0.readToEnd(maximumSizeAllowed: .unlimited)
            }

            self.module = try parseWasm(bytes: .init(buffer: self.wasmBinary))
            self.moduleFilePath = moduleFilePath
            let store = Store(engine: Engine())
            self.debugger = Debugger(store: store)

            var imports = Imports()
            let wasi = try WASIBridgeToHost()
            wasi.link(to: &imports, store: store)
            self.instance = try module.instantiate(store: store, imports: imports)

            guard case .function(let entrypointFunction) = self.instance.exports["_start"] else {
                throw Error.entrypointFunctionNotFound
            }
            self.entrypointFunction = entrypointFunction
        }

        package func handle(command: GDBHostCommand) throws -> GDBTargetResponse {
            let responseKind: GDBTargetResponse.Kind
            logger.trace("handling GDB host command", metadata: ["GDBHostCommand": .string(command.kind.rawValue)])

            var isNoAckModeActivated = false
            switch command.kind {
            case .startNoAckMode:
                isNoAckModeActivated = true
                fallthrough

            case .isThreadSuffixSupported, .listThreadsInStopReply:
                responseKind = .ok

            case .hostInfo:
                responseKind = .keyValuePairs([
                    "arch": "wasm32",
                    "ptrsize": "4",
                    "endian": "little",
                    "ostype": "wasip1",
                    "vendor": "WasmKit",
                ])

            case .supportedFeatures:
                responseKind = .string("qXfer:libraries:read+;PacketSize=1000;")

            case .vContSupportedActions:
                responseKind = .vContSupportedActions([.continue, .step])

            case .isVAttachOrWaitSupported, .enableErrorStrings, .structuredDataPlugins, .readMemoryBinaryData:
                responseKind = .empty

            case .processInfo:
                responseKind = .keyValuePairs([
                    "pid": "1",
                    "parent-pid": "1",
                    "arch": "wasm32",
                    "endian": "little",
                    "ptrsize": "4",
                ])

            case .currentThreadID:
                responseKind = .string("QC1")

            case .firstThreadInfo:
                responseKind = .string("m1")

            case .subsequentThreadInfo:
                responseKind = .string("l")

            case .targetStatus:
                responseKind = .keyValuePairs([
                    "T05thread": "1",
                    "reason": "trace",
                ])

            case .registerInfo:
                if command.arguments == "0" {
                    responseKind = .keyValuePairs([
                        "name": "pc",
                        "bitsize": "64",
                        "offset": "0",
                        "encoding": "uint",
                        "format": "hex",
                        "set": "General Purpose Registers",
                        "gcc": "16",
                        "dwarf": "16",
                        "generic": "pc",
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

                let binaryOffset = Int(address - 0x4000_0000_0000_0000)

                if binaryOffset + length > wasmBinary.readableBytes {
                    length = wasmBinary.readableBytes - binaryOffset
                }

                responseKind = .hexEncodedBinary(wasmBinary.readableBytesView[binaryOffset..<(binaryOffset + length)])

            case .wasmCallStack:
                print(self.debugger.captureBacktrace())
                responseKind = .empty

            case .generalRegisters:
                fatalError()
            }

            logger.trace("handler produced a response", metadata: ["GDBTargetResponse": .string("\(responseKind)")])

            return .init(kind: responseKind, isNoAckModeActivated: isNoAckModeActivated)
        }

    }

#endif
