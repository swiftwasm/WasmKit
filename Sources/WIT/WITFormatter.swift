/// Formats WIT AST nodes to canonical WIT text.
///
/// The output format matches `wasm-tools component wit --all-features --no-docs`:
/// - 2-space indentation
/// - Trailing commas in variant/enum/flags cases
/// - Blank lines between interface-level items
/// - No doc comments
/// - Attributes on their own line before the item
///
/// Output is written line by line to the `TextOutputStream` sink stored on the formatter, so a
/// caller can drive it into a streaming destination instead of the formatter forcing a whole-document
/// `String`. `String` conforms to `TextOutputStream`; the static `format(package:)` convenience uses
/// that to return the rendered text for callers that want a `String`.
public struct WITFormatter<Output: TextOutputStream>: ~Copyable {
    public private(set) var output: Output

    public init(output: Output) {
        self.output = output
    }

    // MARK: - Package

    /// Write an entire package (all source files merged) as canonical WIT text.
    public mutating func write(package: PackageUnit) {
        output.write("package \(package.packageName);\n")

        // Collect all interfaces and worlds across source files
        var interfaces: [SyntaxNode<InterfaceSyntax>] = []
        var worlds: [SyntaxNode<WorldSyntax>] = []
        for sourceFile in package.sourceFiles {
            for item in sourceFile.items {
                switch item {
                case .interface(let iface): interfaces.append(iface)
                case .world(let world): worlds.append(world)
                case .use: break
                }
            }
        }

        for iface in interfaces {
            output.write("\n")
            write(interface: iface.syntax, indent: 0)
        }
        for world in worlds {
            output.write("\n")
            write(world: world.syntax, indent: 0)
        }
    }

    // MARK: - Top-level items

    mutating func write(interface: InterfaceSyntax, indent: Int) {
        writeAttributes(interface.attributes, indent: indent)
        line("interface \(ident(interface.name)) {", indent: indent)
        writeInterfaceItems(interface.items, indent: indent + 1)
        line("}", indent: indent)
    }

    mutating func write(world: WorldSyntax, indent: Int) {
        writeAttributes(world.attributes, indent: indent)
        line("world \(ident(world.name)) {", indent: indent)
        for item in world.items {
            switch item {
            case .import(let imp):
                writeAttributes(imp.attributes, indent: indent + 1)
                line("import \(formatExternKind(imp.kind));", indent: indent + 1)
            case .export(let exp):
                writeAttributes(exp.attributes, indent: indent + 1)
                line("export \(formatExternKind(exp.kind));", indent: indent + 1)
            case .use(let use):
                writeUse(use.syntax, indent: indent + 1)
            case .type(let typeDef):
                writeTypeDef(typeDef.syntax, indent: indent + 1)
            case .include(let include):
                writeInclude(include, indent: indent + 1)
            }
        }
        line("}", indent: indent)
    }

    // MARK: - Interface items

    mutating func writeInterfaceItems(_ items: [InterfaceItemSyntax], indent: Int) {
        // Canonical order: use statements, type definitions, functions
        let sorted = items.sorted { a, b in
            func rank(_ item: InterfaceItemSyntax) -> Int {
                switch item {
                case .use: return 0
                case .typeDef: return 1
                case .function: return 2
                }
            }
            return rank(a) < rank(b)
        }
        for (i, item) in sorted.enumerated() {
            // Blank line between items, except between consecutive use statements
            if i > 0 {
                let prevIsUse = {
                    if case .use = sorted[i - 1] { return true }
                    return false
                }()
                let currIsUse = {
                    if case .use = item { return true }
                    return false
                }()
                if !(prevIsUse && currIsUse) {
                    output.write("\n")
                }
            }
            switch item {
            case .typeDef(let typeDef):
                writeTypeDef(typeDef.syntax, indent: indent)
            case .function(let namedFunc):
                writeAttributes(namedFunc.attributes, indent: indent)
                line("\(ident(namedFunc.name)): \(formatFunc(namedFunc.function));", indent: indent)
            case .use(let use):
                writeUse(use.syntax, indent: indent)
            }
        }
    }

    // MARK: - Type definitions

