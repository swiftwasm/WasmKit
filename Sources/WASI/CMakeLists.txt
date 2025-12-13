add_wasmkit_library(WASI
  Platform/SandboxPrimitives/Open.swift
  Platform/SandboxPrimitives/OpenParent.swift
  Platform/Directory.swift
  Platform/Entry.swift
  Platform/File.swift
  Platform/PlatformTypes.swift
  Platform/SandboxPrimitives.swift
  Platform/HostFileSystem.swift
  MemoryFileSystem/MemoryFileSystem.swift
  MemoryFileSystem/MemoryFSNodes.swift
  MemoryFileSystem/MemoryDirEntry.swift
  MemoryFileSystem/MemoryFileEntry.swift
  MemoryFileSystem/MemoryStdioFile.swift
  FileSystem.swift
  GuestMemorySupport.swift
  Clock.swift
  RandomBufferGenerator.swift
  WASI.swift
)

target_link_wasmkit_libraries(WASI PUBLIC
  WasmTypes SystemExtras)