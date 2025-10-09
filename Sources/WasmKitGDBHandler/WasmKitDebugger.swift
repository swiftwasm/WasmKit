import GDBRemoteProtocol
import Logging
import SystemPackage
import WasmKit

package actor WasmKitDebugger {
    /// Whether `QStartNoAckMode` command was previously sent.
    private var isNoAckModeActive = false

    private let module: Module
    private let logger: Logger

    package init(logger: Logger, moduleFilePath: FilePath) throws {
        self.logger = logger
        self.module = try parseWasm(filePath: moduleFilePath)
    }

    package func handle(command: GDBHostCommand) -> GDBTargetResponse {
        let responseKind: GDBTargetResponse.Kind
        logger.trace("handling GDB host command", metadata: ["GDBHostCommand": .string(command.kind.rawValue)])

        responseKind = switch command.kind {
        case .startNoAckMode, .isThreadSuffixSupported, .listThreadsInStopReply:
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
            // FIXME: should return a different set of supported features instead of echoing.
            .raw(command.arguments)

        case .vContSupportedActions:
            .vContSupportedActions([.continue, .step, .stop])

        case .isVAttachOrWaitSupported, .enableErrorStrings:
            .empty
        case .processInfo:
            .raw("pid:1;parent-pid:1;arch:wasm32;endian:little;ptrsize:4;")

        case .currentThreadID:
            .raw("QC1")

        case .firstThreadInfo:
            .raw("m1")

        case .subsequentThreadInfo:
            .raw("l")

        case .generalRegisters:
            fatalError()
        }

        defer {
            if command.kind == .startNoAckMode {
                self.isNoAckModeActive = true
            }
        }
        return .init(kind: responseKind, isNoAckModeActive: self.isNoAckModeActive)
    }

}
