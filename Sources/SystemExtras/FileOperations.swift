#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#elseif canImport(Android)
import CSystem
import Android
#elseif os(Windows)
import ucrt
import WinSDK
#else
#error("Unsupported Platform")
#endif

import SystemPackage

extension FileDescriptor {
  #if SYSTEM_PACKAGE_DARWIN

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

    #if os(Linux) || os(Android)
    /// Access the specified data in the near future.
    ///
    /// The corresponding C constant is `POSIX_FADV_WILLNEED`.
    @_alwaysEmitIntoClient
    public static var willNeed: Advice { Advice(rawValue: POSIX_FADV_WILLNEED) }
    #endif
  }

  #if os(Linux) || os(Android)
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
    #if os(Windows)
    /// The raw Windows file type derived from `dwFileAttributes`.
    @_alwaysEmitIntoClient
    public var rawValue: DWORD

    /// Creates a strongly-typed file type from a raw Windows file type.
    @_alwaysEmitIntoClient
    public init(rawValue: DWORD) {
      self.rawValue = rawValue
    }

    /// A Boolean value indicating whether this file type represents a directory file.
    @_alwaysEmitIntoClient
    public var isDirectory: Bool {
      rawValue == DWORD(FILE_ATTRIBUTE_DIRECTORY)
    }

    #else
    /// The raw C file type.
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.Mode

    /// Creates a strongly-typed file type from a raw C file type.
    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.Mode) {
      self.rawValue = rawValue
    }

    public static var directory: FileType { FileType(rawValue: _S_IFDIR) }

    #if !os(Windows)
    public static var symlink: FileType { FileType(rawValue: _S_IFLNK) }

    public static var blockDevice: FileType { FileType(rawValue: _S_IFBLK) }

    public static var socket: FileType { FileType(rawValue: _S_IFSOCK) }
    #endif

    public static var file: FileType { FileType(rawValue: _S_IFREG) }

    public static var characterDevice: FileType { FileType(rawValue: _S_IFCHR) }

    public static var unknown: FileType { FileType(rawValue: _S_IFMT) }

    /// A Boolean value indicating whether this file type represents a directory file.
    @_alwaysEmitIntoClient
    public var isDirectory: Bool {
      _is(_S_IFDIR)
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

    #if !os(Windows)
    /// A Boolean value indicating whether this file type represents a symbolic link.
    @_alwaysEmitIntoClient
    public var isSymlink: Bool {
      _is(_S_IFLNK)
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
    #endif

    @_alwaysEmitIntoClient
    internal func _is(_ mode: CInterop.Mode) -> Bool {
      rawValue == mode
    }
    #endif
  }

  /// A metadata information about a file.
  ///
  /// The corresponding C struct is `stat`.
  @frozen
  public struct Attributes: RawRepresentable {
    #if os(Windows)
    /// The raw Windows file metadata structure.
    @_alwaysEmitIntoClient
    public var rawValue: BY_HANDLE_FILE_INFORMATION

    /// Creates a strongly-typed file type from a raw Windows file metadata structure.
    @_alwaysEmitIntoClient
    public init(rawValue: BY_HANDLE_FILE_INFORMATION) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public var device: UInt64 {
      UInt64(rawValue.dwVolumeSerialNumber)
    }

    @_alwaysEmitIntoClient
    public var inode: UInt64 {
      UInt64(rawValue.nFileIndexHigh) << 32 | UInt64(rawValue.nFileIndexLow)
    }

    @_alwaysEmitIntoClient
    public var fileType: FileType {
      return FileType(rawValue: rawValue.dwFileAttributes)
    }

    @_alwaysEmitIntoClient
    public var linkCount: UInt32 {
      rawValue.nNumberOfLinks
    }

    @_alwaysEmitIntoClient
    public var size: Int64 {
      Int64(rawValue.nFileSizeHigh) << 32 | Int64(rawValue.nFileSizeLow)
    }

    @_alwaysEmitIntoClient
    public var accessTime: FileTime {
      FileTime(rawValue: rawValue.ftLastAccessTime)
    }

    @_alwaysEmitIntoClient
    public var modificationTime: FileTime {
      FileTime(rawValue: rawValue.ftLastWriteTime)
    }

    @_alwaysEmitIntoClient
    public var creationTime: FileTime {
      FileTime(rawValue: rawValue.ftCreationTime)
    }

    #else
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
      #if SYSTEM_PACKAGE_DARWIN
      Clock.TimeSpec(rawValue: self.rawValue.st_atimespec)
      #else
      Clock.TimeSpec(rawValue: self.rawValue.st_atim)
      #endif
    }

    @_alwaysEmitIntoClient
    public var modificationTime: Clock.TimeSpec {
      #if SYSTEM_PACKAGE_DARWIN
      Clock.TimeSpec(rawValue: self.rawValue.st_mtimespec)
      #else
      Clock.TimeSpec(rawValue: self.rawValue.st_mtim)
      #endif
    }

    @_alwaysEmitIntoClient
    public var creationTime: Clock.TimeSpec {
      #if SYSTEM_PACKAGE_DARWIN
      Clock.TimeSpec(rawValue: self.rawValue.st_ctimespec)
      #else
      Clock.TimeSpec(rawValue: self.rawValue.st_ctim)
      #endif
    }
    #endif
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
    #if os(Windows)
    var info = BY_HANDLE_FILE_INFORMATION()
    let handle = HANDLE(bitPattern: _get_osfhandle(self.rawValue))
    return nothingOrErrno(retryOnInterrupt: false) {
      let ok = GetFileInformationByHandle(handle, &info)
      return ok ? 0 : -1
    }
    .map { Attributes(rawValue: info) }
    #else
    var stat: stat = stat()
    return nothingOrErrno(retryOnInterrupt: false) {
      system_fstat(self.rawValue, &stat)
    }
    .map { Attributes(rawValue: stat) }
    #endif
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
    #if os(Windows)
    // FIXME: Need to query by `NtQueryInformationFile`?
    return .success(OpenOptions(rawValue: 0))
    #else
    valueOrErrno(retryOnInterrupt: false) {
      system_fcntl(self.rawValue, _F_GETFL)
    }
    .map { OpenOptions(rawValue: $0) }
    #endif
  }

  @_alwaysEmitIntoClient
  public func setStatus(_ options: OpenOptions) throws {
    try _setStatus(options).get()
  }

  @usableFromInline
  internal func _setStatus(_ options: OpenOptions) -> Result<(), Errno> {
    #if os(Windows)
    // FIXME: Re-open the file with new options?
    return .success(())
    #else
    nothingOrErrno(retryOnInterrupt: false) {
      system_fcntl(self.rawValue, F_SETFL, options.rawValue)
    }
    #endif
  }

  @_alwaysEmitIntoClient
  public func setTimes(
    access: FileTime = .omit, modification: FileTime = .omit
  ) throws {
    try _setTime(access: access, modification: modification).get()
  }

  @usableFromInline
  internal func _setTime(access: FileTime, modification: FileTime) -> Result<(), Errno> {
    #if os(Windows)
    let handle = HANDLE(bitPattern: _get_osfhandle(self.rawValue))
    return nothingOrErrno(retryOnInterrupt: false) {
      let ok: Bool
      var nowCache: FILETIME?
      let atime: FILETIME?
      switch access {
      case .now:
        var now = FILETIME()
        GetSystemTimeAsFileTime(&now)
        nowCache = now
        atime = now
      case .absolute(let time):
        atime = time
      case .omit:
        atime = nil
      }

      let mtime: FILETIME?
      switch modification {
      case .now:
        if let now = nowCache {
          mtime = now
        } else {
          var now = FILETIME()
          GetSystemTimeAsFileTime(&now)
          mtime = now
        }
      case .absolute(let time):
        mtime = time
      case .omit:
        mtime = nil
      }

      switch (atime, mtime) {
      case (nil, nil):
        ok = true
      case (.some(let atime), nil):
        ok = withUnsafePointer(to: atime) { atimePtr in
          SetFileTime(handle, nil, atimePtr, nil)
        }
      case (nil, .some(let mtime)):
        ok = withUnsafePointer(to: mtime) { mtimePtr in
          SetFileTime(handle, nil, nil, mtimePtr)
        }
      case (.some(let atime), .some(let mtime)):
        ok = withUnsafePointer(to: atime) { atimePtr in
          withUnsafePointer(to: mtime) { mtimePtr in
            SetFileTime(handle, nil, atimePtr, mtimePtr)
          }
        }
      }
      return ok ? 0 : -1
    }
    #else
    let times = ContiguousArray([access.rawValue, modification.rawValue])
    return times.withUnsafeBufferPointer { timesPtr in
      nothingOrErrno(retryOnInterrupt: false) {
        system_futimens(self.rawValue, timesPtr.baseAddress!)
      }
    }
    #endif
  }

  @_alwaysEmitIntoClient
  public func truncate(size: Int64) throws {
    try _truncate(size: size).get()
  }

  #if os(Windows)
  @usableFromInline
  internal func _truncate(size: Int64) -> Result<(), Errno> {
    return nothingOrErrno(retryOnInterrupt: false) {
      var info = FILE_END_OF_FILE_INFO()
      info.EndOfFile.QuadPart = size
      let handle = HANDLE(bitPattern: _get_osfhandle(self.rawValue))
      let ok = SetFileInformationByHandle(handle, FileEndOfFileInfo, &info, DWORD(MemoryLayout.size(ofValue: info)))
      return ok ? 0 : -1
    }
  }
  #else
  @usableFromInline
  internal func _truncate(size: Int64) -> Result<(), Errno> {
    return nothingOrErrno(retryOnInterrupt: false) {
      system_ftruncate(self.rawValue, off_t(size))
    }
  }
  #endif

  #if os(Windows)
  public struct DirectoryEntry {
    public var data: WIN32_FIND_DATAW

    public var name: String {
      withUnsafePointer(to: data.cFileName) { cFileName in
        cFileName.withMemoryRebound(to: UInt16.self, capacity: Int(MAX_PATH) * MemoryLayout<WCHAR>.size) {
          // String initializer copies the given buffer contents, so it's safe.
          return String(decodingCString: $0, as: UTF16.self)
        }
      }
    }

    public var fileType: FileType {
      return FileType(rawValue: data.dwFileAttributes)
    }
  }

  public struct DirectoryStream: RawRepresentable, IteratorProtocol, Sequence {
    public var rawValue: HANDLE

    public init(rawValue: HANDLE) {
      self.rawValue = rawValue
    }

    public func next() -> Result<DirectoryEntry, Errno>? {
      // TODO: Implement by `FindNextFileW`?
      return .failure(Errno(rawValue: ERROR_NOT_SUPPORTED))
    }
  }

  #else

  public struct DirectoryEntry {
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
  #endif

  public func contentsOfDirectory() throws -> DirectoryStream {
    return try _contentsOfDirectory().get()
  }

  internal func _contentsOfDirectory() -> Result<DirectoryStream, Errno> {
    #if os(Windows)
    // TODO: Implement by `FindFirstFileW`?
    return .failure(Errno(rawValue: ERROR_NOT_SUPPORTED))
    #else
    guard let dirp = system_fdopendir(self.rawValue) else {
      return .failure(Errno(rawValue: system_errno))
    }
    return .success(DirectoryStream(rawValue: dirp))
    #endif
  }

  public func sync() throws {
    return try _sync().get()
  }

  internal func _sync() -> Result<Void, Errno> {
    #if os(Windows)
    let handle = HANDLE(bitPattern: _get_osfhandle(self.rawValue))
    return nothingOrErrno(retryOnInterrupt: false) {
      let ok = FlushFileBuffers(handle)
      return ok ? 0 : -1
    }
    #else
    nothingOrErrno(retryOnInterrupt: false) {
      #if SYSTEM_PACKAGE_DARWIN
      system_fcntl(self.rawValue, F_FULLFSYNC)
      #else
      system_fsync(self.rawValue)
      #endif
    }
    #endif
  }

  public func datasync() throws {
    return try _datasync().get()
  }

  internal func _datasync() -> Result<Void, Errno> {
    #if os(Windows)
    return self._sync()
    #else
    nothingOrErrno(retryOnInterrupt: false) {
      #if SYSTEM_PACKAGE_DARWIN
      system_fcntl(self.rawValue, F_FULLFSYNC)
      #elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android) || os(Cygwin) || os(PS4)
      system_fdatasync(self.rawValue)
      #else
      system_fsync(self.rawValue)
      #endif
    }
    #endif
  }
}

#if os(Windows)
public enum FileTime {
  case omit
  case now
  case absolute(FILETIME)

  @_alwaysEmitIntoClient
  public var unixNanoseconds: Int64 {
    guard case let .absolute(rawValue) = self else { return 0 }
    let ntNanoseconds = (Int64(rawValue.dwHighDateTime) << 32) | Int64(rawValue.dwLowDateTime)
    return ntNanoseconds - Self.unixEpochNanoseconds
  }

  @_alwaysEmitIntoClient
  public static var unixEpochNanoseconds: Int64 {
    return 11644473600 * 1_000_000
  }

  public init(rawValue: FILETIME) {
    self = .absolute(rawValue)
  }

  public init(seconds: Int, nanoseconds: Int) {
    let fileTime: Int64 = Int64(seconds) * 1_000_000_000 + Int64(nanoseconds) + Self.unixEpochNanoseconds
    self = .absolute(FILETIME(
      dwLowDateTime: DWORD(fileTime & 0xFFFF_FFFF),
      dwHighDateTime: DWORD(fileTime >> 32)
    ))
  }
}
#else
public typealias FileTime = Clock.TimeSpec
#endif

#if !os(Windows)

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

#endif
