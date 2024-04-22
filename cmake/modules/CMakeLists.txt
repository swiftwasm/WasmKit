if(PROJECT_IS_TOP_LEVEL)
  export(EXPORT WasmKitTargets
         FILE ${CMAKE_CURRENT_BINARY_DIR}/WasmKitConfig.cmake
         NAMESPACE WasmKit::)
endif()
