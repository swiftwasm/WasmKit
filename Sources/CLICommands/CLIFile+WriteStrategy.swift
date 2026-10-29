import Foundation

extension CLIFile {
    enum WriteStrategy {
        case inPlace
        case replaceExisting
        case create

        init(path: String) throws {
            // `fileExists` follows symlinks; `attributesOfItem` does not.
            guard FileManager.default.fileExists(atPath: path) else {
                self = .create
                return
            }
            let type = try FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType
            self = type == .typeRegular ? .replaceExisting : .inPlace
        }
    }
}
