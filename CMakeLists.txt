cmake_minimum_required(VERSION 3.29)

# CMake 4.1+ can emit each Swift module as `<name>.swiftmodule/<triple>.swiftmodule`
# itself; `add_wasmkit_library` then stops passing its own `-emit-module-path`,
# which newer CMake would override with its own.
if(POLICY CMP0195)
  cmake_policy(SET CMP0195 NEW)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(WasmKit LANGUAGES C Swift)

set(SWIFT_VERSION 5)
set(CMAKE_Swift_LANGUAGE_VERSION ${SWIFT_VERSION})

# Enable whole module optimization for Release or RelWithDebInfo builds.
set(CMAKE_Swift_COMPILATION_MODE $<IF:$<CONFIG:Release,RelWithDebInfo>,wholemodule,incremental>)

# The subdirectory into which host libraries will be installed.
set(SWIFT_HOST_LIBRARIES_SUBDIRECTORY "swift/host")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set(CMAKE_MACOSX_RPATH YES)

set(BUILD_SHARED_LIBS OFF)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Swift autolinks a module built with `-static` as `lib<name>.lib` on
  # Windows, while CMake names static libraries `<name>.lib` there.
  set(CMAKE_STATIC_LIBRARY_PREFIX_Swift "lib")
endif()

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

option(WASMKIT_BUILD_CLI "Build wasmkit-cli" ON)
option(WASMKIT_ENABLE_FILESYSTEM "Enable FileSystem support" ON)

if(WASMKIT_BUILD_CLI)
  set(BUILD_TESTING OFF) # disable ArgumentParser tests
  find_package(ArgumentParser CONFIG)
  if(NOT ArgumentParser_FOUND)
    message("-- Vending ArgumentParser")
    FetchContent_Declare(ArgumentParser
            GIT_REPOSITORY https://github.com/apple/swift-argument-parser
            GIT_TAG 1.6.1
    )
    FetchContent_MakeAvailable(ArgumentParser)
  endif()
endif()

add_subdirectory(Sources)
add_subdirectory(cmake/modules)
