/// `WITExtractor.runWithoutHeader` resolves WIT-name collisions before building this, so each WIT name
/// has one entry.
package struct SwiftSourceSummary {
    private struct TypeInfo {
        let qualifiedSwiftName: String
        let enumCaseNames: [String]?  // declaration order; nil for structs
        let recordFieldNames: [String]?  // declaration order; nil for enums
    }

    private let typesByWITName: [String: TypeInfo]
    /// In emitted-param order; a function with any unresolved param is dropped wholesale, so the list is
    /// never partial. nil element means unlabeled (`_`).
    private let argumentLabelsByWITName: [String: [String?]]

    init(inventory: DeclInventory) {
        var types: [String: TypeInfo] = [:]
        for type in inventory.types {
            let cases = type.kind == .enumType ? type.cases.map(\.name) : nil
            let fields = type.kind == .structType ? type.fields.map(\.name) : nil
            types[type.witName] = TypeInfo(
                qualifiedSwiftName: type.swiftQualifiedName, enumCaseNames: cases, recordFieldNames: fields)
        }
        self.typesByWITName = types

        var labels: [String: [String?]] = [:]
        for function in inventory.functions {
            labels[function.witName] = function.parameters.map(\.externalLabel)
        }
        self.argumentLabelsByWITName = labels
    }

    package func qualifiedSwiftName(byWITName witName: String) -> String? {
        typesByWITName[witName]?.qualifiedSwiftName
    }

    /// nil for a struct or an absent type.
    package func enumCaseNames(byWITName witName: String) -> [String]? {
        typesByWITName[witName]?.enumCaseNames
    }

    /// nil for an enum or an absent type.
    package func recordFieldNames(byWITName witName: String) -> [String]? {
        typesByWITName[witName]?.recordFieldNames
    }

    package func argumentLabels(byWITFunctionName witName: String) -> [String?]? {
        argumentLabelsByWITName[witName]
    }
}
