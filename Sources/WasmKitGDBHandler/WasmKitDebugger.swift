import GDBRemoteProtocol
import Logging
import Synchronization
import SystemPackage
import WasmKit

package actor WasmKitDebugger {
    private let module: Module
    private let logger: Logger

    package init(logger: Logger, moduleFilePath: FilePath) throws {
        self.logger = logger
        self.module = try parseWasm(filePath: moduleFilePath)
    }

    package func handle(command: GDBHostCommand) -> GDBTargetResponse {
        let responseKind: GDBTargetResponse.Kind
        logger.trace("handling GDB host command", metadata: ["GDBHostCommand": .string(command.kind.rawValue)])

        var isNoAckModeActivated = false
        responseKind =
            switch command.kind {
            case .startNoAckMode:
                isNoAckModeActivated = true
                fallthrough

            case .isThreadSuffixSupported, .listThreadsInStopReply:
                .ok

            case .hostInfo:
                .keyValuePairs([
                    "arch": "wasm32",
                    "ptrsize": "4",
                    "endian": "little",
                    "ostype": "wasip1",
                    "vendor": "WasmKit",
                ])

            case .supportedFeatures:
                .raw("qXfer:libraries:read+;PacketSize=1000;")

            case .vContSupportedActions:
                .vContSupportedActions([.continue, .step])

            case .isVAttachOrWaitSupported, .enableErrorStrings:
                .empty
            case .processInfo:
                .keyValuePairs([
                    "pid": "1",
                    "parent-pid": "1",
                    "arch": "wasm32",
                    "endian": "little",
                    "ptrsize": "4",
                ])

            case .currentThreadID:
                .raw("QC1")

            case .firstThreadInfo:
                .raw("m1")

            case .subsequentThreadInfo:
                .raw("l")

            case .targetStatus:
                .keyValuePairs([
                    "T05thread": "1",
                    "reason": "trace",
                ])

            case .registerInfo:
                if command.arguments == "0" {
                    .keyValuePairs([
                        "name": "pc",
                        "bitsize": "64",
                        "offset": "0",
                        "encoding": "uint",
                        "format": "hex",
                        "set": "General Purpose Registers",
                        "gcc": "16",
                        "dwarf": "16",
                        "generic": "pc"
                    ])
                } else {
                    .raw("E45")
                }

            case .generalRegisters:
                fatalError()
            }

        logger.trace("handler produced a response", metadata: ["GDBTargetResponse": .string("\(responseKind)")])

        return .init(kind: responseKind, isNoAckModeActivated: isNoAckModeActivated)
    }

}
