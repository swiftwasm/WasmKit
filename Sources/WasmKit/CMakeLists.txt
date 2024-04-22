add_wasmkit_library(WasmKit
  Types/Module.swift
  ModuleParser.swift
  Translator.swift
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
  Execution/Types/Instances.swift
  Execution/Types/Errors.swift
  Execution/Types/Value.swift
  Execution/Runtime/InstDispatch.swift
  Execution/Runtime/Stack.swift
  Execution/Runtime/Runtime.swift
  Execution/Runtime/ExecutionState.swift
  Execution/Runtime/Profiler.swift
  Execution/Runtime/NameRegistry.swift
  Execution/Runtime/Store.swift
  Execution/Runtime/Function.swift
)

target_link_wasmkit_libraries(WasmKit PUBLIC
  WasmParser SystemExtras WasmTypes SystemPackage)
