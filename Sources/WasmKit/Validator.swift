import WasmParser

/// Validates instructions within a given context.
struct InstructionValidator {
    let context: InternalInstance
    let typeRegistry: TypeRegistry

    func validateMemArg(_ memarg: MemArg, naturalAlignment: Int) throws(WasmKitError) {
        if memarg.align > naturalAlignment {
            throw WasmKitError(message: .invalidMemArgAlignment(memarg: memarg, naturalAlignment: naturalAlignment))
        }
        // With memory64 enabled the parser reads every offset as u64, so a 32-bit memory's
        // offset range is checked here.
        if memarg.offset > UInt32.max, try !context.isMemory64(memoryIndex: memarg.memory) {
            throw WasmKitError(message: .memArgOffsetOutOfRange(offset: memarg.offset))
        }
    }

    func validateGlobalSet(_ type: GlobalType) throws(WasmKitError) {
        switch type.mutability {
        case .constant:
            throw WasmKitError(message: .globalSetConstant)
        case .variable:
            break
        }
    }

    func validateTableInit(elemIndex: UInt32, table: UInt32) throws(WasmKitError) {
        let tableType = try context.tableType(table)
        let elementType = try context.elementType(elemIndex)
        guard elementType.isSubtype(of: tableType.elementType, in: typeRegistry) else {
            throw WasmKitError(
                message: .tableElementTypeMismatch(tableType: "\(tableType.elementType)", elementType: "\(elementType)")
            )
        }
    }

    func validateTableCopy(dest: UInt32, source: UInt32) throws(WasmKitError) {
        let tableType1 = try context.tableType(source)
        let tableType2 = try context.tableType(dest)
        guard tableType1.elementType.isSubtype(of: tableType2.elementType, in: typeRegistry) else {
            throw WasmKitError(
                message:
                    .tableElementTypeMismatch(
                        tableType: "\(tableType1.elementType)",
                        elementType: "\(tableType2.elementType)"
                    )
            )
        }
    }

    /// Checks that `call_indirect` can call through the table's elements.
    func validateCallIndirectTable(_ table: UInt32) throws(WasmKitError) {
        let elementType = try context.tableType(table).elementType
        guard elementType.isSubtype(of: .funcRef, in: typeRegistry) else {
            throw WasmKitError(message: .tableElementTypeMismatch(tableType: "\(elementType)", elementType: "funcref"))
        }
    }

    func validateRefFunc(functionIndex: UInt32) throws(WasmKitError) {
        try context.validateFunctionIndex(functionIndex)
    }

    func validateDataSegment(_ dataIndex: DataIndex) throws(WasmKitError) {
        guard let dataCount = context.dataCount else {
            throw WasmKitError(message: .dataCountSectionRequired)
        }
        guard dataIndex < dataCount else {
            throw WasmKitError(message: .indexOutOfBounds("data", dataIndex, max: dataCount))
        }
    }

    func validateReturnCallLike(calleeType: FunctionType, callerType: FunctionType) throws(WasmKitError) {
        guard calleeType.results.isSubtype(of: callerType.results, in: typeRegistry) else {
            throw WasmKitError(
                message: .typeMismatchOnReturnCall(expected: callerType.results, actual: calleeType.results)
            )
        }
    }
}

/// Validates a WebAssembly module.
struct ModuleValidator {
    let module: Module
    init(module: Module) {
        self.module = module
    }

    func validate() throws(WasmKitError) {
        if module.memoryTypes.count > 1 && !module.features.contains(.multiMemory) {
            throw WasmKitError(message: .multipleMemoriesNotPermitted)
        }
        // Multiple tables are allowed with reference types feature
        if module.tableTypes.count > 1 && !module.features.contains(.referenceTypes) {
            throw WasmKitError(message: .multipleTablesNotPermitted)
        }
        for memoryType in module.memoryTypes {
            try Self.checkMemoryType(memoryType, features: module.features)
        }
        for tableType in module.tableTypes {
            try Self.checkTableType(tableType, features: module.features)
        }
        for (tableType, initializer) in zip(module.internalTables, module.tableInitializers) {
            // Without an initializer, elements start out null.
            guard initializer != nil || tableType.elementType.isNullable else {
                throw WasmKitError(message: .nonNullableTableWithoutInitializer(elementType: tableType.elementType))
            }
        }
        for tagTypeIndex in module.tagTypes {
            let tagType = try module.types.functionType(at: tagTypeIndex)
            guard tagType.results.isEmpty else {
                throw WasmKitError(message: .nonEmptyTagResultType)
            }
        }
        try checkStartFunction()
    }

    func checkStartFunction() throws(WasmKitError) {
        if let startFunction = module.start {
            let type = try module.resolveFunctionType(startFunction)
            guard type.parameters.isEmpty, type.results.isEmpty else {
                throw WasmKitError(message: .startFunctionInvalidParameters())
            }
        }
    }

