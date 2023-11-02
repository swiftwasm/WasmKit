import WIT

enum ConvertCase {
    static func pascalCase(_ ident: Identifier) throws -> String {
        return pascalCase(kebab: ident.text)
    }

    static func pascalCase(kebab text: String) -> String {
        var id = ""
        for component in text.split(separator: "-") {
            id += component[component.startIndex].uppercased()
            id += component[component.index(after: component.startIndex)...]
        }
        return id
    }

    static func camelCase(_ ident: Identifier) throws -> String {
        return camelCase(kebab: ident.text)
    }

    static func camelCase(kebab text: String) -> String {
        let components = text.split(separator: "-")
        return camelCase(components.map(String.init))
    }

    static func camelCase(_ components: [String]) -> String {
        var id = "\(components[0])"
        for component in components.dropFirst() {
            id += component[component.startIndex].uppercased()
            id += component[component.index(after: component.startIndex)...]
        }
        return id
    }
}
