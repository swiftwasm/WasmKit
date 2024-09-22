add_wasmkit_library(WasmKit
  Module.swift
  ModuleParser.swift
  Translator.swift
  ResourceLimiter.swift
  Component/CanonicalLifting.swift
  Component/CanonicalLowering.swift
  Component/CanonicalCall.swift
  Component/CanonicalOptions.swift
  Component/ComponentTypes.swift
  Execution/Instructions/Reference.swift
  Execution/Instructions/Control.swift
  Execution/Instructions/Expression.swift
  Execution/Instructions/Instruction.swift
  Execution/Instructions/Parametric.swift
  Execution/Instructions/Table.swift
  Execution/Instructions/Memory.swift
  Execution/Instructions/InstructionSupport.swift
  Execution/Instructions/Numeric.swift
  Execution/Instructions/Variable.swift
  Execution/DispatchInstruction.swift
  Execution/Errors.swift
  Execution/Execution.swift
  Execution/Function.swift
  Execution/Instances.swift
  Execution/NameRegistry.swift
  Execution/Profiler.swift
  Execution/Runtime.swift
  Execution/RuntimeInterceptor.swift
  Execution/SignpostTracer.swift
  Execution/Store.swift
  Execution/StoreAllocator.swift
  Execution/UntypedValue.swift
  Execution/Value.swift
)

target_link_wasmkit_libraries(WasmKit PUBLIC
  _CWasmKit WasmParser SystemExtras WasmTypes SystemPackage)