    static func checkMemoryType(_ type: MemoryType, features: WasmFeatureSet) throws(WasmKitError) {
        try checkLimit(type)

        if type.isMemory64 {
            guard features.contains(.memory64) else {
                throw WasmKitError(message: .memory64FeatureRequired)
            }
        }

        let hardMax = MemoryEntity.maxPageCount(isMemory64: type.isMemory64)

        if type.min > hardMax {
            throw WasmKitError(message: .sizeMinimumExceeded(max: hardMax))
        }

        if let max = type.max, max > hardMax {
            throw WasmKitError(message: .sizeMaximumExceeded(max: hardMax))
        }

        if type.shared {
            guard features.contains(.threads) else {
                throw WasmKitError(message: .threadsFeatureRequiredForSharedMemories)
            }
            guard type.max != nil else {
                throw WasmKitError(message: .sharedMemoryMustHaveMaximum)
            }
        }
    }

    static func checkTableType(_ type: TableType, features: WasmFeatureSet) throws(WasmKitError) {
        if type.elementType != .funcRef, !features.contains(.referenceTypes) {
            throw WasmKitError(message: .referenceTypesFeatureRequiredForNonFuncrefTables)
        }
        try checkLimit(type.limits)

        if type.limits.isMemory64 {
            guard features.contains(.memory64) else {
                throw WasmKitError(message: .memory64FeatureRequired)
            }
        }

        let hardMax = TableEntity.maxSize(isMemory64: type.limits.isMemory64)

        if type.limits.min > hardMax {
            throw WasmKitError(message: .sizeMinimumExceeded(max: hardMax))
        }

        if let max = type.limits.max, max > hardMax {
            throw WasmKitError(message: .sizeMaximumExceeded(max: hardMax))
        }
    }

    private static func checkLimit(_ limit: Limits) throws(WasmKitError) {
        guard let max = limit.max else { return }
        if limit.min > max {
            throw WasmKitError(message: .sizeMinimumMustNotExceedMaximum)
        }
    }
}

extension WasmTypes.Reference {
    /// Whether the reference is a value of the given canonical reference type.
    ///
    /// - Parameter heap: The GC heap an object reference points into, which
    ///   tells the object's type.
    func matches(_ type: WasmTypes.ReferenceType, heap: GCHeap) -> Bool {
        switch self {
        case .function(let address):
            guard type.heapType.isSubtype(of: .funcRef, in: heap.typeRegistry) else { return false }
            guard let address else { return type.isNullable }
            return HeapType.concrete(typeIndex: InternalFunction(bitPattern: address).type.id).isSubtype(of: type.heapType, in: heap.typeRegistry)
        case .extern(let address):
            guard type.heapType.isSubtype(of: .externRef, in: heap.typeRegistry) else { return false }
            return address != nil ? type.heapType == .externRef : type.isNullable
        case .exception(let address):
            guard type.heapType.isSubtype(of: .exnRef, in: heap.typeRegistry) else { return false }
            return address != nil ? type.heapType == .exnRef : type.isNullable
        case .any(let reference):
            guard type.heapType.topType == .any else { return false }
            guard let reference else { return type.isNullable }
            if reference.i31 != nil {
                return HeapType.abstract(.i31).isSubtype(of: type.heapType, in: heap.typeRegistry)
            }
            if reference.internalizedValue != nil {
                // An internalized host value is an `anyref` and nothing more specific.
                return type.heapType == .abstract(.any)
            }
            let object = UInt32(truncatingIfNeeded: reference.storage)
            return HeapType.concrete(typeIndex: heap.typeID(of: object)).isSubtype(of: type.heapType, in: heap.typeRegistry)
        case .externalized:
            return type.heapType == .externRef
        }
    }

    /// Checks if the reference type matches the expected type.
    func checkType(_ type: WasmTypes.ReferenceType, heap: GCHeap) throws(WasmKitError) {
        guard matches(type, heap: heap) else {
            throw WasmKitError(message: .expectTypeButGot(expected: "\(type)", got: "\(self)"))
        }
    }
}

extension Value {
    /// Whether the value is a value of the given canonical type.
    func matches(_ type: WasmTypes.ValueType, heap: GCHeap) -> Bool {
        switch (self, type) {
        case (.i32, .i32), (.i64, .i64), (.f32, .f32), (.f64, .f64), (.v128, .v128): return true
        case (.ref(let ref), .ref(let refType)): return ref.matches(refType, heap: heap)
        default: return false
        }
    }

    /// Checks if the value type matches the expected type.
    func checkType(_ type: WasmTypes.ValueType, heap: GCHeap) throws(WasmKitError) {
        guard matches(type, heap: heap) else {
            throw WasmKitError(message: .expectTypeButGot(expected: "\(type)", got: "\(self)"))
        }
    }
}
