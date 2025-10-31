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

#if WasmDebuggingSupport

    import GDBRemoteProtocol
    import Logging
    import NIOCore
    import NIOPosix
    import SystemPackage
    import WasmKit
    import WasmKitGDBHandler

    struct DebuggerServer {
        var host = "127.0.0.1"
        var port: Int
        var logLevel = Logger.Level.info
        let wasmModulePath: FilePath
        let engineConfiguration: EngineConfiguration

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
                                MessageToByteHandler(GDBTargetResponseEncoder(logger: logger)),
                            ])
                        }
                    }

                    // Enable SO_REUSEADDR for the accepted Channels
                    .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
                    .childChannelOption(.maxMessagesPerRead, value: 16)
                    .childChannelOption(.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

                let serverChannel = try await bootstrap.bind(host: self.host, port: self.port) { childChannel in
                    childChannel.eventLoop.makeCompletedFuture {
                        try NIOAsyncChannel<GDBPacket<GDBHostCommand>, GDBTargetResponse>(
                            wrappingChannelSynchronously: childChannel
                        )
                    }
                }
                /* the server will now be accepting connections */
                logger.info("Debugger server listening on port \(port)")

                let debuggerHandler = try await WasmKitGDBHandler(
                    moduleFilePath: self.wasmModulePath,
                    engineConfiguration: self.engineConfiguration,
                    logger: logger,
                    allocator: serverChannel.channel.allocator
                )

                // Discarding task group was designed for persistent server purposes, where a single failing request
                // isn't taking down the entire server. In our case we need to be able to shut down the server on
                // debugger client's request, so let's wrap the discarding task group with a throwing task group
                // for cancellation.
                try await withThrowingTaskGroup { cancellableGroup in
                    // Use `AsyncStream` for sending a signal out of the discarding group.
                    let (shutDownStream, shutDownContinuation) = AsyncStream<()>.makeStream()

                    cancellableGroup.addTask {
                        try await withThrowingDiscardingTaskGroup { discardingGroup in
                            try await serverChannel.executeThenClose { serverChannelInbound in
                                for try await connectionChannel in serverChannelInbound {
                                    discardingGroup.addTask {
                                        do {
                                            try await connectionChannel.executeThenClose { connectionChannelInbound, connectionChannelOutbound in
                                                for try await inboundData in connectionChannelInbound {
                                                    try await connectionChannelOutbound.write(debuggerHandler.handle(command: inboundData.payload))
                                                }
                                            }
                                        } catch WasmKitGDBHandler.Error.killRequestReceived {
                                            logger.info("Debugger shut down request received")
                                            shutDownContinuation.yield()
                                        } catch {
                                            logger.error("Error in GDB remote protocol connection channel", metadata: ["error": "\(error)"])
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // The stream isn't really sending data, just a single type of empty signal, wait for the first one.
                    await shutDownStream.first { _ in true }
                    cancellableGroup.cancelAll()
                }
            }
        }
    }

#endif