    mutating func writeTypeDef(_ typeDef: TypeDefSyntax, indent: Int) {
        writeAttributes(typeDef.attributes, indent: indent)
        switch typeDef.body {
        case .alias(let alias):
            line("type \(ident(typeDef.name)) = \(formatTypeRepr(alias.typeRepr));", indent: indent)
        case .record(let record):
            line("record \(ident(typeDef.name)) {", indent: indent)
            for field in record.fields {
                line("\(ident(field.name)): \(formatTypeRepr(field.type)),", indent: indent + 1)
            }
            line("}", indent: indent)
        case .variant(let variant):
            line("variant \(ident(typeDef.name)) {", indent: indent)
            for c in variant.cases {
                if let type = c.type {
                    line("\(ident(c.name))(\(formatTypeRepr(type))),", indent: indent + 1)
                } else {
                    line("\(ident(c.name)),", indent: indent + 1)
                }
            }
            line("}", indent: indent)
        case .enum(let enumType):
            line("enum \(ident(typeDef.name)) {", indent: indent)
            for c in enumType.cases {
                line("\(ident(c.name)),", indent: indent + 1)
            }
            line("}", indent: indent)
        case .flags(let flags):
            line("flags \(ident(typeDef.name)) {", indent: indent)
            for f in flags.flags {
                line("\(ident(f.name)),", indent: indent + 1)
            }
            line("}", indent: indent)
        case .resource(let resource):
            if resource.functions.isEmpty {
                line("resource \(ident(typeDef.name));", indent: indent)
            } else {
                line("resource \(ident(typeDef.name)) {", indent: indent)
                for resourceFunc in resource.functions {
                    writeResourceFunc(resourceFunc, indent: indent + 1)
                }
                line("}", indent: indent)
            }
        case .union(let union):
            line("union \(ident(typeDef.name)) {", indent: indent)
            for c in union.cases {
                line("\(formatTypeRepr(c.type)),", indent: indent + 1)
            }
            line("}", indent: indent)
        }
    }

    // MARK: - Resource functions

    mutating func writeResourceFunc(_ resourceFunc: ResourceFunctionSyntax, indent: Int) {
        switch resourceFunc {
        case .constructor(let namedFunc):
            writeAttributes(namedFunc.attributes, indent: indent)
            let params = formatParams(namedFunc.function.parameters)
            line("constructor(\(params));", indent: indent)
        case .method(let namedFunc):
            writeAttributes(namedFunc.attributes, indent: indent)
            line("\(ident(namedFunc.name)): \(formatFunc(namedFunc.function));", indent: indent)
        case .static(let namedFunc):
            writeAttributes(namedFunc.attributes, indent: indent)
            line("\(ident(namedFunc.name)): static \(formatFunc(namedFunc.function));", indent: indent)
        }
    }

    // MARK: - Use statements

    mutating func writeUse(_ use: UseSyntax, indent: Int) {
        writeAttributes(use.attributes, indent: indent)
        let names = use.names.map { name in
            if let asName = name.asName {
                return "\(ident(name.name)) as \(ident(asName))"
            }
            return ident(name.name)
        }.joined(separator: ", ")
        line("use \(formatUsePath(use.from)).{\(names)};", indent: indent)
    }

    // MARK: - Include

    mutating func writeInclude(_ include: IncludeSyntax, indent: Int) {
        writeAttributes(include.attributes, indent: indent)
        var text = "include \(formatUsePath(include.from))"
        if !include.names.isEmpty {
            let names = include.names.map { "\(ident($0.name)) as \(ident($0.asName))" }.joined(separator: ", ")
            text += " with { \(names) }"
        }
        line(text + ";", indent: indent)
    }

    // MARK: - Attributes

    mutating func writeAttributes(_ attrs: [AttributeSyntax], indent: Int) {
        for attr in attrs {
            switch attr {
            case .since(let since):
                var text = "@since(version = \(since.version)"
                if let feature = since.feature {
                    text += ", feature = \(ident(feature))"
                }
                text += ")"
                line(text, indent: indent)
            case .unstable(let unstable):
                line("@unstable(feature = \(ident(unstable.feature)))", indent: indent)
            case .deprecated(let deprecated):
                line("@deprecated(version = \(deprecated.version))", indent: indent)
            }
        }
    }

    // MARK: - Functions

    func formatFunc(_ func_: FunctionSyntax) -> String {
        let params = formatParams(func_.parameters)
        let results = formatResults(func_.results)
        if results.isEmpty {
            return "func(\(params))"
        }
        return "func(\(params)) -> \(results)"
    }

    func formatParams(_ params: ParameterList) -> String {
        params.map { "\(ident($0.name)): \(formatTypeRepr($0.type))" }.joined(separator: ", ")
    }

