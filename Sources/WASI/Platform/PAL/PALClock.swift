// System clocks for the WASI platform layer, wrapping `clock_gettime`.
// Windows clocks use QueryPerformanceCounter/GetSystemTimePreciseAsFileTime
// directly in `Clock.swift` and don't go through this wrapper.
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(WASI)
    import CWASIPlatform
    import WASILibc
#endif

#if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)

    /// A system clock identifier for `clock_gettime`/`clock_getres`.
    struct PlatformClock {
        let rawValue: clockid_t

        #if os(WASI)
            // wasi-libc clock ids are pointer-typed macros, which Swift can't
            // import; a tiny C shim exposes them as functions.
            static var monotonic: PlatformClock { PlatformClock(rawValue: wasi_platform_monotonic_clockid()) }
            static var realtime: PlatformClock { PlatformClock(rawValue: wasi_platform_realtime_clockid()) }
        #else
            static var monotonic: PlatformClock { PlatformClock(rawValue: CLOCK_MONOTONIC) }
            static var realtime: PlatformClock { PlatformClock(rawValue: CLOCK_REALTIME) }
        #endif

        #if canImport(Darwin)
            static var rawUptime: PlatformClock { PlatformClock(rawValue: CLOCK_UPTIME_RAW) }
        #endif
        #if os(OpenBSD) || os(FreeBSD)
            static var uptime: PlatformClock { PlatformClock(rawValue: CLOCK_UPTIME) }
        #endif

        func currentTime() throws -> FileTime {
            var timeSpec = timespec()
            try valueOrErrno(retryOnInterrupt: false) { clock_gettime(rawValue, &timeSpec) }
            return FileTime(rawValue: timeSpec)
        }

        func resolution() throws -> FileTime {
            var timeSpec = timespec()
            try valueOrErrno(retryOnInterrupt: false) { clock_getres(rawValue, &timeSpec) }
            return FileTime(rawValue: timeSpec)
        }
    }

#endif
