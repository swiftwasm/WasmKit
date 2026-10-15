find_package(Threads REQUIRED)

add_library(CWasmKitWASIThreads
  Thread.c
)

target_include_directories(CWasmKitWASIThreads PUBLIC
  include
)

target_link_libraries(CWasmKitWASIThreads PUBLIC
  Threads::Threads
)

install(TARGETS CWasmKitWASIThreads EXPORT WasmKitTargets)
set_property(GLOBAL APPEND PROPERTY WASMKIT_EXPORTS CWasmKitWASIThreads)
