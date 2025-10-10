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
import WASILibc
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
@_alwaysEmitIntoClient
internal var _AT_REMOVEDIR: CInt { AT_REMOVEDIR }
#endif
#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _AT_REALDEV: CInt { AT_REALDEV }
@_alwaysEmitIntoClient
internal var _AT_FDONLY: CInt { AT_FDONLY }
@_alwaysEmitIntoClient
internal var _AT_SYMLINK_NOFOLLOW_ANY: CInt { AT_SYMLINK_NOFOLLOW_ANY }
#endif
/* FIXME: Disabled until CSystem will include "linux/fcntl.h"
#if os(Linux) || os(Android)
@_alwaysEmitIntoClient
internal var _AT_NO_AUTOMOUNT: CInt { AT_NO_AUTOMOUNT }
#endif
*/

#if !os(Windows) && !os(WASI)
@_alwaysEmitIntoClient
internal var _F_GETFL: CInt { F_GETFL }
@_alwaysEmitIntoClient
internal var _O_DSYNC: CInt { O_DSYNC }
#if os(Android)
@_alwaysEmitIntoClient
internal var _O_SYNC: CInt { __O_SYNC | O_DSYNC }
#else
@_alwaysEmitIntoClient
internal var _O_SYNC: CInt { O_SYNC }
#endif
#endif
#if os(Linux)
@_alwaysEmitIntoClient
internal var _O_RSYNC: CInt { O_RSYNC }
#endif

#if !os(Windows) && !os(WASI)
@_alwaysEmitIntoClient
internal var _UTIME_NOW: CInt {
    #if os(Linux) || os(Android)
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
    #if os(Linux) || os(Android)
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
#endif

@_alwaysEmitIntoClient
internal var _S_IFMT: CInterop.Mode { S_IFMT }
@_alwaysEmitIntoClient
internal var _S_IFCHR: CInterop.Mode { S_IFCHR }
@_alwaysEmitIntoClient
internal var _S_IFDIR: CInterop.Mode { S_IFDIR }
@_alwaysEmitIntoClient
internal var _S_IFREG: CInterop.Mode { S_IFREG }
#if !os(Windows)
@_alwaysEmitIntoClient
internal var _S_IFIFO: CInterop.Mode { S_IFIFO }
@_alwaysEmitIntoClient
internal var _S_IFBLK: CInterop.Mode { S_IFBLK }
@_alwaysEmitIntoClient
internal var _S_IFLNK: CInterop.Mode { S_IFLNK }
@_alwaysEmitIntoClient
internal var _S_IFSOCK: CInterop.Mode { S_IFSOCK }
#endif

#if os(Linux) || os(Android)
@_alwaysEmitIntoClient
internal var _CLOCK_BOOTTIME: CInterop.ClockId { CLOCK_BOOTTIME }
#endif
#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _CLOCK_MONOTONIC_RAW: CInterop.ClockId { CLOCK_MONOTONIC_RAW }
#endif
#if SYSTEM_PACKAGE_DARWIN || os(Linux) || os(Android) || os(OpenBSD) || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _CLOCK_MONOTONIC: CInterop.ClockId { CLOCK_MONOTONIC }
#endif
#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _CLOCK_UPTIME_RAW: CInterop.ClockId { CLOCK_UPTIME_RAW }
#endif
#if os(OpenBSD) || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _CLOCK_UPTIME: CInterop.ClockId { CLOCK_UPTIME }
#endif
