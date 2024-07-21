#if os(Windows)
import WinSDK
import SystemPackage

extension Errno {
  public init(windowsError: DWORD) {
    self.init(rawValue: _mapWindowsErrorToErrno(windowsError))
  }
}

@usableFromInline
internal func _mapWindowsErrorToErrno(_ errorCode: DWORD) -> CInt {
  switch Int32(errorCode) {
  case ERROR_SUCCESS:
    return 0
  case ERROR_INVALID_FUNCTION,
       ERROR_INVALID_ACCESS,
       ERROR_INVALID_DATA,
       ERROR_INVALID_PARAMETER,
       ERROR_NEGATIVE_SEEK:
    return EINVAL
  case ERROR_FILE_NOT_FOUND,
       ERROR_PATH_NOT_FOUND,
       ERROR_INVALID_DRIVE,
       ERROR_NO_MORE_FILES,
       ERROR_BAD_NETPATH,
       ERROR_BAD_NET_NAME,
       ERROR_BAD_PATHNAME,
       ERROR_FILENAME_EXCED_RANGE:
    return ENOENT
  case ERROR_TOO_MANY_OPEN_FILES:
    return EMFILE
  case ERROR_ACCESS_DENIED,
       ERROR_CURRENT_DIRECTORY,
       ERROR_LOCK_VIOLATION,
       ERROR_NETWORK_ACCESS_DENIED,
       ERROR_CANNOT_MAKE,
       ERROR_FAIL_I24,
       ERROR_DRIVE_LOCKED,
       ERROR_SEEK_ON_DEVICE,
       ERROR_NOT_LOCKED,
       ERROR_LOCK_FAILED,
       ERROR_WRITE_PROTECT...ERROR_SHARING_BUFFER_EXCEEDED:
    return EACCES
  case ERROR_INVALID_HANDLE,
       ERROR_INVALID_TARGET_HANDLE,
       ERROR_DIRECT_ACCESS_HANDLE:
    return EBADF
  case ERROR_ARENA_TRASHED,
       ERROR_NOT_ENOUGH_MEMORY,
       ERROR_INVALID_BLOCK,
       ERROR_NOT_ENOUGH_QUOTA:
    return ENOMEM
  case ERROR_BAD_ENVIRONMENT:
    return E2BIG
  case ERROR_BAD_FORMAT,
       ERROR_INVALID_STARTING_CODESEG...ERROR_INFLOOP_IN_RELOC_CHAIN:
    return ENOEXEC
  case ERROR_NOT_SAME_DEVICE:
    return EXDEV
  case ERROR_FILE_EXISTS,
       ERROR_ALREADY_EXISTS:
    return EEXIST
  case ERROR_NO_PROC_SLOTS,
       ERROR_MAX_THRDS_REACHED,
       ERROR_NESTING_NOT_ALLOWED:
    return EAGAIN
  case ERROR_BROKEN_PIPE:
    return EPIPE
  case ERROR_DISK_FULL:
    return ENOSPC
  case ERROR_WAIT_NO_CHILDREN,
       ERROR_CHILD_NOT_COMPLETE:
    return ECHILD
  case ERROR_DIR_NOT_EMPTY:
    return ENOTEMPTY
  case ERROR_NO_UNICODE_TRANSLATION:
    return EILSEQ
  default:
    return EINVAL
  }
}

#endif
