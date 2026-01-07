cmake_minimum_required(VERSION 3.30)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(WasmKit LANGUAGES C CXX Swift)

set(SWIFT_VERSION 6)
set(CMAKE_Swift_LANGUAGE_VERSION ${SWIFT_VERSION})

set(min_supported_swift_version 6.2)
if(CMAKE_Swift_COMPILER_VERSION VERSION_LESS "${min_supported_swift_version}")
  message(
    FATAL_ERROR
    "Outdated Swift compiler: "
    "Swift ${min_supported_swift_version} or newer is required."
  )
endif()

# Enable whole module optimization for Release or RelWithDebInfo builds.
if(POLICY CMP0157)
  set(CMAKE_Swift_COMPILATION_MODE $<IF:$<CONFIG:Release,RelWithDebInfo>,wholemodule,incremental>)
else()
  add_compile_options($<$<AND:$<COMPILE_LANGUAGE:Swift>,$<CONFIG:Release,RelWithDebInfo>>:-wmo>)
endif()

# The subdirectory into which host libraries will be installed.
set(SWIFT_HOST_LIBRARIES_SUBDIRECTORY "swift/host")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set(CMAKE_MACOSX_RPATH YES)

set(BUILD_SHARED_LIBS OFF)

include(AddSwiftHostLibrary)

set(CMAKE_Swift_COMPILER_TARGET ${SWIFT_HOST_TRIPLE})

if("${SWIFT_HOST_MODULE_TRIPLE}" STREQUAL "")
  set(module_triple_command "${CMAKE_Swift_COMPILER}" -print-target-info)
  if(CMAKE_Swift_COMPILER_TARGET)
    list(APPEND module_triple_command -target ${CMAKE_Swift_COMPILER_TARGET})
  endif()
  execute_process(COMMAND ${module_triple_command} OUTPUT_VARIABLE target_info_json)
  string(JSON SWIFT_HOST_MODULE_TRIPLE GET "${target_info_json}" "target" "moduleTriple")
endif()
message(STATUS "Module triple: ${SWIFT_HOST_MODULE_TRIPLE}")

add_compile_definitions(
  $<$<COMPILE_LANGUAGE:Swift>:WASMKIT_BUILD_USING_CMAKE>
)

include(FetchContent)

find_package(SwiftSystem CONFIG)
if(NOT SwiftSystem_FOUND)
  message("-- Vending SwiftSystem")
  FetchContent_Declare(SwiftSystem
    GIT_REPOSITORY https://github.com/apple/swift-system
    GIT_TAG 1.5.0
    GIT_SHALLOW TRUE
  )
  FetchContent_MakeAvailable(SwiftSystem)
endif()

option(WASMKIT_BUILD_CLI "Build WasmKit CLI" ON)
option(WASMKIT_BUILD_LLVM_BACKEND "Build WasmKit LLVM backend (experimental)" OFF)
option(WASMKIT_LLVM_BACKEND_TARGET "WasmKit LLVM backend target architecture" "aarch64")

add_subdirectory(Sources)
add_subdirectory(Tests)
add_subdirectory(cmake/modules)
