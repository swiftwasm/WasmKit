import WASI

package struct WASIConfiguration: Sendable {
    package let arguments: [String]
    package let environment: [String: String]
    package let preopens: [WASIBridgeToHost.Preopen]

    package init(
        arguments: [String],
        environment: [String: String],
        preopens: [WASIBridgeToHost.Preopen]
    ) {
        self.arguments = arguments
        self.environment = environment
        self.preopens = preopens
    }
}

extension WASIBridgeToHost {
    package convenience init(configuration: WASIConfiguration) throws {
        try self.init(
            args: configuration.arguments,
            environment: configuration.environment,
            preopens: configuration.preopens
        )
    }
}
