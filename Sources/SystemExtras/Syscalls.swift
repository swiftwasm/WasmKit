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

#if !os(Windows)

// openat
internal func system_openat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ oflag: Int32
) -> CInt {
  return openat(fd, path, oflag)
}

internal func system_openat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ oflag: Int32, _ mode: CInterop.Mode
) -> CInt {
  return openat(fd, path, oflag, mode)
}

// fcntl
internal func system_fcntl(_ fd: Int32, _ cmd: Int32, _ value: UnsafeMutableRawPointer) -> CInt {
  return fcntl(fd, cmd, value)
}

internal func system_fcntl(_ fd: Int32, _ cmd: Int32, _ value: CInt) -> CInt {
  return fcntl(fd, cmd, value)
}

internal func system_fcntl(_ fd: Int32, _ cmd: Int32) -> CInt {
  return fcntl(fd, cmd)
}

// fsync
internal func system_fsync(_ fd: Int32) -> CInt {
  return fsync(fd)
}

#endif

#if os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android) || os(Cygwin) || os(PS4)
// fdatasync
internal func system_fdatasync(_ fd: Int32) -> CInt {
  return fdatasync(fd)
}
#endif

#if os(Linux) || os(Android)
// posix_fadvise
internal func system_posix_fadvise(
  _ fd: Int32, _ offset: Int, _ length: Int, _ advice: CInt
) -> CInt {
  return posix_fadvise(fd, .init(offset), .init(length), advice)
}
#endif

// fstat
internal func system_fstat(_ fd: Int32, _ stat: UnsafeMutablePointer<stat>) -> CInt {
  return fstat(fd, stat)
}

#if !os(Windows)

// fstatat
internal func system_fstatat(
  _ fd: Int32, _ path: UnsafePointer<CInterop.PlatformChar>,
  _ stat: UnsafeMutablePointer<stat>,
  _ flags: Int32
) -> CInt {
  return fstatat(fd, path, stat, flags)
}

// unlinkat
internal func system_unlinkat(
  _ fd: Int32, _ path: UnsafePointer<CInterop.PlatformChar>,
  _ flags: Int32
) -> CInt {
  return unlinkat(fd, path, flags)
}

// ftruncate
internal func system_ftruncate(_ fd: Int32, _ size: off_t) -> CInt {
  return ftruncate(fd, size)
}

// mkdirat
internal func system_mkdirat(
  _ fd: Int32, _ path: UnsafePointer<CChar>, _ mode: CInterop.Mode
) -> CInt {
  return mkdirat(fd, path, mode)
}

// symlinkat
internal func system_symlinkat(
  _ oldPath: UnsafePointer<CChar>, _ newDirFd: Int32, _ newPath: UnsafePointer<CChar>
) -> CInt {
  return symlinkat(oldPath, newDirFd, newPath)
}

extension CInterop {
  #if SYSTEM_PACKAGE_DARWIN
  public typealias DirP = UnsafeMutablePointer<DIR>
  #elseif os(Linux) || os(Android)
  public typealias DirP = OpaquePointer
  #else
  #error("Unsupported Platform")
  #endif
}

// fdopendir
internal func system_fdopendir(_ fd: Int32) -> CInterop.DirP? {
  return fdopendir(fd)
}

// readdir
internal func system_readdir(_ dirp: CInterop.DirP) -> UnsafeMutablePointer<dirent>? {
  return readdir(dirp)
}
#endif

#if os(Windows)

extension CInterop {
  public typealias TimeSpec = FILETIME
}

#else

extension CInterop {
  public typealias ClockId = clockid_t
  public typealias TimeSpec = timespec
}

// futimens
internal func system_futimens(_ fd: Int32, _ times: UnsafePointer<CInterop.TimeSpec>) -> CInt {
  return futimens(fd, times)
}

// clock_gettime
internal func system_clock_gettime(_ id: CInterop.ClockId, _ tp: UnsafeMutablePointer<CInterop.TimeSpec>) -> CInt {
    return clock_gettime(id, tp)
}

// clock_getres
internal func system_clock_getres(_ id: CInterop.ClockId, _ tp: UnsafeMutablePointer<CInterop.TimeSpec>) -> CInt {
    return clock_getres(id, tp)
}
#endif
