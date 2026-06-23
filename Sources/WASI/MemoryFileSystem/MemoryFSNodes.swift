import Synchronization
import SystemExtras
import SystemPackage
import WasmTypes

/// Base protocol for file system nodes.
///
/// Each node guards its own state, so a reference can be shared across concurrent
/// file descriptors without a single global lock.
protocol MemFSNode: AnyObject, Sendable {
    var type: MemFSNodeType { get }
}

/// Types of file system nodes.
enum MemFSNodeType {
    case directory
    case file
    case characterDevice
}

/// A directory node.
///
/// Timestamp bumps are inlined into each mutating method rather than delegated to
/// a locking helper, since the lock is non-reentrant.
package final class MemoryDirectoryNode: MemFSNode {
    let type: MemFSNodeType = .directory

    private struct State {
        var children: [String: MemFSNode] = [:]
        var atim: WASIAbi.Timestamp
        var mtim: WASIAbi.Timestamp
        var ctim: WASIAbi.Timestamp
    }

    private let state: Mutex<State>

    init() {
        let now = WASIAbi.Timestamp.currentWallClock()
        self.state = Mutex(State(atim: now, mtim: now, ctim: now))
    }

    var timestamps: (atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp, ctim: WASIAbi.Timestamp) {
        state.withLock { ($0.atim, $0.mtim, $0.ctim) }
    }

    func setTimes(atim: WASIAbi.Timestamp?, mtim: WASIAbi.Timestamp?) {
        state.withLock { s in
            if let atim { s.atim = atim }
            if let mtim { s.mtim = mtim }
            s.ctim = WASIAbi.Timestamp.currentWallClock()
        }
    }

    func getChild(name: String) -> MemFSNode? {
        state.withLock { $0.children[name] }
    }

    func setChild(name: String, node: MemFSNode) {
        state.withLock { s in
            s.children[name] = node
            let now = WASIAbi.Timestamp.currentWallClock()
            s.mtim = now
            s.ctim = now
        }
    }

    @discardableResult
    func removeChild(name: String) -> Bool {
        state.withLock { s in
            guard s.children.removeValue(forKey: name) != nil else { return false }
            let now = WASIAbi.Timestamp.currentWallClock()
            s.mtim = now
            s.ctim = now
            return true
        }
    }

    /// Returns the existing child directory `name`, creating one if absent.
    /// Throws `ENOTDIR` if a non-directory already occupies the name.
    func getOrCreateChildDirectory(name: String) throws -> MemoryDirectoryNode {
        try state.withLock { s in
            if let existing = s.children[name] {
                guard let dir = existing as? MemoryDirectoryNode else {
                    throw WASIAbi.Errno.ENOTDIR
                }
                return dir
            }
            let dir = MemoryDirectoryNode()
            s.children[name] = dir
            let now = WASIAbi.Timestamp.currentWallClock()
            s.mtim = now
            s.ctim = now
            return dir
        }
    }

    /// Returns the existing regular file `name`, creating an empty one if absent.
    /// Throws `EISDIR` if a directory already occupies the name.
    func getOrCreateChildFile(name: String) throws -> MemoryFileNode {
        try state.withLock { s in
            if let existing = s.children[name] {
                guard let file = existing as? MemoryFileNode else {
                    throw WASIAbi.Errno.EISDIR
                }
                return file
            }
            let file = MemoryFileNode(bytes: [])
            s.children[name] = file
            let now = WASIAbi.Timestamp.currentWallClock()
            s.mtim = now
            s.ctim = now
            return file
        }
    }

    func listChildren() -> [String] {
        state.withLock { s in
            s.atim = WASIAbi.Timestamp.currentWallClock()
            return s.children.keys.sorted()
        }
    }

    func childCount() -> Int {
        state.withLock { $0.children.count }
    }
}

