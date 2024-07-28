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

set(SWIFT_SYSTEM_APPLE_PLATFORMS "Darwin" "iOS" "watchOS" "tvOS" "visionOS")
if(CMAKE_SYSTEM_NAME IN_LIST SWIFT_SYSTEM_APPLE_PLATFORMS)
  target_compile_definitions(SystemExtras PRIVATE SYSTEM_PACKAGE_DARWIN)
endif()

target_link_wasmkit_libraries(SystemExtras PUBLIC
  SystemPackage)
