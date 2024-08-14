import WasmParser

class BumpAllocator<T> {
    private var pages: [UnsafeMutablePointer<T>] = []
    private var currentPage: UnsafeMutablePointer<T>
    private var currentOffset: Int = 0
    private let currentPageSize: Int

    init(initialCapacity: Int) {
        currentPageSize = initialCapacity
        currentPage = .allocate(capacity: currentPageSize)
    }

    deinit {
        for page in pages {
            page.deallocate()
        }
        currentPage.deallocate()
    }

    private func startNewPage(minimumCapacity: Int = 1) {
        pages.append(currentPage)
        // TODO: Should we grow the page size?
        let page = UnsafeMutablePointer<T>.allocate(capacity: currentPageSize)
        currentPage = page
        currentOffset = 0
    }

    func allocate(initializing value: T) -> UnsafeMutablePointer<T> {
        let pointer = allocate()
        pointer.initialize(to: value)
        return pointer
    }

    func allocate() -> UnsafeMutablePointer<T> {
        if currentOffset == currentPageSize - 1 {
            startNewPage()
        }
        let pointer = currentPage.advanced(by: currentOffset)
        currentOffset += 1
        return pointer
    }
}

extension BumpAllocator where T == UnsafeMutableRawPointer {
    func allocate<E>(
        _: E.Type,
        count: Int,
        initialize: (UnsafeMutableBufferPointer<E>) throws -> Void
    ) rethrows -> ImmutableBumpPtrVector<E> {
        assert(MemoryLayout<E>.size == MemoryLayout<T>.size)
        let pointer: UnsafeMutablePointer<T>
        if currentOffset + count >= currentPageSize {
            pointer = UnsafeMutablePointer<T>.allocate(capacity: count)
            pages.append(pointer)
        } else {
            pointer = currentPage.advanced(by: currentOffset)
            currentOffset += count
        }
        return try pointer.withMemoryRebound(to: E.self, capacity: count) { baseAddress in
            let buffer = UnsafeMutableBufferPointer(
                start: baseAddress,
                count: count
            )
            try initialize(buffer)
            return ImmutableBumpPtrVector<E>(buffer: buffer)
        }
    }
}

struct RuntimeRef {
    private let _value: Unmanaged<Runtime>

    var value: Runtime {
        _value.takeUnretainedValue()
    }

    var store: Store {
        value.store
    }

    init(_ value: __shared Runtime) {
        self._value = .passUnretained(value)
    }
}

protocol Internable {
    associatedtype Offset: UnsignedInteger
}

struct Interned<T: Internable>: Equatable, Hashable {
    let id: T.Offset
}

class Interner<Item: Hashable & Internable> {
    private var itemByIntern: [Item]
    private var internByItem: [Item: Interned<Item>]

    init() {
        itemByIntern = []
        internByItem = [:]
    }

    func intern(_ item: Item) -> Interned<Item> {
        if let interned = internByItem[item] {
            return interned
        }
        let id = itemByIntern.count
        itemByIntern.append(item)
        let newInterned = Interned<Item>(id: Item.Offset(id))
        internByItem[item] = newInterned
        return newInterned
    }

    func resolve(_ interned: Interned<Item>) -> Item {
        return itemByIntern[Int(interned.id)]
    }
}

extension FunctionType: Internable {
    typealias Offset = UInt32
}

typealias InternedFuncType = Interned<FunctionType>

class StoreAllocator {
    var instances: BumpAllocator<InstanceEntity>
    var functions: BumpAllocator<WasmFunctionEntity>
    var hostFunctions: BumpAllocator<HostFunctionEntity>
    var tables: BumpAllocator<TableEntity>
    var memories: BumpAllocator<MemoryEntity>
    var globals: BumpAllocator<GlobalEntity>
    var elements: BumpAllocator<ElementSegmentEntity>
    var datas: BumpAllocator<DataSegmentEntity>
    var codes: BumpAllocator<Code>
    var pointerVectors: BumpAllocator<UnsafeMutableRawPointer>
    let iseqAllocator: ISeqAllocator

