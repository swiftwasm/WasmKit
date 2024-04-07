import struct WasmParser.NameSectionParser

struct NameRegistry {
    private var functionNames: [FunctionAddress: String] = [:]
    private var materializers: [(inout NameRegistry) throws -> Void] = []

    init() {}

    mutating func register(instance: ModuleInstance, nameSection: CustomSection) throws {
        materializers.append { registry in
            let stream = LegacyStaticByteStream(bytes: Array(nameSection.bytes))
            let parser = NameSectionParser(stream: stream)
            for result in try parser.parseAll() {
                switch result {
                case .functions(let nameMap):
                    registry.register(instance: instance, nameMap: nameMap)
                }
            }
        }
    }

    private mutating func register(instance: ModuleInstance, nameMap: NameSectionParser.NameMap) {
        for (index, name) in nameMap {
            let addr = instance.functionAddresses[Int(index)]
            self.functionNames[addr] = name
        }
    }

    private mutating func materializeIfNeeded() throws {
        guard !materializers.isEmpty else { return }
        for materialize in materializers {
            try materialize(&self)
        }
        materializers = []
    }

    mutating func lookup(_ addr: FunctionAddress) throws -> String? {
        try materializeIfNeeded()
        return functionNames[addr]
    }
}
