import ArgumentParser
import GDBRemoteProtocol
import NIOCore
import NIOPosix
import WasmKitGDBHandler

@main
struct Entrypoint: ParsableCommand {
    @Option(help: "TCP port that a debugger can connect to")
    var port = 8080

    func run() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
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
                        ByteToMessageHandler(GDBHostCommandDecoder()),
                        MessageToByteHandler(GDBTargetResponseEncoder()),
                        WasmKitHandler(),
                    ])
                }
            }

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 16)
            .childChannelOption(.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        let channel = try bootstrap.bind(host: "127.0.0.1", port: port).wait()
        /* the server will now be accepting connections */
        print("listening on port \(port)")

        try channel.closeFuture.wait()  // wait forever as we never close the Channel
        try group.syncShutdownGracefully()
    }
}
