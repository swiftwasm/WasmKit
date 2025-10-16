import GDBRemoteProtocol
import Logging
import Synchronization
import SystemPackage
import WasmKit

package actor WasmKitGDBHandler {
    enum Error: Swift.Error {
        case unknownTransferArguments
    }

    private let module: Module
    private let moduleFilePath: FilePath
    private let logger: Logger
    private let debuggerExecution: DebuggerExecution
    private let instance: Instance

    package init(logger: Logger, moduleFilePath: FilePath) throws {
        self.logger = logger
        self.module = try parseWasm(filePath: moduleFilePath)
        self.moduleFilePath = moduleFilePath
        let store = Store(engine: Engine())
        self.debuggerExecution = DebuggerExecution(store: store)
        self.instance = try module.instantiate(store: store)
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
            responseKind = .raw("qXfer:libraries:read+;PacketSize=1000;")

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
            responseKind = .raw("QC1")

        case .firstThreadInfo:
            responseKind = .raw("m1")

        case .subsequentThreadInfo:
            responseKind = .raw("l")

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
                responseKind = .raw("E45")
            }

        case .transfer:
            if command.arguments.starts(with: "libraries:read:") {
                responseKind = .raw(
                    """
                    l<library-list>
                        <library name="\(self.moduleFilePath.string)"><section address="0x4000000000000000"/></library>
                    </library-list>
                    """)
            } else {
                throw Error.unknownTransferArguments
            }

        case .readMemory:
            responseKind = .empty

        case .wasmCallStack:
            print(self.debuggerExecution.captureBacktrace())
            responseKind = .empty

        case .generalRegisters:
            fatalError()
        }

        logger.trace("handler produced a response", metadata: ["GDBTargetResponse": .string("\(responseKind)")])

        return .init(kind: responseKind, isNoAckModeActivated: isNoAckModeActivated)
    }

}
