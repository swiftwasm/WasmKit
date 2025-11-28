import SystemPackage

/// Base protocol for all file system nodes in memory.
protocol MemFSNode: AnyObject {
    var type: MemFSNodeType { get }
}

/// Types of file system nodes.
enum MemFSNodeType {
    case directory
    case file
    case characterDevice
}

/// A directory node in the memory file system.
final class MemoryDirectoryNode: MemFSNode {
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
final class MemoryFileNode: MemFSNode {
    let type: MemFSNodeType = .file
    var content: FileContent

    init(content: FileContent) {
        self.content = content
    }

    convenience init(bytes: some Sequence<UInt8>) {
        self.init(content: .bytes(Array(bytes)))
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
final class MemoryCharacterDeviceNode: MemFSNode {
    let type: MemFSNodeType = .characterDevice

    enum Kind {
        case null
    }

    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
    }
}

/// A WASIFile implementation for character devices like /dev/null
final class MemoryCharacterDeviceEntry: WASIFile {
    let deviceNode: MemoryCharacterDeviceNode
    let accessMode: FileAccessMode

    init(deviceNode: MemoryCharacterDeviceNode, accessMode: FileAccessMode) {
        self.deviceNode = deviceNode
        self.accessMode = accessMode
    }

    // MARK: - WASIEntry

    func attributes() throws -> WASIAbi.Filestat {
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .CHARACTER_DEVICE,
            nlink: 1, size: 0,
            atim: 0, mtim: 0, ctim: 0
        )
    }

    func fileType() throws -> WASIAbi.FileType {
        return .CHARACTER_DEVICE
    }

    func status() throws -> WASIAbi.Fdflags {
        return []
    }

    func setTimes(
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws {
        // No-op for character devices
    }

    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice
    ) throws {
        // No-op for character devices
    }

    func close() throws {
        // No-op for character devices
    }

    // MARK: - WASIFile

    func fdStat() throws -> WASIAbi.FdStat {
        var fsRightsBase: WASIAbi.Rights = []
        if accessMode.contains(.read) {
            fsRightsBase.insert(.FD_READ)
        }
        if accessMode.contains(.write) {
            fsRightsBase.insert(.FD_WRITE)
        }

        return WASIAbi.FdStat(
            fsFileType: .CHARACTER_DEVICE,
            fsFlags: [],
            fsRightsBase: fsRightsBase,
            fsRightsInheriting: []
        )
    }

    func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws {
        // No-op for character devices
    }

    func setFilestatSize(_ size: WASIAbi.FileSize) throws {
        throw WASIAbi.Errno.EINVAL
    }

    func sync() throws {
        // No-op for character devices
    }

    func datasync() throws {
        // No-op for character devices
    }

    func tell() throws -> WASIAbi.FileSize {
        return 0
    }

    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
        throw WASIAbi.Errno.ESPIPE
    }

    func write<Buffer: Sequence>(vectored buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }

        switch deviceNode.kind {
        case .null:
            // /dev/null discards all writes but reports them as successful
            var totalBytes: UInt32 = 0
            for iovec in buffer {
                iovec.withHostBufferPointer { bufferPtr in
                    totalBytes += UInt32(bufferPtr.count)
                }
            }
            return totalBytes
        }
    }

    func pwrite<Buffer: Sequence>(vectored buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        throw WASIAbi.Errno.ESPIPE
    }

    func read<Buffer: Sequence>(into buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.read) else {
            throw WASIAbi.Errno.EBADF
        }

        switch deviceNode.kind {
        case .null:
            // /dev/null always returns EOF (0 bytes read)
            return 0
        }
    }

    func pread<Buffer: Sequence>(into buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        throw WASIAbi.Errno.ESPIPE
    }
}
