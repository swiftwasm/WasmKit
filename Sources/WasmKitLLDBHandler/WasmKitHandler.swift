import LLDBRemoteProtocol
import NIOCore
import WasmKit

import struct Foundation.Date

package final class WasmKitHandler: ChannelInboundHandler {
    package typealias InboundIn = Packet<HostCommand>
    package typealias OutboundOut = TargetResponse

    /// Whether `QStartNoAckMode` command was previously sent.
    private var isNoAckModeActive = false

    package init() {}

    package func channelRead(
        context: ChannelHandlerContext,
        data: NIOAny
    ) {
        let command = self.unwrapInboundIn(data).payload
        let responseKind: TargetResponse.Kind
        print(command.kind)

        switch command.kind {
        case .startNoAckMode, .isThreadSuffixSupported, .listThreadsInStopReply:
            responseKind = .ok
        case .supportedFeatures:
            responseKind = .raw(command.arguments)
        default:
            fatalError()
        }

        context.writeAndFlush(
            wrapOutboundOut(.init(kind: responseKind, isNoAckModeActive: self.isNoAckModeActive)),
            promise: nil)
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
