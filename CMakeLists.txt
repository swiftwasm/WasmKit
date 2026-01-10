cmake_minimum_required(VERSION 3.19.6)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(WasmKit LANGUAGES C Swift)

set(SWIFT_VERSION 5)
set(CMAKE_Swift_LANGUAGE_VERSION ${SWIFT_VERSION})

# Enable whole module optimization for Release or RelWithDebInfo builds.
if(POLICY CMP0157)
  set(CMAKE_Swift_COMPILATION_MODE $<IF:$<CONFIG:Release,RelWithDebInfo>,wholemodule,incremental>)
else()
  add_compile_options($<$<AND:$<COMPILE_LANGUAGE:Swift>,$<CONFIG:Release,RelWithDebInfo>>:-wmo>)
endif()

if(CMAKE_VERSION VERSION_LESS 3.21)
  get_property(parent_dir DIRECTORY PROPERTY PARENT_DIRECTORY)
  if(NOT parent_dir)
    set(PROJECT_IS_TOP_LEVEL TRUE)
  endif()
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

option(WASMKIT_BUILD_CLI "Build wasmkit-cli" ON)

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

find_package(SwiftSystem CONFIG)
if(NOT SwiftSystem_FOUND)
  message("-- Vending SwiftSystem")
  FetchContent_Declare(SwiftSystem
    GIT_REPOSITORY https://github.com/apple/swift-system
    GIT_TAG 1.5.0
  )
  FetchContent_MakeAvailable(SwiftSystem)
endif()


add_subdirectory(Sources)
add_subdirectory(Tests)
add_subdirectory(cmake/modules)
