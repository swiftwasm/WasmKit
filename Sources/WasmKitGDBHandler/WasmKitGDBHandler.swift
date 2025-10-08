import GDBRemoteProtocol
import NIOCore
import WasmKit

import struct Foundation.Date

package final class WasmKitGDBHandler: ChannelInboundHandler {
    package typealias InboundIn = GDBPacket<GDBHostCommand>
    package typealias OutboundOut = GDBTargetResponse

    /// Whether `QStartNoAckMode` command was previously sent.
    private var isNoAckModeActive = false

    package init() {}

    package func channelRead(
        context: ChannelHandlerContext,
        data: NIOAny
    ) {
        let command = self.unwrapInboundIn(data).payload
        let responseKind: GDBTargetResponse.Kind
        print(command.kind)

        switch command.kind {
        case .startNoAckMode, .isThreadSuffixSupported, .listThreadsInStopReply:
            responseKind = .ok

        case .hostInfo:
            responseKind = .hostInfo([
                "arch": "wasm32",
                "ptrsize": "4",
                "endian": "little",
                "ostype": "wasip1",
                "vendor": "WasmKit",
            ])

        case .supportedFeatures:
            responseKind = .raw(command.arguments)

        case .vContSupportedActions:
            responseKind = .vContSupportedActions([.continue, .step, .stop])

        case .isVAttachOrWaitSupported, .enableErrorStrings, .processInfo:
            responseKind = .empty

        case .currentThreadID:
            responseKind = .raw("QC 1")

        case .generalRegisters, .firstThreadInfo:
            fatalError()
        }

        context.writeAndFlush(
            wrapOutboundOut(.init(kind: responseKind, isNoAckModeActive: self.isNoAckModeActive)),
            promise: nil
        )
        if command.kind == .startNoAckMode {
            self.isNoAckModeActive = true
        }
    }

    package func channelReadComplete(
        context: ChannelHandlerContext
    ) {
        context.flush()
    }

    package func errorCaught(
        context: ChannelHandlerContext,
        error: Error
    ) {
        print(error)

        context.close(promise: nil)
    }
}
