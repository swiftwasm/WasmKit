#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import CSystem
import Glibc
#elseif os(Windows)
import CSystem
import ucrt
#else
#error("Unsupported Platform")
#endif

import SystemPackage

@frozen
public struct Clock: RawRepresentable {

  @_alwaysEmitIntoClient
  public var rawValue: CInterop.ClockId

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.ClockId) { self.rawValue = rawValue }
}

extension Clock {
  #if os(Linux)
  @_alwaysEmitIntoClient
  public static var boottime: Clock { Clock(rawValue: CLOCK_BOOTTIME) }
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  @_alwaysEmitIntoClient
  public static var rawMonotonic: Clock { Clock(rawValue: _CLOCK_MONOTONIC_RAW) }
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(Linux) || os(OpenBSD) || os(FreeBSD) || os(WASI)
  @_alwaysEmitIntoClient
  public static var monotonic: Clock { Clock(rawValue: _CLOCK_MONOTONIC) }
  #endif

  #if os(OpenBSD) || os(FreeBSD) || os(WASI)
  @_alwaysEmitIntoClient
  public static var uptime: Clock { Clock(rawValue: _CLOCK_UPTIME) }
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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
    try _currentTime().get()
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
    public var seconds: Int { rawValue.tv_sec }

    @_alwaysEmitIntoClient
    public var nanoseconds: Int { rawValue.tv_nsec }

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.TimeSpec) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public init(seconds: Int, nanoseconds: Int) {
      self.init(rawValue: CInterop.TimeSpec(tv_sec: seconds, tv_nsec: nanoseconds))
    }

    @_alwaysEmitIntoClient
    public static var now: TimeSpec {
      return TimeSpec(rawValue: CInterop.TimeSpec(tv_sec: 0, tv_nsec: Int(_UTIME_NOW)))
    }

    @_alwaysEmitIntoClient
    public static var omit: TimeSpec {
      return TimeSpec(rawValue: CInterop.TimeSpec(tv_sec: 0, tv_nsec: Int(_UTIME_OMIT)))
    }
  }
}
