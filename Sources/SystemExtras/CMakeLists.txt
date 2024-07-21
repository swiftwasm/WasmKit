add_wasmkit_library(SystemExtras
  Vendor/Exports.swift
  Vendor/Utils.swift
  Vendor/WindowsSyscallAdapter.swift
  Clock.swift
  Constants.swift
  FileAtOperations.swift
  FileOperations.swift
  Syscalls.swift
)

target_link_wasmkit_libraries(SystemExtras PUBLIC
  SystemPackage)
