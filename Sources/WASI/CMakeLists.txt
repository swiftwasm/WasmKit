add_wasmkit_library(WASI
  Platform/SandboxPrimitives/Open.swift
  Platform/SandboxPrimitives/OpenParent.swift
  Platform/Directory.swift
  Platform/Entry.swift
  Platform/File.swift
  Platform/PlatformTypes.swift
  Platform/SandboxPrimitives.swift
  FileSystem.swift
  GuestMemorySupport.swift
  Clock.swift
  Poll.swift
  RandomBufferGenerator.swift
  WASI.swift
)

target_link_wasmkit_libraries(WASI PUBLIC
  WasmTypes SystemExtras)
