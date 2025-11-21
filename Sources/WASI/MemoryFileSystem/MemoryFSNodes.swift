import SystemPackage

/// Base protocol for all file system nodes in memory.
internal protocol MemFSNode: AnyObject {
    var type: MemFSNodeType { get }
}

/// Types of file system nodes.
internal enum MemFSNodeType {
    case directory
    case file
    case characterDevice
}

/// A directory node in the memory file system.
internal final class MemoryDirectoryNode: MemFSNode {
    let type: MemFSNodeType = .directory
    private var children: [String: MemFSNode] = [:]
    
    init() {}
    
    func getChild(name: String) -> MemFSNode? {
        return children[name]
    }
    
    func setChild(name: String, node: MemFSNode) {
        children[name] = node
    }
    
    @discardableResult
    func removeChild(name: String) -> Bool {
        return children.removeValue(forKey: name) != nil
    }
    
    func listChildren() -> [String] {
        return Array(children.keys).sorted()
    }
    
    func childCount() -> Int {
        return children.count
    }
}

/// A regular file node in the memory file system.
internal final class MemoryFileNode: MemFSNode {
    let type: MemFSNodeType = .file
    var content: FileContent
    
    init(content: FileContent) {
        self.content = content
    }
    
    convenience init(bytes: [UInt8]) {
        self.init(content: .bytes(bytes))
    }
    
    convenience init(handle: FileDescriptor) {
        self.init(content: .handle(handle))
    }
    
    var size: Int {
        switch content {
        case .bytes(let bytes):
            return bytes.count
        case .handle(let fd):
            do {
                let attrs = try fd.attributes()
                return Int(attrs.size)
            } catch {
                return 0
            }
        }
    }
}

/// A character device node in the memory file system.
internal final class MemoryCharacterDeviceNode: MemFSNode {
    let type: MemFSNodeType = .characterDevice
    
    enum Kind {
        case null
    }
    
    let kind: Kind
    
    init(kind: Kind) {
        self.kind = kind
    }
}