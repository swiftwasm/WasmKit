import struct WasmParser.CustomSection
import struct WasmParser.NameMap
import struct WasmParser.NameSectionParser
import class WasmParser.StaticByteStream
import struct WasmParser.WasmParserError

struct NameRegistry {
    typealias Materializer = (inout NameRegistry) throws(WasmParserError) -> Void
    private var functionNames: [InternalFunction: String] = [:]
    private var materializers: [Materializer] = []

    init() {}

    mutating func register(instance: InternalInstance, nameSection: CustomSection) {
        let materializer: Materializer = { (registry: inout NameRegistry) throws(WasmParserError) in
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
        materializers.append(materializer)
    }

    private mutating func register(instance: InternalInstance, nameMap: NameMap) {
        for (index, name) in nameMap {
            let addr = instance.functions[Int(index)]
            self.functionNames[addr] = name
        }
    }

    private mutating func materializeIfNeeded() throws(WasmParserError) {
        guard !materializers.isEmpty else { return }
        for materialize in materializers {
            try materialize(&self)
        }
        materializers = []
    }

    mutating func lookup(_ addr: InternalFunction) throws(WasmParserError) -> String? {
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
