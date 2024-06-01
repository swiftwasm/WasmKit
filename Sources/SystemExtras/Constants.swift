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

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _AT_EACCESS: CInt { AT_EACCESS }
@_alwaysEmitIntoClient
internal var _AT_SYMLINK_NOFOLLOW: CInt { AT_SYMLINK_NOFOLLOW }
@_alwaysEmitIntoClient
internal var _AT_SYMLINK_FOLLOW: CInt { AT_SYMLINK_FOLLOW }
#endif
@_alwaysEmitIntoClient
internal var _AT_REMOVEDIR: CInt { AT_REMOVEDIR }
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _AT_REALDEV: CInt { AT_REALDEV }
@_alwaysEmitIntoClient
internal var _AT_FDONLY: CInt { AT_FDONLY }
@_alwaysEmitIntoClient
internal var _AT_SYMLINK_NOFOLLOW_ANY: CInt { AT_SYMLINK_NOFOLLOW_ANY }
#endif
/* FIXME: Disabled until CSystem will include "linux/fcntl.h"
#if os(Linux)
@_alwaysEmitIntoClient
internal var _AT_NO_AUTOMOUNT: CInt { AT_NO_AUTOMOUNT }
#endif
*/

@_alwaysEmitIntoClient
internal var _F_GETFL: CInt { F_GETFL }
@_alwaysEmitIntoClient
internal var _O_DSYNC: CInt { O_DSYNC }
@_alwaysEmitIntoClient
internal var _O_SYNC: CInt { O_SYNC }
#if os(Linux)
@_alwaysEmitIntoClient
internal var _O_RSYNC: CInt { O_RSYNC }
#endif

@_alwaysEmitIntoClient
internal var _UTIME_NOW: CInt {
    #if os(Linux)
    // Hard-code constants because it's defined in glibc in a form that
    // ClangImporter cannot interpret as constants.
    // https://github.com/torvalds/linux/blob/92901222f83d988617aee37680cb29e1a743b5e4/include/linux/stat.h#L15
    return ((1 << 30) - 1)
    #else
    return UTIME_NOW
    #endif
}
@_alwaysEmitIntoClient
internal var _UTIME_OMIT: CInt {
    #if os(Linux)
    // Hard-code constants because it's defined in glibc in a form that
    // ClangImporter cannot interpret as constants.
    // https://github.com/torvalds/linux/blob/92901222f83d988617aee37680cb29e1a743b5e4/include/linux/stat.h#L16
    return ((1 << 30) - 2)
    #else
    return UTIME_OMIT
    #endif
}

@_alwaysEmitIntoClient
internal var _DT_UNKNOWN: CInt { CInt(DT_UNKNOWN) }
@_alwaysEmitIntoClient
internal var _DT_FIFO: CInt { CInt(DT_FIFO) }
@_alwaysEmitIntoClient
internal var _DT_CHR: CInt { CInt(DT_CHR) }
@_alwaysEmitIntoClient
internal var _DT_DIR: CInt { CInt(DT_DIR) }
@_alwaysEmitIntoClient
internal var _DT_BLK: CInt { CInt(DT_BLK) }
@_alwaysEmitIntoClient
internal var _DT_REG: CInt { CInt(DT_REG) }
@_alwaysEmitIntoClient
internal var _DT_LNK: CInt { CInt(DT_LNK) }
@_alwaysEmitIntoClient
internal var _DT_SOCK: CInt { CInt(DT_SOCK) }
@_alwaysEmitIntoClient
internal var _DT_WHT: CInt { CInt(DT_WHT) }

@_alwaysEmitIntoClient
internal var _S_IFMT: CInterop.Mode { S_IFMT }
@_alwaysEmitIntoClient
internal var _S_IFIFO: CInterop.Mode { S_IFIFO }
@_alwaysEmitIntoClient
internal var _S_IFCHR: CInterop.Mode { S_IFCHR }
@_alwaysEmitIntoClient
internal var _S_IFDIR: CInterop.Mode { S_IFDIR }
@_alwaysEmitIntoClient
internal var _S_IFBLK: CInterop.Mode { S_IFBLK }
@_alwaysEmitIntoClient
internal var _S_IFREG: CInterop.Mode { S_IFREG }
@_alwaysEmitIntoClient
internal var _S_IFLNK: CInterop.Mode { S_IFLNK }
@_alwaysEmitIntoClient
internal var _S_IFSOCK: CInterop.Mode { S_IFSOCK }

#if os(Linux)
@_alwaysEmitIntoClient
internal var _CLOCK_BOOTTIME: CInterop.ClockId { CLOCK_BOOTTIME }
#endif
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _CLOCK_MONOTONIC_RAW: CInterop.ClockId { CLOCK_MONOTONIC_RAW }
#endif
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(Linux) || os(OpenBSD) || os(FreeBSD) || os(WASI)
@_alwaysEmitIntoClient
internal var _CLOCK_MONOTONIC: CInterop.ClockId { CLOCK_MONOTONIC }
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _CLOCK_UPTIME_RAW: CInterop.ClockId { CLOCK_UPTIME_RAW }
#endif
#if os(OpenBSD) || os(FreeBSD) || os(WASI)
@_alwaysEmitIntoClient
internal var _CLOCK_UPTIME: CInterop.ClockId { CLOCK_UPTIME }
#endif
