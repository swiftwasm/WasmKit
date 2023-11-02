import Foundation

extension FileManager {
    internal func isDirectory(filePath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: filePath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