/// A regular file node.
///
/// `.bytes` reads and writes run under the node lock; `.handle` IO extracts the
/// descriptor under the lock and runs the syscall outside it.
final class MemoryFileNode: MemFSNode {
    let type: MemFSNodeType = .file

    private struct State {
        var content: FileContent
        var atim: WASIAbi.Timestamp
        var mtim: WASIAbi.Timestamp
        var ctim: WASIAbi.Timestamp
    }

    private let state: Mutex<State>

    init(content: FileContent) {
        let now = WASIAbi.Timestamp.currentWallClock()
        self.state = Mutex(State(content: content, atim: now, mtim: now, ctim: now))
    }

    convenience init(bytes: some Sequence<UInt8>) {
        self.init(content: .bytes(Array(bytes)))
    }

    convenience init(handle: FileDescriptor) {
        self.init(content: .handle(handle))
    }

    /// A snapshot of the current content. `.bytes` copies the array; `.handle`
    /// returns the descriptor.
    var content: FileContent {
        state.withLock { $0.content }
    }

    /// The host descriptor for a `.handle`-backed file, or nil for an in-memory file.
    var handle: FileDescriptor? {
        state.withLock { if case .handle(let fd) = $0.content { return fd }; return nil }
    }

    var size: Int {
        get throws {
            let content = state.withLock { $0.content }
            switch content {
            case .bytes(let bytes):
                return bytes.count
            case .handle(let fd):
                return Int(try fd.attributes().size)
            }
        }
    }

    var timestamps: (atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp, ctim: WASIAbi.Timestamp) {
        get throws {
            let snapshot = state.withLock { (content: $0.content, atim: $0.atim, mtim: $0.mtim, ctim: $0.ctim) }
            switch snapshot.content {
            case .bytes:
                return (snapshot.atim, snapshot.mtim, snapshot.ctim)
            case .handle(let fd):
                let attrs = try fd.attributes()
                return (
                    WASIAbi.Timestamp(platformTimeSpec: attrs.accessTime),
                    WASIAbi.Timestamp(platformTimeSpec: attrs.modificationTime),
                    WASIAbi.Timestamp(platformTimeSpec: attrs.creationTime)
                )
            }
        }
    }

    /// Resets a `.bytes` file to empty content (used for `O_TRUNC`). No-op for `.handle`.
    func truncateToEmpty() {
        state.withLock { s in
            guard case .bytes = s.content else { return }
            s.content = .bytes([])
            let now = WASIAbi.Timestamp.currentWallClock()
            s.mtim = now
            s.ctim = now
        }
    }

    /// Sets in-memory times on a `.bytes` file; returns the host descriptor for a
    /// `.handle` file so the caller applies the change with a syscall outside the lock.
    func setTimesInMemory(atim: WASIAbi.Timestamp?, mtim: WASIAbi.Timestamp?) -> FileDescriptor? {
        state.withLock { s in
            if case .handle(let fd) = s.content { return fd }
            if let atim { s.atim = atim }
            if let mtim { s.mtim = mtim }
            s.ctim = WASIAbi.Timestamp.currentWallClock()
            return nil
        }
    }

    /// Truncates or extends a `.bytes` file; calls `truncate` on the host descriptor
    /// for a `.handle` file outside the lock.
    func setFilestatSize(_ size: WASIAbi.FileSize) throws {
        let handle: FileDescriptor? = state.withLock { s in
            switch s.content {
            case .bytes(var bytes):
                let newSize = Int(size)
                if newSize < bytes.count {
                    bytes = Array(bytes.prefix(newSize))
                } else if newSize > bytes.count {
                    bytes.append(contentsOf: Array(repeating: 0, count: newSize - bytes.count))
                }
                s.content = .bytes(bytes)
                let now = WASIAbi.Timestamp.currentWallClock()
                s.mtim = now
                s.ctim = now
                return nil
            case .handle(let fd):
                return fd
            }
        }
        if let handle { try handle.truncate(size: Int64(size)) }
    }

