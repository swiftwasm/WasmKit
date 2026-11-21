add_wasmkit_library(WasmTypes
  Description.swift
  GuestMemory.swift
  PlatformMutex.swift
  WasmTypes.swift
)

target_compile_options(WasmTypes PRIVATE
  $<$<COMPILE_LANGUAGE:Swift>:-DMultiThread>)
