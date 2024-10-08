#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#elseif os(Windows)
import ucrt
import WinSDK
#else
#error("Unsupported Platform")
#endif

import SystemPackage

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FileDescriptor {
  /// Options for use with `*at` functions like `openAt`
  /// Each function defines which option values are valid with it
  @frozen
  public struct AtOptions: OptionSet {
    /// The raw C options.
    @_alwaysEmitIntoClient
    public var rawValue: Int32

    /// Create a strongly-typed options value from raw C options.
    @_alwaysEmitIntoClient
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    #if !os(Windows)
    /// Indicates the operation does't follow symlinks
    ///
    /// If you specify this option and the file you pass to
    /// <doc:SystemPackage/FileDescriptor/attributes(at:options:)-803zm>
    /// is a symbolic link, then it returns information about the link itself.
    ///
    /// The corresponding C constant is `AT_SYMLINK_NOFOLLOW`.
    @_alwaysEmitIntoClient
    public static var noFollow: AtOptions { AtOptions(rawValue: _AT_SYMLINK_NOFOLLOW) }
    #endif

    /* FIXME: Disabled until CSystem will include "linux/fcntl.h"
    #if os(Linux)
    /// Indicates the operation does't mount the basename component automatically
    ///
    /// If you specify this option and the file you pass to
    /// <doc:SystemPackage/FileDescriptor/attributes(at:options:)-803zm>
    /// is a auto-mount point, it does't mount the directory even if it's an auto-mount point.
    ///
    /// The corresponding C constant is `AT_NO_AUTOMOUNT`.
    @_alwaysEmitIntoClient
    public static var noAutomount: AtOptions { AtOptions(rawValue: _AT_NO_AUTOMOUNT)}
    #endif
    */

    #if !os(Windows)
    /// Indicates the operation removes directory
    ///
    /// If you specify this option and the file path you pass to
    /// <doc:SystemPackage/FileDescriptor/remove(at:options:)-1y194>
    /// is not a directory, then that remove operation fails.
    ///
    /// The corresponding C constant is `AT_REMOVEDIR`.
    @_alwaysEmitIntoClient
    public static var removeDirectory: AtOptions { AtOptions(rawValue: _AT_REMOVEDIR) }
    #endif
  }

  /// Opens or creates a file relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the file to open.
  ///   - mode: The read and write access to use.
  ///   - options: The behavior for opening the file.
  ///   - permissions: The file permissions to use for created files.
  ///   - retryOnInterrupt: Whether to retry the open operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A file descriptor for the open file
  ///
  /// The corresponding C function is `openat`.
  @_alwaysEmitIntoClient
  public func open(
    at path: FilePath,
    _ mode: FileDescriptor.AccessMode,
    options: FileDescriptor.OpenOptions,
    permissions: FilePermissions? = nil,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor {
    try path.withPlatformString {
      try open(
        at: $0, mode, options: options, permissions: permissions, retryOnInterrupt: retryOnInterrupt)
    }
  }

  /// Opens or creates a file relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the file to open.
  ///   - mode: The read and write access to use.
  ///   - options: The behavior for opening the file.
  ///   - permissions: The file permissions to use for created files.
  ///   - retryOnInterrupt: Whether to retry the open operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A file descriptor for the open file
  ///
  /// The corresponding C function is `openat`.
  @_alwaysEmitIntoClient
  public func open(
    at path: UnsafePointer<CInterop.PlatformChar>,
    _ mode: FileDescriptor.AccessMode,
    options: FileDescriptor.OpenOptions,
    permissions: FilePermissions? = nil,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor {
    try _open(
      at: path, mode, options: options, permissions: permissions, retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _open(
    at path: UnsafePointer<CInterop.PlatformChar>,
    _ mode: FileDescriptor.AccessMode,
    options: FileDescriptor.OpenOptions,
    permissions: FilePermissions?,
    retryOnInterrupt: Bool
  ) -> Result<FileDescriptor, Errno> {
    #if os(Windows)
    return .failure(Errno(rawValue: ERROR_NOT_SUPPORTED))
    #else
    let oFlag = mode.rawValue | options.rawValue
    let descOrError: Result<CInt, Errno> = valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      if let permissions = permissions {
        return system_openat(self.rawValue, path, oFlag, permissions.rawValue)
      }
      precondition(!options.contains(.create),
                   "Create must be given permissions")
      return system_openat(self.rawValue, path, oFlag)
    }
    return descOrError.map { FileDescriptor(rawValue: $0) }
    #endif
  }

  /// Returns attributes information about a file relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the file to retrieve attributes.
  ///   - options: The behavior for retrieving attributes. Available options are:
  ///       - <doc:SystemPackage/FileDescriptor/AtOptions/noFollow>
  /// - Returns: A set of attributes about the specified file.
  ///
  /// The corresponding C function is `fstatat`.
  @_alwaysEmitIntoClient
  public func attributes(at path: FilePath, options: AtOptions) throws -> Attributes {
    try path.withPlatformString { _attributes(at: $0, options: options) }.get()
  }

  /// Returns attributes information about a file relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the file to retrieve attributes.
  ///   - options: The behavior for retrieving attributes. Available options are:
  ///       - <doc:SystemPackage/FileDescriptor/AtOptions/noFollow>
  /// - Returns: A set of attributes about the specified file.
  ///
  /// The corresponding C function is `fstatat`.
  @_alwaysEmitIntoClient
  public func attributes(at path: UnsafePointer<CInterop.PlatformChar>, options: AtOptions) throws -> Attributes {
    try _attributes(at: path, options: options).get()
  }

  @usableFromInline
  internal func _attributes(at path: UnsafePointer<CInterop.PlatformChar>, options: AtOptions) -> Result<Attributes, Errno> {
    #if os(Windows)
    return .failure(Errno(rawValue: ERROR_NOT_SUPPORTED))
    #else
    var stat: stat = stat()
    return nothingOrErrno(retryOnInterrupt: false) {
      system_fstatat(self.rawValue, path, &stat, options.rawValue)
    }
    .map { Attributes(rawValue: stat) }
    #endif
  }

  /// Remove a file entry relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the directory to remove.
  ///   - options: The behavior for removing a file entry. Available options are:
  ///       - <doc:SystemPackage/FileDescriptor/AtOptions/removeDirectory>
  ///
  /// The corresponding C function is `unlinkat`.
  @_alwaysEmitIntoClient
  public func remove(at path: FilePath, options: AtOptions) throws {
    try path.withPlatformString { _remove(at: $0, options: options) }.get()
  }

  /// Remove a file entry relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the directory to remove.
  ///   - options: The behavior for removing a file entry. Available options are:
  ///       - <doc:SystemPackage/FileDescriptor/AtOptions/removeDirectory>
  ///
  /// The corresponding C function is `unlinkat`.
  @_alwaysEmitIntoClient
  public func remove(at path: UnsafePointer<CInterop.PlatformChar>, options: AtOptions) throws {
    try _remove(at: path, options: options).get()
  }

  @usableFromInline
  internal func _remove(
    at path: UnsafePointer<CInterop.PlatformChar>, options: AtOptions
  ) -> Result<(), Errno> {
    #if os(Windows)
    return .failure(Errno(rawValue: ERROR_NOT_SUPPORTED))
    #else
    return nothingOrErrno(retryOnInterrupt: false) {
      system_unlinkat(self.rawValue, path, options.rawValue)
    }
    #endif
  }

  /// Create a directory relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the directory to create.
  ///   - permissions: The file permissions to use for the created directory.
  ///
  /// The corresponding C function is `mkdirat`.
  @_alwaysEmitIntoClient
  public func createDirectory(
    at path: FilePath, permissions: FilePermissions
  ) throws {
    try path.withPlatformString {
      _createDirectory(at: $0, permissions: permissions)
    }.get()
  }

  /// Create a directory relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - path: The relative location of the directory to create.
  ///   - permissions: The file permissions to use for the created directory.
  ///
  /// The corresponding C function is `mkdirat`.
  @_alwaysEmitIntoClient
  public func createDirectory(
    at path: UnsafePointer<CInterop.PlatformChar>, permissions: FilePermissions
  ) throws {
    try _createDirectory(at: path, permissions: permissions).get()
  }

  @usableFromInline
  internal func _createDirectory(
    at path: UnsafePointer<CInterop.PlatformChar>, permissions: FilePermissions
  ) -> Result<(), Errno> {
    #if os(Windows)
    return .failure(Errno(rawValue: ERROR_NOT_SUPPORTED))
    #else
    return nothingOrErrno(retryOnInterrupt: false) {
      system_mkdirat(self.rawValue, path, permissions.rawValue)
    }
    #endif
  }

  /// Create a symbolic link relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - original: The path to be referred by the created symbolic link.
  ///   - link: The relative location of the symbolic link to create
  ///
  /// The corresponding C function is `symlinkat`.
  @_alwaysEmitIntoClient
  public func createSymlink(original: FilePath, link: FilePath) throws {
    try original.withPlatformString { cOriginal in
      try link.withPlatformString { cLink in
        try _createSymlink(original: cOriginal, link: cLink).get()
      }
    }
  }

  /// Create a symbolic link relative to a directory file descriptor
  ///
  /// - Parameters:
  ///   - original: The path to be referred by the created symbolic link.
  ///   - link: The relative location of the symbolic link to create
  ///
  /// The corresponding C function is `symlinkat`.
  @_alwaysEmitIntoClient
  public func createSymlink(
    original: UnsafePointer<CInterop.PlatformChar>,
    link: UnsafePointer<CInterop.PlatformChar>
  ) throws {
    try _createSymlink(original: original, link: link).get()
  }

  @usableFromInline
  internal func _createSymlink(
    original: UnsafePointer<CInterop.PlatformChar>,
    link: UnsafePointer<CInterop.PlatformChar>
  ) -> Result<(), Errno> {
    #if os(Windows)
    return .failure(Errno(rawValue: ERROR_NOT_SUPPORTED))
    #else
    return nothingOrErrno(retryOnInterrupt: false) {
      system_symlinkat(original, self.rawValue, link)
    }
    #endif
  }
}