    /// The byte count of a `.bytes` file, or the host descriptor for a `.handle` file
    /// (so the caller can seek on it directly).
    func seekPrep() -> (byteCount: Int, handle: FileDescriptor?) {
        state.withLock { s in
            switch s.content {
            case .bytes(let bytes): return (bytes.count, nil)
            case .handle(let fd): return (0, fd)
            }
        }
    }

    func read<M: GuestMemory, Buffer: Sequence>(
        into buffer: Buffer, memory: M, position: Int
    ) throws -> (count: WASIAbi.Size, newPosition: Int) where Buffer.Element == WASIAbi.IOVec {
        let (count, newPosition, handle): (WASIAbi.Size, Int, FileDescriptor?) = state.withLock { s in
            switch s.content {
            case .bytes(let bytes):
                var cur = position
                var total: UInt32 = 0
                for iovec in buffer {
                    iovec.withHostBufferPointer(in: memory) { bufferPtr in
                        let available = max(0, bytes.count - cur)
                        let toRead = min(bufferPtr.count, available)
                        guard toRead > 0 else { return }
                        bytes.withUnsafeBytes { contentBytes in
                            bufferPtr.baseAddress!.copyMemory(
                                from: contentBytes.baseAddress!.advanced(by: cur), byteCount: toRead)
                        }
                        cur += toRead
                        total += UInt32(toRead)
                    }
                }
                s.atim = WASIAbi.Timestamp.currentWallClock()
                return (total, cur, nil)
            case .handle(let fd):
                return (0, position, fd)
            }
        }
        guard let handle else { return (count, newPosition) }
        var currentOffset = Int64(position)
        var total: UInt32 = 0
        for iovec in buffer {
            let nread = try iovec.withHostBufferPointer(in: memory) { bufferPtr in
                try handle.read(fromAbsoluteOffset: currentOffset, into: bufferPtr)
            }
            currentOffset += Int64(nread)
            total += UInt32(nread)
        }
        return (total, Int(currentOffset))
    }

    func pread<M: GuestMemory, Buffer: Sequence>(
        into buffer: Buffer, memory: M, offset: Int
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        let (count, handle): (WASIAbi.Size, FileDescriptor?) = state.withLock { s in
            switch s.content {
            case .bytes(let bytes):
                var cur = offset
                var total: UInt32 = 0
                for iovec in buffer {
                    iovec.withHostBufferPointer(in: memory) { bufferPtr in
                        let available = max(0, bytes.count - cur)
                        let toRead = min(bufferPtr.count, available)
                        guard toRead > 0 else { return }
                        bytes.withUnsafeBytes { contentBytes in
                            bufferPtr.baseAddress!.copyMemory(
                                from: contentBytes.baseAddress!.advanced(by: cur), byteCount: toRead)
                        }
                        cur += toRead
                        total += UInt32(toRead)
                    }
                }
                s.atim = WASIAbi.Timestamp.currentWallClock()
                return (total, nil)
            case .handle(let fd):
                return (0, fd)
            }
        }
        guard let handle else { return count }
        var currentOffset = Int64(offset)
        var total: UInt32 = 0
        for iovec in buffer {
            let nread = try iovec.withHostBufferPointer(in: memory) { bufferPtr in
                try handle.read(fromAbsoluteOffset: currentOffset, into: bufferPtr)
            }
            currentOffset += Int64(nread)
            total += UInt32(nread)
        }
        return total
    }