    /// Function type interner shared across stores associated with the same `Runtime`.
    let funcTypeInterner: Interner<FunctionType>

    init(funcTypeInterner: Interner<FunctionType>) {
        instances = BumpAllocator(initialCapacity: 2)
        functions = BumpAllocator(initialCapacity: 64)
        hostFunctions = BumpAllocator(initialCapacity: 32)
        codes = BumpAllocator(initialCapacity: 64)
        tables = BumpAllocator(initialCapacity: 2)
        memories = BumpAllocator(initialCapacity: 2)
        globals = BumpAllocator(initialCapacity: 256)
        elements = BumpAllocator(initialCapacity: 2)
        datas = BumpAllocator(initialCapacity: 64)
        pointerVectors = BumpAllocator(initialCapacity: 1024)
        iseqAllocator = ISeqAllocator()
        self.funcTypeInterner = funcTypeInterner
    }
}

extension StoreAllocator: Equatable {
    static func == (lhs: StoreAllocator, rhs: StoreAllocator) -> Bool {
        lhs === rhs
    }
}


extension StoreAllocator {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-module>
    func allocate(
        module: Module,
        runtime: Runtime,
        externalValues: [ExternalValue],
        nameRegistry: inout NameRegistry
    ) throws -> InternalInstance {
        // Step 1 of module allocation algorithm, according to Wasm 2.0 spec.

        let types = module.types
        // Uninitialized instance
        let instancePointer = instances.allocate()
        let instanceHandle = InternalInstance(unsafe: instancePointer)
        var importedFunctions: [InternalFunction] = []
        var importedTables: [InternalTable] = []
        var importedMemories: [InternalMemory] = []
        var importedGlobals: [InternalGlobal] = []

        // External values imported in this module should be included in corresponding index spaces before definitions
        // local to to the module are added.
        for external in externalValues {
            switch external {
            case let .function(function):
                // Step 14.
                importedFunctions.append(function.handle)
            case let .table(table):
                // Step 15.
                importedTables.append(table.handle)
            case let .memory(memory):
                // Step 16.
                importedMemories.append(memory.handle)
            case let .global(global):
                // Step 17.
                importedGlobals.append(global.handle)
            }
        }

        func allocateEntities<EntityHandle, Internals: Collection>(
            imports: [EntityHandle],
            internals: Internals, allocateHandle: (Internals.Element, Int) throws -> EntityHandle
        ) rethrows -> ImmutableBumpPtrVector<EntityHandle> {
            return try pointerVectors.allocate(
                EntityHandle.self,
                count: imports.count + internals.count
            ) { buffer in
                for (index, importedEntity) in imports.enumerated() {
                    buffer.initializeElement(at: index, to: importedEntity)
                }
                for (index, internalEntity) in internals.enumerated() {
                    let allocated = try allocateHandle(internalEntity, index)
                    buffer.initializeElement(at: imports.count + index, to: allocated)
                }
            }
        }

        // Step 2.
        let functions = allocateEntities(
            imports: importedFunctions,
            internals: module.functions,
            allocateHandle: { f, _ in
                allocate(function: f, instance: instanceHandle, runtime: runtime)
            }
        )

        // Step 3.
        let tables = allocateEntities(
            imports: importedTables,
            internals: module.internalTables,
            allocateHandle: { t, _ in allocate(tableType: t) }
        )

        // Step 4.
        let memories = allocateEntities(
            imports: importedMemories,
            internals: module.internalMemories,
            allocateHandle: { m, _ in allocate(memoryType: m) }
        )

        // Step 5.
        var constEvalContext = ConstEvaluationContext(
            functions: functions,
            globals: importedGlobals.map(\.value)
        )
        let globals = try allocateEntities(
            imports: importedGlobals,
            internals: module.globals,
            allocateHandle: { global, i in
                let initialValue = try global.initializer.evaluate(context: constEvalContext)
                constEvalContext.globals.append(initialValue)
                return allocate(globalType: global.type, initialValue: initialValue)
            }
        )

        // Step 6.
        let elements = try pointerVectors.allocate(
            InternalElementSegment.self,
            count: module.elements.count
        ) { buffer in
            for (index, element) in module.elements.enumerated() {
                let references: [Reference]
                switch element.mode {
                case .active, .declarative:
                    // active & declarative segments are unavailable at runtime
                    references = []
                case .passive:
                    references = try element.evaluateInits(context: constEvalContext)
                }
                let handle = allocate(elementType: element.type, references: references)
                buffer.initializeElement(at: index, to: handle)
            }
        }

        // Step 13.
        let dataSegments = pointerVectors.allocate(InternalDataSegment.self, count: module.data.count) { buffer in
            for (index, datum) in module.data.enumerated() {
                let segment: InternalDataSegment
                switch datum {
                case let .passive(bytes):
                    segment = allocate(bytes: bytes)
                case .active:
                    // Active segments are copied into memories while instantiation
                    // They are semantically dropped after instantiation, so we don't
                    // need them at runtime
                    segment = allocate(bytes: [])
                }
                buffer.initializeElement(at: index, to: segment)
            }
        }

        // Steps 20-21.
        let instanceEntity = InstanceEntity(
            types: types,
            functions: functions,
            tables: tables,
            memories: memories,
            globals: globals,
            elementSegments: elements,
            dataSegments: dataSegments,
            exports: module.exports,
            features: module.features,
            hasDataCount: module.hasDataCount
        )
        instancePointer.initialize(to: instanceEntity)
        return instanceHandle
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-func>
    /// TODO: Mark as private
    func allocate(
        function: GuestFunction,
        instance: InternalInstance,
        runtime: Runtime
    ) -> InternalFunction {
        let code = InternalUncompiledCode(unsafe: codes.allocate(initializing: function.code))
        let pointer = functions.allocate(
            initializing: WasmFunctionEntity(
                type: runtime.internType(function.type),
                code: code,
                instance: instance
            )
        )
        return InternalFunction.wasm(EntityHandle(unsafe: pointer))
    }

    func allocate(hostFunction: HostFunction, runtime: Runtime) -> InternalFunction {
        let pointer = hostFunctions.allocate(
            initializing: HostFunctionEntity(
                type: runtime.internType(hostFunction.type),
                implementation: hostFunction.implementation
            )
        )
        return InternalFunction.host(EntityHandle(unsafe: pointer))
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-table>
    private func allocate(tableType: TableType) -> InternalTable {
        let pointer = tables.allocate(initializing: TableEntity(tableType))
        return InternalTable(unsafe: pointer)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-mem>
    func allocate(memoryType: MemoryType) -> InternalMemory {
        let pointer = memories.allocate(initializing: MemoryEntity(memoryType))
        return InternalMemory(unsafe: pointer)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-global>
    func allocate(globalType: GlobalType, initialValue: Value) -> InternalGlobal {
        let pointer = globals.allocate(initializing: GlobalEntity(globalType: globalType, initialValue: initialValue))
        return InternalGlobal(unsafe: pointer)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#element-segments>
    private func allocate(elementType: ReferenceType, references: [Reference]) -> InternalElementSegment {
        let pointer = elements.allocate(initializing: ElementSegmentEntity(type: elementType, references: references))
        return InternalElementSegment(unsafe: pointer)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#data-segments>
    private func allocate(bytes: ArraySlice<UInt8>) -> InternalDataSegment {
        let pointer = datas.allocate(initializing: DataSegmentEntity(data: bytes))
        return EntityHandle(unsafe: pointer)
    }
}
