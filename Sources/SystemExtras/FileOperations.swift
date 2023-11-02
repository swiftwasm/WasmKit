#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#elseif os(Windows)
import ucrt
#else
#error("Unsupported Platform")
#endif

import SystemPackage

extension FileDescriptor {
  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

  /// Announces an intention to read specific region of file data.
  ///
  /// - Parameters:
  ///   - offset: The offset to the starting point of the region.
  ///   - length: The length of the region.
  ///
  /// The corresponding C function is `fcntl` with `F_RDADVISE` command.
  @_alwaysEmitIntoClient
  public func adviseRead(offset: Int64, length: Int32) throws {
    try _adviseRead(offset: offset, length: length).get()
  }

  @usableFromInline
  internal func _adviseRead(offset: Int64, length: Int32) -> Result<Void, Errno> {
    var radvisory = radvisory(ra_offset: offset, ra_count: length)
    return withUnsafeMutablePointer(to: &radvisory) { radvisoryPtr in
      nothingOrErrno(retryOnInterrupt: false) {
        system_fcntl(self.rawValue, F_RDADVISE, radvisoryPtr)
      }
    }
  }
  #endif

  /// The advisory for specific access pattern to file data.
  @frozen
  public struct Advice: RawRepresentable, Hashable, Codable {
    public var rawValue: CInt

    /// Creates a strongly-typed advice from a raw C access mode.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    #if os(Linux)
    /// Access the specified data in the near future.
    ///
    /// The corresponding C constant is `POSIX_FADV_WILLNEED`.
    @_alwaysEmitIntoClient
    public static var willNeed: Advice { Advice(rawValue: POSIX_FADV_WILLNEED) }
    #endif
  }

  #if os(Linux)
  /// Announces an intention to access specific region of file data.
  ///
  /// - Parameters:
  ///   - offset: The offset to the starting point of the region.
  ///   - length: The length of the region.
  ///   - advice: The advisory for the access pattern.
  ///
  /// The corresponding C function is `posix_fadvise`.
  @_alwaysEmitIntoClient
  public func advise(offset: Int, length: Int, advice: Advice) throws {
    try _advise(offset: offset, length: length, advice: advice).get()
  }