    func write<M: GuestMemory, Buffer: Sequence>(
        vectored buffer: Buffer, memory: M, position: Int
    ) throws -> (count: WASIAbi.Size, newPosition: Int) where Buffer.Element == WASIAbi.IOVec {
        let (count, newPosition, handle): (WASIAbi.Size, Int, FileDescriptor?) = state.withLock { s in
            switch s.content {
            case .bytes(var bytes):
                var cur = position
                var total: UInt32 = 0
                for iovec in buffer {
                    iovec.withHostBufferPointer(in: memory) { bufferPtr in
                        let bytesToWrite = bufferPtr.count
                        let requiredSize = cur + bytesToWrite
                        if requiredSize > bytes.count {
                            bytes.append(contentsOf: Array(repeating: 0, count: requiredSize - bytes.count))
                        }
                        bytes.replaceSubrange(cur..<(cur + bytesToWrite), with: bufferPtr)
                        cur += bytesToWrite
                        total += UInt32(bytesToWrite)
                    }
                }
                s.content = .bytes(bytes)
                let now = WASIAbi.Timestamp.currentWallClock()
                s.mtim = now
                s.ctim = now
                return (total, cur, nil)
            case .handle(let fd):
                return (0, position, fd)
            }
        }
        guard let handle else { return (count, newPosition) }
        var currentOffset = Int64(position)
        var total: UInt32 = 0
        for iovec in buffer {
            let nwritten = try iovec.withHostBufferPointer(in: memory) { bufferPtr in
                try handle.writeAll(toAbsoluteOffset: currentOffset, bufferPtr)
            }
            currentOffset += Int64(nwritten)
            total += UInt32(nwritten)
        }
        return (total, Int(currentOffset))
    }

    func pwrite<M: GuestMemory, Buffer: Sequence>(
        vectored buffer: Buffer, memory: M, offset: Int
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        let (count, handle): (WASIAbi.Size, FileDescriptor?) = state.withLock { s in
            switch s.content {
            case .bytes(var bytes):
                var cur = offset
                var total: UInt32 = 0
                for iovec in buffer {
                    iovec.withHostBufferPointer(in: memory) { bufferPtr in
                        let bytesToWrite = bufferPtr.count
                        let requiredSize = cur + bytesToWrite
                        if requiredSize > bytes.count {
                            bytes.append(contentsOf: Array(repeating: 0, count: requiredSize - bytes.count))
                        }
                        bytes.replaceSubrange(cur..<(cur + bytesToWrite), with: bufferPtr)
                        cur += bytesToWrite
                        total += UInt32(bytesToWrite)
                    }
                }
                s.content = .bytes(bytes)
                let now = WASIAbi.Timestamp.currentWallClock()
                s.mtim = now
                s.ctim = now
                return (total, nil)
            case .handle(let fd):
                return (0, fd)
            }
        }
        guard let handle else { return count }
        var currentOffset = Int64(offset)
        var total: UInt32 = 0
        for iovec in buffer {
            let nwritten = try iovec.withHostBufferPointer(in: memory) { bufferPtr in
                try handle.writeAll(toAbsoluteOffset: currentOffset, bufferPtr)
            }
            currentOffset += Int64(nwritten)
            total += UInt32(nwritten)
        }
        return total
    }
}

/// A character device node.
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

    func write<M: GuestMemory, Buffer: Sequence>(vectored buffer: Buffer, memory: M) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }

        switch deviceNode.kind {
        case .null:
            var totalBytes: UInt32 = 0
            for iovec in buffer {
                iovec.withHostBufferPointer(in: memory) { bufferPtr in
                    totalBytes += UInt32(bufferPtr.count)
                }
            }
            return totalBytes
        }
    }

    func pwrite<M: GuestMemory, Buffer: Sequence>(vectored buffer: Buffer, memory: M, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        throw WASIAbi.Errno.ESPIPE
    }

    func read<M: GuestMemory, Buffer: Sequence>(into buffer: Buffer, memory: M) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.read) else {
            throw WASIAbi.Errno.EBADF
        }

        switch deviceNode.kind {
        case .null:
            return 0
        }
    }

    func pread<M: GuestMemory, Buffer: Sequence>(into buffer: Buffer, memory: M, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        throw WASIAbi.Errno.ESPIPE
    }
}
