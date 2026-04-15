import WasmTypes

/// An error type thrown during WAT (WebAssembly Text Format) parsing.
public struct WatParserError: Swift.Error {
    public let message: String
    public let location: Location?

    package init(_ message: String, location: Location?) {
        self.message = message
        self.location = location
    }
}

extension WatParserError: CustomStringConvertible {
    public var description: String {
        if let location {
            return "\(message) at \(location)"
        }
        return message
    }
}
