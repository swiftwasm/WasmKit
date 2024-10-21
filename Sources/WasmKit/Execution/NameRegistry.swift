import struct WasmParser.CustomSection
import struct WasmParser.NameMap
import struct WasmParser.NameSectionParser
import class WasmParser.StaticByteStream

struct NameRegistry {
    private var functionNames: [InternalFunction: String] = [:]
    private var materializers: [(inout NameRegistry) throws -> Void] = []

    init() {}

    mutating func register(instance: InternalInstance, nameSection: CustomSection) throws {
        materializers.append { registry in
            let stream = StaticByteStream(bytes: Array(nameSection.bytes))
            let parser = NameSectionParser(stream: stream)
            for result in try parser.parseAll() {
                switch result {
                case .functions(let nameMap):
                    registry.register(instance: instance, nameMap: nameMap)
                }
            }

            for (name, entry) in instance.exports {
                // Use exported name if the function doesn't have name in name section.
                guard case .function(let function) = entry else { continue }
                guard registry.functionNames[function] == nil else { continue }
                registry.functionNames[function] = name
            }
        }
    }

    private mutating func register(instance: InternalInstance, nameMap: NameMap) {
        for (index, name) in nameMap {
            let addr = instance.functions[Int(index)]
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

    mutating func lookup(_ addr: InternalFunction) throws -> String? {
        try materializeIfNeeded()
        return functionNames[addr]
    }

    mutating func symbolicate(_ function: InternalFunction) -> String {
        if let name = try? lookup(function) {
            return name
        }
        // Fallback
        if function.isWasm {
            return "wasm function[\(function.wasm.index)]"
        } else {
            return "unknown host function"
        }
    }
}
