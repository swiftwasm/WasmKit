import WIT

enum CanonicalFunctionName {
    case world(String)
    case interface(PackageNameSyntax, interfaceName: String, id: String)

    var abiName: String {
        switch self {
        case .world(let id): return id
        case .interface(let packageName, let interfaceName, let id):
            return "\(packageName.namespace.text):\(packageName.name.text)/\(interfaceName)#\(id)"
        }
    }

    var uniqueSwiftName: String {
        switch self {
        case .world(let id):
            return ConvertCase.camelCase(kebab: id)
        case .interface(let packageName, let interfaceName, let id):
            return ConvertCase.camelCase(kebab: packageName.namespace.text) + "_"
                + ConvertCase.camelCase(kebab: packageName.name.text) + "_"
                + ConvertCase.camelCase(kebab: interfaceName) + "_"
                + ConvertCase.camelCase(kebab: id)
        }
    }

    var apiSwiftName: String {
        switch self {
        case .world(let id), .interface(_, _, let id):
            return ConvertCase.camelCase(kebab: id)
        }
    }
}
