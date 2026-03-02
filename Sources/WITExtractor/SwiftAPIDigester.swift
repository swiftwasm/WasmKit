import Foundation

/// A wrapper for the swift-api-digester tool.
struct SwiftAPIDigester {
    /// The path to `swift-api-digester` executable in the toolchain
    let executableURL: URL

    init(executableURL: URL) {
        self.executableURL = executableURL
    }

    struct Output: Decodable {
        let ABIRoot: SDKNode

        static func parse(_ bytes: Data) throws -> Output {
            let decoder = JSONDecoder()
            return try decoder.decode(Output.self, from: bytes)
        }
    }

    struct SDKNodeInherit<Parent: Decodable, Body: Decodable>: Decodable {
        let parent: Parent
        let body: Body

        init(from decoder: Decoder) throws {
            self.parent = try Parent(from: decoder)
            self.body = try Body(from: decoder)
        }
    }

    enum SDKNode: Decodable {
        case root(SDKNodeRoot)
        case decl(SDKNodeDecl)
        case typeDecl(SDKNodeDeclType)
        case typeNominal(SDKNodeTypeNominal)
        case unknown(SDKNodeBody)

        var body: SDKNodeBody {
            switch self {
            case .root(let node): return node.parent
            case .decl(let node): return node.parent
            case .typeDecl(let node): return node.parent.parent
            case .typeNominal(let node): return node.parent.parent
            case .unknown(let node): return node
            }
        }

        var decl: SDKNodeDecl? {
            switch self {
            case .root: return nil
            case .decl(let node): return node
            case .typeDecl(let node): return node.parent
            case .typeNominal: return nil
            case .unknown: return nil
            }
        }

        enum CodingKeys: CodingKey {
            case kind
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            switch try container.decode(String.self, forKey: .kind) {
            case "Root":
                self = try .root(SDKNodeRoot(from: decoder))
            case "TypeDecl":
                self = try .typeDecl(SDKNodeDeclType(from: decoder))
            case "TypeNominal":
                self = try .typeNominal(SDKNodeTypeNominal(from: decoder))
            case "Var", "Function":
                self = try .decl(SDKNodeDecl(from: decoder))
            default:
                self = try .unknown(SwiftAPIDigester.SDKNodeBody(from: decoder))
            }
        }
    }

    struct SDKNodeBody: Decodable {
        let kind: String
        let name: String
        let printedName: String
        let children: [SDKNode]?

        enum CodingKeys: CodingKey {
            case kind
            case name
            case printedName
            case children
        }
    }

    typealias SDKNodeRoot = SDKNodeInherit<SDKNodeBody, SDKNodeRootBody>
    struct SDKNodeRootBody: Codable {
        let json_format_version: Int
    }

    struct SDKNodeDeclBody: Codable {
        let declKind: String
        let usr: String
        let mangledName: String
        let moduleName: String
        let declAttributes: [String]?
        let spi_group_names: [String]?
        let `static`: Bool?
    }

    struct SDKNodeDeclTypeBody: Codable {}
    struct SDKNodeTypeBody: Codable {}
    struct SDKNodeTypeNominalBody: Codable {
        let usr: String?
    }

    typealias SDKNodeDecl = SDKNodeInherit<SDKNodeBody, SDKNodeDeclBody>
    typealias SDKNodeDeclType = SDKNodeInherit<SDKNodeDecl, SDKNodeDeclTypeBody>
    typealias SDKNodeType = SDKNodeInherit<SDKNodeBody, SDKNodeTypeBody>
    typealias SDKNodeTypeNominal = SDKNodeInherit<SDKNodeType, SDKNodeTypeNominalBody>

    @available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    func dumpSDK(moduleName: String, arguments: [String]) throws -> Output {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS) || os(WASI)
            fatalError("WITExtractor does not support platforms where Foundation.Process is unavailable")
        #else
            var args = [
                "-dump-sdk",
                "-module", moduleName,
                // Emit output to stdout
                "-o", "-",
            ]
            args += arguments
            let process = Process()
            process.executableURL = executableURL
            process.arguments = args
            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            try process.run()
            guard let output = try stdoutPipe.fileHandleForReading.readToEnd() else {
                throw SwiftAPIDigesterError.unexpectedEmptyOutput
            }
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw SwiftAPIDigesterError.nonZeroExitCode(process.terminationStatus, arguments: args)
            }
            return try Output.parse(output)
        #endif
    }
}

enum SwiftAPIDigesterError: Error {
    case unexpectedEmptyOutput
    case nonZeroExitCode(Int32, arguments: [String])
}
