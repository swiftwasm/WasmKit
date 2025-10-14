//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2025 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import GDBRemoteProtocol
import Logging
import NIOCore
import NIOPosix
import SystemPackage
import WasmKitGDBHandler

@main
struct Entrypoint: AsyncParsableCommand {
    @Option(help: "TCP port that a debugger can connect to")
    var port = 8080

    @Option(
        name: .shortAndLong,
        transform: { stringValue in
            guard let logLevel = Logger.Level(rawValue: stringValue.lowercased()) else {
                throw ValidationError("not a valid log level: \(stringValue)")
            }
            return logLevel
        }
    )
    var logLevel = Logger.Level.info

    @Argument(transform: { FilePath($0) })
    var wasmModulePath: FilePath

    func run() async throws {
        let logger = {
            var result = Logger(label: "org.swiftwasm.WasmKit")
            result.logLevel = self.logLevel
            return result
        }()

        try await MultiThreadedEventLoopGroup.withEventLoopGroup(numberOfThreads: System.coreCount) { group in
            let bootstrap = ServerBootstrap(group: group)
                // Specify backlog and enable SO_REUSEADDR for the server itself
                .serverChannelOption(.backlog, value: 256)
                .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)

                // Set the handlers that are applied to the accepted child `Channel`s.
                .childChannelInitializer { channel in
                    // Ensure we don't read faster then we can write by adding the BackPressureHandler into the pipeline.
                    channel.eventLoop.makeCompletedFuture {
                        try channel.pipeline.syncOperations.addHandler(BackPressureHandler())
                        // make sure to instantiate your `ChannelHandlers` inside of
                        // the closure as it will be invoked once per connection.
                        try channel.pipeline.syncOperations.addHandlers([
                            ByteToMessageHandler(GDBHostCommandDecoder(logger: logger)),
                            MessageToByteHandler(GDBTargetResponseEncoder()),
                        ])
                    }
                }

                // Enable SO_REUSEADDR for the accepted Channels
                .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
                .childChannelOption(.maxMessagesPerRead, value: 16)
                .childChannelOption(.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

            let serverChannel = try await bootstrap.bind(host: "127.0.0.1", port: port) { childChannel in
                childChannel.eventLoop.makeCompletedFuture {
                    try NIOAsyncChannel<GDBPacket<GDBHostCommand>, GDBTargetResponse>(
                        wrappingChannelSynchronously: childChannel
                    )
                }
            }
            /* the server will now be accepting connections */
            logger.info("listening on port \(port)")

            let debugger = try WasmKitDebugger(logger: logger, moduleFilePath: self.wasmModulePath)

            try await withThrowingDiscardingTaskGroup { group in
                try await serverChannel.executeThenClose { serverChannelInbound in
                    for try await connectionChannel in serverChannelInbound {
                        group.addTask {
                            do {
                                try await connectionChannel.executeThenClose { connectionChannelInbound, connectionChannelOutbound in
                                    for try await inboundData in connectionChannelInbound {
                                        // Let's echo back all inbound data
                                        try await connectionChannelOutbound.write(debugger.handle(command: inboundData.payload))
                                    }
                                }
                            } catch {
                                logger.error("Error in GDB remote protocol connection channel", metadata: ["error": "\(error)"])
                            }
                        }
                    }
                }
            }
        }
    }
}
