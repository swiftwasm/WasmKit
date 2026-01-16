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
import CSystem
import ucrt
#elseif os(WASI)
import CSystemExtras
import WASILibc
#else
#error("Unsupported Platform")
#endif

import SystemPackage

#if !os(Windows)

@frozen
public struct Clock: RawRepresentable {

  @_alwaysEmitIntoClient
  public var rawValue: CInterop.ClockId

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.ClockId) { self.rawValue = rawValue }
}

extension Clock {
  #if os(Linux) || os(Android)
  @_alwaysEmitIntoClient
  public static var boottime: Clock { Clock(rawValue: CLOCK_BOOTTIME) }
  #endif

  #if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var rawMonotonic: Clock { Clock(rawValue: _CLOCK_MONOTONIC_RAW) }
  #endif

  #if SYSTEM_PACKAGE_DARWIN || os(Linux) || os(Android) || os(OpenBSD) || os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var monotonic: Clock { Clock(rawValue: _CLOCK_MONOTONIC) }
  #endif

  #if os(WASI)
  @_alwaysEmitIntoClient
  public static var monotonic: Clock { Clock(rawValue: csystemextras_monotonic_clockid()) }
  #endif

  #if SYSTEM_PACKAGE_DARWIN || os(Linux) || os(Android) || os(OpenBSD) || os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var realtime: Clock { Clock(rawValue: _CLOCK_REALTIME) }
  #endif

  #if os(WASI)
  @_alwaysEmitIntoClient
  public static var realtime: Clock { Clock(rawValue: csystemextras_realtime_clockid()) }
  #endif

  #if os(OpenBSD) || os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var uptime: Clock { Clock(rawValue: _CLOCK_UPTIME) }
  #endif

  #if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var rawUptime: Clock { Clock(rawValue: _CLOCK_UPTIME_RAW) }
  #endif

  @_alwaysEmitIntoClient
  public func currentTime() throws -> Clock.TimeSpec {
    try _currentTime().get()
  }

  @usableFromInline
  internal func _currentTime() -> Result<Clock.TimeSpec, Errno> {
    var timeSpec = CInterop.TimeSpec()
    return nothingOrErrno(retryOnInterrupt: false) {
      system_clock_gettime(self.rawValue, &timeSpec)
    }
    .map { Clock.TimeSpec(rawValue: timeSpec) }
  }

  @_alwaysEmitIntoClient
  public func resolution() throws -> Clock.TimeSpec {
    try _resolution().get()
  }

  @usableFromInline
  internal func _resolution() -> Result<Clock.TimeSpec, Errno> {
    var timeSpec = CInterop.TimeSpec()
    return nothingOrErrno(retryOnInterrupt: false) {
      system_clock_getres(self.rawValue, &timeSpec)
    }
    .map { Clock.TimeSpec(rawValue: timeSpec) }
  }
}

extension Clock {
  @frozen
  public struct TimeSpec: RawRepresentable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.TimeSpec

    @_alwaysEmitIntoClient
    public var seconds: Int64 { .init(rawValue.tv_sec) }

    @_alwaysEmitIntoClient
    public var nanoseconds: Int64 { .init(rawValue.tv_nsec) }

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.TimeSpec) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public init(seconds: Int, nanoseconds: Int) {
      self.init(rawValue: CInterop.TimeSpec(tv_sec: .init(seconds), tv_nsec: nanoseconds))
    }

    @_alwaysEmitIntoClient
    public static var now: TimeSpec {
#if os(WASI)
      return TimeSpec(rawValue: CInterop.TimeSpec(tv_sec: 0, tv_nsec: Int(UTIME_NOW)))
#else
      return TimeSpec(rawValue: CInterop.TimeSpec(tv_sec: 0, tv_nsec: Int(_UTIME_NOW)))
#endif
    }

    @_alwaysEmitIntoClient
    public static var omit: TimeSpec {
#if os(WASI)
      return TimeSpec(rawValue: CInterop.TimeSpec(tv_sec: 0, tv_nsec: Int(UTIME_OMIT)))
#else
      return TimeSpec(rawValue: CInterop.TimeSpec(tv_sec: 0, tv_nsec: Int(_UTIME_OMIT)))
#endif
    }
  }
}
#endif
