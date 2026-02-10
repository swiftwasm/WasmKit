#if ComponentModel
import ComponentModel

/// Converts WIT type representations to ComponentModel types.
///
/// This converter bridges WIT (WebAssembly Interface Types) definitions
/// to the ComponentValueType system used for runtime values.
///
/// Example usage:
/// ```swift
/// let sourceFile = try SourceFileSyntax.parse(witContents, fileName: "api.wit")
/// var converter = WITTypeConverter()
///
/// // Register type definitions first
/// for typeDef in typeDefinitions {
///     converter.registerTypeDef(typeDef)
/// }
///
/// // Then convert types
/// let componentType = converter.convert(typeRepr)
/// ```
public struct WITTypeConverter {
    /// Type table for resolving indexed types
    public private(set) var typeTable: [ComponentValueType] = []

    /// Named type definitions
    public private(set) var namedTypes: [String: ComponentValueType] = [:]

    public init() {}

    /// Add a type to the table and return its index
    public mutating func addType(_ type: ComponentValueType) -> ComponentTypeIndex {
        let idx = typeTable.count
        typeTable.append(type)
        return ComponentTypeIndex(rawValue: idx)
    }

    /// Convert a WIT type representation to a ComponentValueType
    public mutating func convert(_ typeRepr: TypeReprSyntax) -> ComponentValueType {
        switch typeRepr {
        case .bool: return .bool
        case .u8: return .u8
        case .u16: return .u16
        case .u32: return .u32
        case .u64: return .u64
        case .s8: return .s8
        case .s16: return .s16
        case .s32: return .s32
        case .s64: return .s64
        case .float32: return .float32
        case .float64: return .float64
        case .char: return .char
        case .string: return .string
        case .name(let id):
            // Handle f32/f64 as aliases for float32/float64 (WIT spec uses f32/f64)
            switch id.text {
            case "f32": return .float32
            case "f64": return .float64
            default:
                // Look up named type
                if let type = namedTypes[id.text] {
                    return type
                }
                fatalError("Unknown type: \(id.text)")
            }
        case .list(let element):
            let elementType = convert(element)
            let idx = addType(elementType)
            return .list(idx)
        case .option(let inner):
            let innerType = convert(inner)
            let idx = addType(innerType)
            return .option(idx)
        case .result(let resultSyntax):
            let okIdx = resultSyntax.ok.map { ok -> ComponentTypeIndex in
                let okType = convert(ok)
                return addType(okType)
            }
            let errIdx = resultSyntax.error.map { err -> ComponentTypeIndex in
                let errType = convert(err)
                return addType(errType)
            }
            return .result(ok: okIdx, error: errIdx)
        case .tuple(let elements):
            let indices = elements.map { elem -> ComponentTypeIndex in
                let elemType = convert(elem)
                return addType(elemType)
            }
            return .tuple(indices)
        case .handle, .future, .stream:
            fatalError("Unsupported type: \(typeRepr)")
        }
    }

    /// Register a type definition, making it available for lookup by name
    public mutating func registerTypeDef(_ typeDef: TypeDefSyntax) {
        let typeName = typeDef.name.text
        let componentType: ComponentValueType

        switch typeDef.body {
        case .record(let recordSyntax):
            let fields = recordSyntax.fields.map { field -> ComponentRecordField in
                let fieldType = convert(field.type)
                let fieldIdx = addType(fieldType)
                return ComponentRecordField(name: field.name.text, type: fieldIdx)
            }
            componentType = .record(fields)
        case .enum(let enumSyntax):
            let cases = enumSyntax.cases.map { $0.name.text }
            componentType = .enum(cases)
        case .flags(let flagsSyntax):
            let flags = flagsSyntax.flags.map { $0.name.text }
            componentType = .flags(flags)
        case .variant(let variantSyntax):
            let cases = variantSyntax.cases.map { caseItem -> ComponentCaseField in
                let caseType = caseItem.type.map { type -> ComponentTypeIndex in
                    let converted = convert(type)
                    return addType(converted)
                }
                return ComponentCaseField(name: caseItem.name.text, type: caseType)
            }
            componentType = .variant(cases)
        case .alias(let aliasSyntax):
            componentType = convert(aliasSyntax.typeRepr)
        case .resource, .union:
            fatalError("Unsupported type definition: \(typeDef.body)")
        }

        namedTypes[typeName] = componentType
    }

    /// Resolve a type index to its ComponentValueType
    public func resolve(_ idx: ComponentTypeIndex) -> ComponentValueType {
        return typeTable[Int(idx.rawValue)]
    }
}

/// Helper for extracting interface information from parsed WIT
public struct WITInterfaceExtractor {
    /// Extracted function signatures
    public private(set) var functions: [String: [(name: String, type: ComponentValueType)]] = [:]

    /// The type converter used during extraction
    public private(set) var converter: WITTypeConverter

    public init() {
        self.converter = WITTypeConverter()
    }

    /// Extract function signatures from a WIT interface
    public mutating func extractInterface(_ interfaceSyntax: InterfaceSyntax) {
        // First pass: register all type definitions
        for item in interfaceSyntax.items {
            if case .typeDef(let typeDefNode) = item {
                converter.registerTypeDef(typeDefNode.syntax)
            }
        }

        // Second pass: extract function signatures
        for item in interfaceSyntax.items {
            if case .function(let funcNode) = item {
                let funcSyntax = funcNode.syntax
                let funcName = funcSyntax.name.text
                let params = funcSyntax.function.parameters.map { param -> (String, ComponentValueType) in
                    let paramType = converter.convert(param.type)
                    return (param.name.text, paramType)
                }
                functions[funcName] = params
            }
        }
    }

    /// Extract an interface by name from a parsed source file
    public mutating func extractInterface(named name: String, from sourceFile: SourceFileSyntax) -> Bool {
        for item in sourceFile.items {
            guard case .interface(let interfaceNode) = item else { continue }
            let interfaceSyntax = interfaceNode.syntax
            guard interfaceSyntax.name.text == name else { continue }
            extractInterface(interfaceSyntax)
            return true
        }
        return false
    }
}

#endif