  @usableFromInline
  internal func _advise(offset: Int, length: Int, advice: Advice) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_posix_fadvise(self.rawValue, offset, length, advice.rawValue)
    }
  }
  #endif

  /// A structure representing type of file.
  ///
  /// Typically created from `st_mode & S_IFMT`.
  @frozen
  public struct FileType: RawRepresentable {
    /// The raw C file type.
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.Mode

    /// Creates a strongly-typed file type from a raw C file type.
    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.Mode) {
      self.rawValue = rawValue
    }

    public static var directory: FileType { FileType(rawValue: _S_IFDIR) }

    public static var symlink: FileType { FileType(rawValue: _S_IFLNK) }

    public static var file: FileType { FileType(rawValue: _S_IFREG) }

    public static var characterDevice: FileType { FileType(rawValue: _S_IFCHR) }

    public static var blockDevice: FileType { FileType(rawValue: _S_IFBLK) }

    public static var socket: FileType { FileType(rawValue: _S_IFSOCK) }

    public static var unknown: FileType { FileType(rawValue: _S_IFMT) }

    /// A Boolean value indicating whether this file type represents a directory file.
    @_alwaysEmitIntoClient
    public var isDirectory: Bool {
      _is(_S_IFDIR)
    }

    /// A Boolean value indicating whether this file type represents a symbolic link.
    @_alwaysEmitIntoClient
    public var isSymlink: Bool {
      _is(_S_IFLNK)
    }

    /// A Boolean value indicating whether this file type represents a regular file.
    @_alwaysEmitIntoClient
    public var isFile: Bool {
      _is(_S_IFREG)
    }

    /// A Boolean value indicating whether this file type represents a character-oriented device file.
    @_alwaysEmitIntoClient
    public var isCharacterDevice: Bool {
      _is(_S_IFCHR)
    }

    /// A Boolean value indicating whether this file type represents a block-oriented device file.
    @_alwaysEmitIntoClient
    public var isBlockDevice: Bool {
      _is(_S_IFBLK)
    }

    /// A Boolean value indicating whether this file type represents a socket.
    @_alwaysEmitIntoClient
    public var isSocket: Bool {
      _is(_S_IFSOCK)
    }

    @_alwaysEmitIntoClient
    internal func _is(_ mode: CInterop.Mode) -> Bool {
      rawValue == mode
    }
  }

  /// A metadata information about a file.
  ///
  /// The corresponding C struct is `stat`.
  @frozen
  public struct Attributes: RawRepresentable {
    /// The raw C file metadata structure.
    @_alwaysEmitIntoClient
    public let rawValue: stat

    /// Creates a strongly-typed file type from a raw C file metadata structure.
    @_alwaysEmitIntoClient
    public init(rawValue: stat) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public var device: UInt64 {
      UInt64(rawValue.st_dev)
    }

    @_alwaysEmitIntoClient
    public var inode: UInt64 {
      UInt64(rawValue.st_ino)
    }

    /// Returns the file type for this metadata.
    @_alwaysEmitIntoClient
    public var fileType: FileType {
      FileType(rawValue: self.rawValue.st_mode & S_IFMT)
    }

    @_alwaysEmitIntoClient
    public var linkCount: UInt32 {
      UInt32(rawValue.st_nlink)
    }

    @_alwaysEmitIntoClient
    public var size: Int64 {
      Int64(rawValue.st_size)
    }

    @_alwaysEmitIntoClient
    public var accessTime: Clock.TimeSpec {
      #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      Clock.TimeSpec(rawValue: self.rawValue.st_atimespec)
      #else
      Clock.TimeSpec(rawValue: self.rawValue.st_atim)
      #endif
    }

    @_alwaysEmitIntoClient
    public var modificationTime: Clock.TimeSpec {
      #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      Clock.TimeSpec(rawValue: self.rawValue.st_mtimespec)
      #else
      Clock.TimeSpec(rawValue: self.rawValue.st_mtim)
      #endif
    }

    @_alwaysEmitIntoClient
    public var creationTime: Clock.TimeSpec {
      #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      Clock.TimeSpec(rawValue: self.rawValue.st_ctimespec)
      #else
      Clock.TimeSpec(rawValue: self.rawValue.st_ctim)
      #endif
    }
  }

  /// Queries the metadata about the file
  ///
  /// - Returns: The attributes of the file
  ///
  /// The corresponding C function is `fstat`.
  @_alwaysEmitIntoClient
  public func attributes() throws -> Attributes {
    try _attributes().get()
  }

  @usableFromInline
  internal func _attributes() -> Result<Attributes, Errno> {
    var stat: stat = stat()
    return nothingOrErrno(retryOnInterrupt: false) {
      system_fstat(self.rawValue, &stat)
    }
    .map { Attributes(rawValue: stat) }
  }

  /// Queries the current status of the file descriptor.
  ///
  /// - Returns: The file descriptor's access mode and status.
  ///
  /// The corresponding C function is `fcntl` with `F_GETFL` command.
  @_alwaysEmitIntoClient
  public func status() throws -> OpenOptions {
    try _status().get()
  }

  @usableFromInline
  internal func _status() -> Result<OpenOptions, Errno> {
    valueOrErrno(retryOnInterrupt: false) {
      system_fcntl(self.rawValue, _F_GETFL)
    }
    .map { OpenOptions(rawValue: $0) }
  }

  @_alwaysEmitIntoClient
  public func setStatus(_ options: OpenOptions) throws {
    try _setStatus(options).get()
  }

  @usableFromInline
  internal func _setStatus(_ options: OpenOptions) -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_fcntl(self.rawValue, F_SETFL, options.rawValue)
    }
  }

  @_alwaysEmitIntoClient
  public func setTimes(
    access: Clock.TimeSpec = .omit, modification: Clock.TimeSpec = .omit
  ) throws {
    try _setTime(access: access, modification: modification).get()
  }

  @usableFromInline
  internal func _setTime(access: Clock.TimeSpec, modification: Clock.TimeSpec) -> Result<(), Errno> {
    let times = ContiguousArray([access.rawValue, modification.rawValue])
    return times.withUnsafeBufferPointer { timesPtr in
      nothingOrErrno(retryOnInterrupt: false) {
        system_futimens(self.rawValue, timesPtr.baseAddress!)
      }
    }
  }

  @_alwaysEmitIntoClient
  public func truncate(size: Int64) throws {
    try _truncate(size: size).get()
  }

  @usableFromInline
  internal func _truncate(size: Int64) -> Result<(), Errno> {
    return nothingOrErrno(retryOnInterrupt: false) {
      system_ftruncate(self.rawValue, off_t(size))
    }
  }

  public struct DirectoryEntry: RawRepresentable {
    @_alwaysEmitIntoClient
    public var rawValue: UnsafeMutablePointer<dirent>

    @_alwaysEmitIntoClient
    public init(rawValue: UnsafeMutablePointer<dirent>) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public var name: String {
      withUnsafePointer(to: &rawValue.pointee.d_name) { dName in
        dName.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: dName)) {
          // String initializer copies the given buffer contents, so it's safe.
          return String(cString: $0)
        }
      }
    }

    public var fileType: FileType {
      switch CInt(rawValue.pointee.d_type) {
      case _DT_REG: return .file
      case _DT_BLK: return .blockDevice
      case _DT_CHR: return .characterDevice
      case _DT_DIR: return .directory
      case _DT_LNK: return .symlink
      case _DT_SOCK: return .socket
      default: return .unknown
      }
    }
  }

  public struct DirectoryStream: RawRepresentable, IteratorProtocol, Sequence {
    @_alwaysEmitIntoClient
    public let rawValue: CInterop.DirP

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.DirP) {
      self.rawValue = rawValue
    }

    public func next() -> Result<DirectoryEntry, Errno>? {
      // https://man7.org/linux/man-pages/man3/readdir.3.html#RETURN_VALUE
      // > If the end of the directory stream is reached, NULL is returned
      // > and errno is not changed.  If an error occurs, NULL is returned
      // > and errno is set to indicate the error.  To distinguish end of
      // > stream from an error, set errno to zero before calling readdir()
      // > and then check the value of errno if NULL is returned.
      system_errno = 0
      if let dirent = system_readdir(rawValue) {
        return .success(DirectoryEntry(rawValue: dirent))
      } else {
        let currentErrno = system_errno
        if currentErrno == 0 {
            // We successfully reached the end of the stream.
            return nil
        } else {
            return .failure(Errno(rawValue: currentErrno))
        }
      }
    }
  }

  public func contentsOfDirectory() throws -> DirectoryStream {
    return try _contentsOfDirectory().get()
  }

  internal func _contentsOfDirectory() -> Result<DirectoryStream, Errno> {
    guard let dirp = system_fdopendir(self.rawValue) else {
      return .failure(Errno(rawValue: system_errno))
    }
    return .success(DirectoryStream(rawValue: dirp))
  }
}

// MARK: - Synchronized Input and Output

extension FileDescriptor.OpenOptions {
  @_alwaysEmitIntoClient
  public static var dataSync: FileDescriptor.OpenOptions {
    FileDescriptor.OpenOptions(rawValue: _O_DSYNC)
  }

  @_alwaysEmitIntoClient
  public static var fileSync: FileDescriptor.OpenOptions {
    FileDescriptor.OpenOptions(rawValue: _O_SYNC)
  }

  #if os(Linux)
  @_alwaysEmitIntoClient
  public static var readSync: FileDescriptor.OpenOptions {
    FileDescriptor.OpenOptions(rawValue: _O_RSYNC)
  }
  #endif
}
