import WasmParser
import WasmTypes

/// The ids of a module's index spaces, and the text of types that refer to them.
struct ModuleNames {
    let functions: IdentifierTable
    let types: IdentifierTable
    let tables: IdentifierTable
    let memories: IdentifierTable
    let globals: IdentifierTable
    let tags: IdentifierTable
    let elements: IdentifierTable
    let data: IdentifierTable

    init(info: ModuleInfo) {
        functions = IdentifierTable(names: info.functionNames)
        types = IdentifierTable(names: info.typeNames)
        tables = IdentifierTable(names: info.tableNames)
        memories = IdentifierTable(names: info.memoryNames)
        globals = IdentifierTable(names: info.globalNames)
        tags = IdentifierTable(names: info.tagNames)
        elements = IdentifierTable(names: info.elementNames)
        data = IdentifierTable(names: info.dataNames)
    }

    func valueType(_ type: ValueType) -> String {
        switch type {
        case .i32: return "i32"
        case .i64: return "i64"
        case .f32: return "f32"
        case .f64: return "f64"
        case .v128: return "v128"
        case .ref(let reference): return refType(reference)
        }
    }

    func refType(_ type: ReferenceType) -> String {
        if type.isNullable {
            if type.heapType == .funcRef { return "funcref" }
            if type.heapType == .externRef { return "externref" }
            return "(ref null \(heapType(type.heapType)))"
        }
        return "(ref \(heapType(type.heapType)))"
    }

    func heapType(_ type: HeapType) -> String {
        switch type {
        case .abstract(let abstract):
            switch abstract {
            case .funcRef: return "func"
            case .externRef: return "extern"
            case .exnRef: return "exn"
            case .any: return "any"
            case .eq: return "eq"
            case .i31: return "i31"
            case .structRef: return "struct"
            case .arrayRef: return "array"
            case .noneRef: return "none"
            case .noExtern: return "noextern"
            case .noFunc: return "nofunc"
            case .noExn: return "noexn"
            }
        case .concrete(let typeIndex):
            return types.reference(typeIndex)
        }
    }
}
