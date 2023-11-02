/// A container to manage execution state of one or more module instances.
public final class Runtime {
    public let store: Store
    var stack: Stack
    let interceptor: RuntimeInterceptor?

    /// Index of an instruction to be executed in the current function.
    var programCounter = 0

    /// Initializes a new instant of a WebAssembly interpreter runtime.
    /// - Parameter hostModules: Host module names mapped to their corresponding ``HostModule`` definitions.
    public init(hostModules: [String: HostModule] = [:], interceptor: RuntimeInterceptor? = nil) {
        stack = Stack()
        store = Store(hostModules)
        self.interceptor = interceptor
    }

    public var isStackEmpty: Bool {
        stack.top == nil
    }
}

public protocol RuntimeInterceptor {
    func onEnterFunction(_ address: FunctionAddress, store: Store)
    func onExitFunction(_ address: FunctionAddress, store: Store)
}

extension Runtime {
    func cleanUpStack() {
        stack = Stack()
    }

    public func instantiate(module: Module, name: String? = nil) throws -> ModuleInstance {
        let instance = try instantiate(module: module, externalValues: store.getExternalValues(module))

        if let name {
            store.namedModuleInstances[name] = instance
        }

        return instance
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#instantiation>
    func instantiate(module: Module, externalValues: [ExternalValue]) throws -> ModuleInstance {
        defer {
            // clean up the stack in case an error is thrown.
            cleanUpStack()
        }

        // Step 3 of instantiation algorithm, according to Wasm 2.0 spec.
        guard module.imports.count == externalValues.count else {
            throw InstantiationError.importsAndExternalValuesMismatch
        }

        // Step 4.
        let isValid = zip(module.imports, externalValues).map { i, e -> Bool in
            switch (i.descriptor, e) {
            case (.function, .function),
                (.table, .table),
                (.memory, .memory),
                (.global, .global):
                return true
            default: return false
            }
        }.reduce(true) { $0 && $1 }

        guard isValid else {
            throw InstantiationError.importsAndExternalValuesMismatch
        }

        // Steps 5-8.
        let initialGlobals = try evaluateGlobals(module: module, externalValues: externalValues)

        // Step 9.
        // Process `elem.init` evaluation during allocation

        // Step 11.
        let instance = store.allocate(
            module: module,
            externalValues: externalValues,
            initialGlobals: initialGlobals
        )

        // Step 12.
        let frame = Frame(arity: 0, module: instance, locals: [])

        // Step 13.
        try stack.push(frame: frame)

        // Steps 14-15.
        do {
            for (elementIndex, element) in module.elements.enumerated() {
                let elementIndex = UInt32(elementIndex)

                switch element.mode {
                case let .active(tableIndex, offsetExpression):
                    for i in offsetExpression.instructions + [
                        .numeric(.const(.i32(0))),
                        .numeric(.const(.i32(UInt32(element.initializer.count)))),
                        .table(.`init`(tableIndex, elementIndex)),
                        .table(.elementDrop(elementIndex)),
                    ] {
                        try execute(i)
                    }

                case .declarative:
                    try execute(.table(.elementDrop(elementIndex)))

                case .passive:
                    continue
                }
            }
        } catch Trap.undefinedElement, Trap.tableSizeOverflow, Trap.outOfBoundsTableAccess {
            throw InstantiationError.outOfBoundsTableAccess
        } catch {
            throw error
        }

        // Step 16.
        do {
            for case let (dataIndex, .active(data)) in module.data.enumerated() {
                assert(data.index == 0)

                for i in data.offset.instructions + [
                    .numeric(.const(.i32(0))),
                    .numeric(.const(.i32(UInt32(data.initializer.count)))),
                    .memory(.`init`(UInt32(dataIndex))),
                    .memory(.dataDrop(UInt32(dataIndex))),
                ] {
                    try execute(i)
                }
            }
        } catch Trap.outOfBoundsMemoryAccess {
            throw InstantiationError.outOfBoundsMemoryAccess
        } catch {
            throw error
        }

        // Step 17.
        if let startIndex = module.start {
            try invoke(functionAddress: instance.functionAddresses[Int(startIndex)])
            while stack.elements.count != 1 || stack.currentFrame != frame {
                try step()
            }
        }

        // Steps 18-19.
        try stack.popFrame()

        return instance
    }

    private func evaluateGlobals(module: Module, externalValues: [ExternalValue]) throws -> [Value] {
        let globalModuleInstance = ModuleInstance()

        for externalValue in externalValues {
            switch externalValue {
            case let .global(address):
                globalModuleInstance.globalAddresses.append(address)
            case let .function(address):
                globalModuleInstance.functionAddresses.append(address)
            default:
                continue
            }
        }

        globalModuleInstance.types = module.types

        for function in module.functions {
            let address = store.allocate(function: function, module: globalModuleInstance)
            globalModuleInstance.functionAddresses.append(address)
        }

        try stack.push(frame: .init(arity: 0, module: globalModuleInstance, locals: []))

        let globalInitializers = try module.globals.map { global in
            for i in global.initializer.instructions {
                try execute(i)
            }

            return try stack.popValue()
        }

        try stack.popFrame()

        return globalInitializers
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    func invoke(functionAddress address: FunctionAddress) throws {
        interceptor?.onEnterFunction(address, store: store)

        switch try store.function(at: address) {
        case let .host(function):
            let parameters = try stack.popValues(count: function.type.parameters.count)
            let caller = Caller(store: store, instance: stack.currentFrame.module)
            stack.push(values: try function.implementation(caller, parameters))

            programCounter += 1

        case let .wasm(function, body: body):
            let locals = function.code.locals.map { $0.defaultValue }
            let expression = body

            let arguments = try stack.popValues(count: function.type.parameters.count)

            let arity = function.type.results.count
            try stack.push(frame: .init(arity: arity, module: function.module, locals: arguments + locals, address: address))

            self.enter(
                expression, continuation: programCounter + 1,
                arity: arity
            )
        }
    }
}

extension Runtime {
    public func step() throws {
        if let label = stack.currentLabel {
            if programCounter < label.expression.instructions.count {
                try execute(stack.currentLabel.expression.instructions[programCounter])
            } else {
                try self.exit(label: label)
            }
        } else {
            if let address = stack.currentFrame.address {
                interceptor?.onExitFunction(address, store: store)
            }
            let values = try stack.popValues(count: stack.currentFrame.arity)
            try stack.popFrame()
            stack.push(values: values)
        }
    }

    public func run() throws {
        while stack.currentFrame != nil {
            try step()
        }
    }

    public func getGlobal(_ moduleInstance: ModuleInstance, globalName: String) throws -> Value {
        guard case let .global(address) = moduleInstance.exportInstances.first(where: { $0.name == globalName })?.value else {
            throw Trap._raw("no global export with name \(globalName) in a module instance \(moduleInstance)")
        }

        return store.globals[address].value
    }

    public func invoke(_ moduleInstance: ModuleInstance, function: String, with parameters: [Value] = []) throws -> [Value] {
        guard case let .function(address)? = moduleInstance.exports[function] else {
            throw Trap.exportedFunctionNotFound(moduleInstance, name: function)
        }
        return try invoke(address, with: parameters)
    }

    /// Invokes a function of the given address with the given parameters.
    public func invoke(_ address: FunctionAddress, with parameters: [Value] = []) throws -> [Value] {
        do {
            try invoke(functionAddress: address, with: parameters)
            try run()

            return try stack.popTopValues()
        } catch {
            cleanUpStack()
            throw error
        }
    }

    private func check(functionType: FunctionType, parameters: [Value]) throws {
        let parameterTypes = parameters.map { $0.type }

        guard parameterTypes == functionType.parameters else {
            throw Trap._raw("parameters types don't match, expected \(functionType.parameters), got \(parameterTypes)")
        }
    }

    private func check(functionType: FunctionType, results: [Value]) throws {
        let resultTypes = results.map { $0.type }

        guard resultTypes == functionType.results else {
            throw Trap._raw("result types don't match, expected \(functionType.results), got \(resultTypes)")
        }
    }

    private func invoke(functionAddress address: FunctionAddress, with parameters: [Value]) throws {
        switch try store.function(at: address) {
        case let .host(function):
            try check(functionType: function.type, parameters: parameters)

            let parameters = try stack.popValues(count: function.type.parameters.count)

            let caller = Caller(store: store, instance: stack.currentFrame.module)
            let results = try function.implementation(caller, parameters)
            try check(functionType: function.type, results: results)
            stack.push(values: results)

        case let .wasm(function, _):
            try check(functionType: function.type, parameters: parameters)
            stack.push(values: parameters)

            try invoke(functionAddress: address)
        }
    }
}

extension Runtime {
    func execute(_ instruction: Instruction) throws {
        switch instruction {
        case let .control(instruction):
            return try instruction.execute(runtime: self)

        case let .memory(instruction):
            try instruction.execute(&stack, store)

        case let .numeric(instruction):
            try instruction.execute(&stack)

        case let .parametric(instruction):
            try instruction.execute(&stack)

        case let .reference(instruction):
            try instruction.execute(&stack)

        case let .table(instruction):
            try instruction.execute(runtime: self)

        case let .variable(instruction):
            try instruction.execute(&stack, &store.globals)
        case .pseudo:
            // Structured pseudo instructions (end/else) should not appear at runtime
            throw Trap.unreachable
        }

        programCounter += 1
    }

    func branch(labelIndex: Int) throws {
        let label = try stack.getLabel(index: Int(labelIndex))
        let values = try stack.popValues(count: label.arity)

        var lastLabel: Label?
        for _ in 0...labelIndex {
            stack.discardTopValues()
            lastLabel = try stack.popLabel()
        }

        stack.push(values: values)
        programCounter = lastLabel!.continuation
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#entering-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    func enter(_ expression: Expression, continuation: Int, arity: Int) {
        let exit = programCounter + 1
        let label = Label(arity: arity, expression: expression, continuation: continuation, exit: exit)
        stack.push(label: label)
        programCounter = label.expression.instructions.startIndex
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#exiting-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    func exit(label: Label) throws {
        let values = try stack.popTopValues()
        let lastLabel = try stack.popLabel()
        assert(lastLabel == label)
        stack.push(values: values)
        programCounter = label.exit
    }
}