    func formatResults(_ results: ResultListSyntax) -> String {
        switch results {
        case .named(let params):
            if params.isEmpty { return "" }
            if params.count == 1 {
                return "\(ident(params[0].name)): \(formatTypeRepr(params[0].type))"
            }
            let inner = params.map { "\(ident($0.name)): \(formatTypeRepr($0.type))" }.joined(separator: ", ")
            return "(\(inner))"
        case .anon(let typeRepr):
            return formatTypeRepr(typeRepr)
        }
    }

    // MARK: - Type representations

    func formatTypeRepr(_ type: TypeReprSyntax) -> String {
        switch type {
        case .bool: return "bool"
        case .u8: return "u8"
        case .u16: return "u16"
        case .u32: return "u32"
        case .u64: return "u64"
        case .s8: return "s8"
        case .s16: return "s16"
        case .s32: return "s32"
        case .s64: return "s64"
        case .float32: return "f32"
        case .float64: return "f64"
        case .char: return "char"
        case .string: return "string"
        case .name(let id): return ident(id)
        case .list(let element): return "list<\(formatTypeRepr(element))>"
        case .option(let wrapped): return "option<\(formatTypeRepr(wrapped))>"
        case .tuple(let types):
            return "tuple<\(types.map { formatTypeRepr($0) }.joined(separator: ", "))>"
        case .handle(.own(let resource)): return "own<\(ident(resource))>"
        case .handle(.borrow(let resource)): return "borrow<\(ident(resource))>"
        case .result(let result):
            switch (result.ok, result.error) {
            case (nil, nil): return "result"
            case (.some(let ok), nil): return "result<\(formatTypeRepr(ok))>"
            case (nil, .some(let err)): return "result<_, \(formatTypeRepr(err))>"
            case (.some(let ok), .some(let err)): return "result<\(formatTypeRepr(ok)), \(formatTypeRepr(err))>"
            }
        case .future(let element):
            if let element { return "future<\(formatTypeRepr(element))>" }
            return "future"
        case .stream(let stream):
            switch (stream.element, stream.end) {
            case (nil, nil): return "stream"
            case (.some(let element), nil): return "stream<\(formatTypeRepr(element))>"
            case (nil, .some(let end)): return "stream<_, \(formatTypeRepr(end))>"
            case (.some(let element), .some(let end)): return "stream<\(formatTypeRepr(element)), \(formatTypeRepr(end))>"
            }
        }
    }

    // MARK: - Extern kinds

    func formatExternKind(_ kind: ExternKindSyntax) -> String {
        switch kind {
        case .path(let path): return formatUsePath(path)
        case .function(let name, let function):
            return "\(ident(name)): \(formatFunc(function))"
        case .interface(let name, _):
            // Inline interface (rare in WASIp2). The body payload is not rendered.
            return "\(ident(name)): interface { ... }"
        }
    }

    // MARK: - Use paths

    func formatUsePath(_ path: UsePathSyntax) -> String {
        switch path {
        case .id(let id): return ident(id)
        case .package(let packageName, let name):
            // WIT format: ns:pkg/iface@version (version after interface name)
            var text = "\(packageName.namespace.text):\(packageName.name.text)/\(ident(name))"
            if let version = packageName.version {
                text += "@\(version)"
            }
            return text
        }
    }

    // MARK: - Helpers

    func ident(_ id: Identifier) -> String {
        let text = id.text
        if witKeywords.contains(text) {
            return "%\(text)"
        }
        return text
    }

    private mutating func line(_ text: String, indent: Int) {
        output.write(String(repeating: "  ", count: indent) + text + "\n")
    }
}

/// WIT keywords and built-in type names that need `%` escaping when used as identifiers.
/// File-scope because Swift forbids stored `static let` in a generic type.
private let witKeywords: Set<String> = [
    // Structural keywords
    "use", "type", "resource", "func", "record", "enum", "flags",
    "variant", "static", "interface", "world", "import", "export",
    "package", "include", "constructor", "with", "union",
    // Built-in type names
    "bool", "char", "string",
    "u8", "u16", "u32", "u64",
    "s8", "s16", "s32", "s64",
    "f32", "f64", "float32", "float64",
    "list", "option", "result", "tuple",
    "future", "stream",
    "own", "borrow",
]

// MARK: - String convenience

extension WITFormatter where Output == String {
    /// Format an entire package (all source files merged) to canonical WIT text.
    public static func format(package: PackageUnit) -> String {
        var formatter = WITFormatter(output: "")
        formatter.write(package: package)
        return formatter.output
    }
}
