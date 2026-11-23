/// Writes WIT syntax as WIT text.
///
/// Items keep their source order. Each item and each attribute takes its own line, indented by two
/// spaces per level. A blank line separates the items of a source file and of an interface, except
/// two `use` items in a row. The items of a world follow one another without blank lines. Every field
/// and case in a braced list ends with a comma.
public struct WITFormatter<Output: TextOutputStream>: ~Copyable {
    public private(set) var output: Output

    /// Whether to write the comments in front of each item, which WIT tools read as its documentation.
    public let includeDocs: Bool

    public init(output: Output, includeDocs: Bool = true) {
        self.output = output
        self.includeDocs = includeDocs
    }

    // MARK: - Source files

    public mutating func write(sourceFile: SourceFileSyntax) {
        var previousIsUse: Bool?
        if let packageId = sourceFile.packageId {
            line("package \(formatPackageName(packageId));", indent: 0)
            previousIsUse = false
        }
        for item in sourceFile.items {
            let isUse: Bool
            if case .use = item { isUse = true } else { isUse = false }
            writeSeparator(isUse: isUse, previousIsUse: previousIsUse)
            switch item {
            case .interface(let interface): write(interface: interface.syntax, indent: 0)
            case .world(let world): write(world: world.syntax, indent: 0)
            case .use(let use): writeTopLevelUse(use.syntax)
            }
            previousIsUse = isUse
        }
    }

    // MARK: - Top-level items

    mutating func write(interface: InterfaceSyntax, indent: Int) {
        writeDocsAndAttributes(interface.documents, interface.attributes, indent: indent)
        line("interface \(ident(interface.name)) {", indent: indent)
        writeInterfaceItems(interface.items, indent: indent + 1)
        line("}", indent: indent)
    }

    mutating func write(world: WorldSyntax, indent: Int) {
        writeDocsAndAttributes(world.documents, world.attributes, indent: indent)
        line("world \(ident(world.name)) {", indent: indent)
        for item in world.items {
            switch item {
            case .import(let imp):
                writeDocsAndAttributes(imp.documents, imp.attributes, indent: indent + 1)
                writeExtern("import", imp.kind, indent: indent + 1)
            case .export(let exp):
                writeDocsAndAttributes(exp.documents, exp.attributes, indent: indent + 1)
                writeExtern("export", exp.kind, indent: indent + 1)
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

    mutating func writeTopLevelUse(_ use: TopLevelUseSyntax) {
        writeAttributes(use.attributes, indent: 0)
        var text = "use \(formatUsePath(use.item))"
        if let asName = use.asName {
            text += " as \(ident(asName))"
        }
        line(text + ";", indent: 0)
    }

    // MARK: - Interface items

    mutating func writeInterfaceItems(_ items: [InterfaceItemSyntax], indent: Int) {
        var previousIsUse: Bool?
        for item in items {
            let isUse: Bool
            if case .use = item { isUse = true } else { isUse = false }
            writeSeparator(isUse: isUse, previousIsUse: previousIsUse)
            switch item {
            case .typeDef(let typeDef):
                writeTypeDef(typeDef.syntax, indent: indent)
            case .function(let namedFunc):
                writeDocsAndAttributes(namedFunc.documents, namedFunc.attributes, indent: indent)
                line("\(ident(namedFunc.name)): \(formatFunc(namedFunc.function));", indent: indent)
            case .use(let use):
                writeUse(use.syntax, indent: indent)
            }
            previousIsUse = isUse
        }
    }

    // MARK: - Type definitions

    mutating func writeTypeDef(_ typeDef: TypeDefSyntax, indent: Int) {
        writeDocsAndAttributes(typeDef.documents, typeDef.attributes, indent: indent)
        switch typeDef.body {
        case .alias(let alias):
            line("type \(ident(typeDef.name)) = \(formatTypeRepr(alias.typeRepr));", indent: indent)
        case .record(let record):
            line("record \(ident(typeDef.name)) {", indent: indent)
            for field in record.fields {
                writeDocs(field.documents, indent: indent + 1)
                line("\(ident(field.name)): \(formatTypeRepr(field.type)),", indent: indent + 1)
            }
            line("}", indent: indent)
        case .variant(let variant):
            line("variant \(ident(typeDef.name)) {", indent: indent)
            for c in variant.cases {
                writeDocs(c.documents, indent: indent + 1)
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
                writeDocs(c.documents, indent: indent + 1)
                line("\(ident(c.name)),", indent: indent + 1)
            }
            line("}", indent: indent)
        case .flags(let flags):
            line("flags \(ident(typeDef.name)) {", indent: indent)
            for f in flags.flags {
                writeDocs(f.documents, indent: indent + 1)
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
                writeDocs(c.documents, indent: indent + 1)
                line("\(formatTypeRepr(c.type)),", indent: indent + 1)
            }
            line("}", indent: indent)
        }
    }

    // MARK: - Resource functions

    mutating func writeResourceFunc(_ resourceFunc: ResourceFunctionSyntax, indent: Int) {
        switch resourceFunc {
        case .constructor(let namedFunc):
            writeDocsAndAttributes(namedFunc.documents, namedFunc.attributes, indent: indent)
            let params = formatParams(namedFunc.function.parameters)
            line("constructor(\(params));", indent: indent)
        case .method(let namedFunc):
            writeDocsAndAttributes(namedFunc.documents, namedFunc.attributes, indent: indent)
            line("\(ident(namedFunc.name)): \(formatFunc(namedFunc.function));", indent: indent)
        case .static(let namedFunc):
            writeDocsAndAttributes(namedFunc.documents, namedFunc.attributes, indent: indent)
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

    // MARK: - Docs and attributes

    mutating func writeDocs(_ documents: DocumentsSyntax, indent: Int) {
        guard includeDocs else { return }
        for comment in documents.comments {
            // A line comment's text ends with its newline.
            var text = Substring(comment)
            while text.last?.isNewline == true {
                text.removeLast()
            }
            line(String(text), indent: indent)
        }
    }

    mutating func writeDocsAndAttributes(_ documents: DocumentsSyntax, _ attributes: [AttributeSyntax], indent: Int) {
        writeDocs(documents, indent: indent)
        writeAttributes(attributes, indent: indent)
    }

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
        let keyword = func_.isAsync ? "async func" : "func"
        if results.isEmpty {
            return "\(keyword)(\(params))"
        }
        return "\(keyword)(\(params)) -> \(results)"
    }

    func formatParams(_ params: ParameterList) -> String {
        params.map { "\(ident($0.name)): \(formatTypeRepr($0.type))" }.joined(separator: ", ")
    }

    func formatResults(_ results: ResultListSyntax) -> String {
        switch results {
        case .named(let params):
            if params.isEmpty { return "" }
            return "(\(formatParams(params)))"
        case .anon(let typeRepr):
            return formatTypeRepr(typeRepr)
        }
    }

    // MARK: - Type representations

    func formatTypeRepr(_ type: TypeReprSyntax) -> String {
        switch type {
        case .bool: return WITKeyword.bool.rawValue
        case .u8: return WITKeyword.u8.rawValue
        case .u16: return WITKeyword.u16.rawValue
        case .u32: return WITKeyword.u32.rawValue
        case .u64: return WITKeyword.u64.rawValue
        case .s8: return WITKeyword.s8.rawValue
        case .s16: return WITKeyword.s16.rawValue
        case .s32: return WITKeyword.s32.rawValue
        case .s64: return WITKeyword.s64.rawValue
        case .float32: return WITKeyword.f32.rawValue
        case .float64: return WITKeyword.f64.rawValue
        case .char: return WITKeyword.char.rawValue
        case .string: return WITKeyword.string.rawValue
        case .name(let id): return ident(id)
        case .list(let element): return "\(WITKeyword.list.rawValue)<\(formatTypeRepr(element))>"
        case .option(let wrapped): return "\(WITKeyword.option.rawValue)<\(formatTypeRepr(wrapped))>"
        case .tuple(let types):
            return "\(WITKeyword.tuple.rawValue)<\(types.map { formatTypeRepr($0) }.joined(separator: ", "))>"
        case .handle(.own(let resource)): return "\(WITKeyword.own.rawValue)<\(ident(resource))>"
        case .handle(.borrow(let resource)): return "\(WITKeyword.borrow.rawValue)<\(ident(resource))>"
        case .result(let result):
            let name = WITKeyword.result.rawValue
            switch (result.ok, result.error) {
            case (nil, nil): return name
            case (.some(let ok), nil): return "\(name)<\(formatTypeRepr(ok))>"
            case (nil, .some(let err)): return "\(name)<\(WITKeyword.underscore.rawValue), \(formatTypeRepr(err))>"
            case (.some(let ok), .some(let err)): return "\(name)<\(formatTypeRepr(ok)), \(formatTypeRepr(err))>"
            }
        case .future(let element):
            let name = WITKeyword.future.rawValue
            if let element { return "\(name)<\(formatTypeRepr(element))>" }
            return name
        case .stream(let stream):
            let name = WITKeyword.stream.rawValue
            switch (stream.element, stream.end) {
            case (nil, nil): return name
            case (.some(let element), nil): return "\(name)<\(formatTypeRepr(element))>"
            case (nil, .some(let end)): return "\(name)<\(WITKeyword.underscore.rawValue), \(formatTypeRepr(end))>"
            case (.some(let element), .some(let end)): return "\(name)<\(formatTypeRepr(element)), \(formatTypeRepr(end))>"
            }
        }
    }

    // MARK: - Extern kinds

    mutating func writeExtern(_ keyword: String, _ kind: ExternKindSyntax, indent: Int) {
        switch kind {
        case .path(let path):
            line("\(keyword) \(formatUsePath(path));", indent: indent)
        case .function(let name, let function):
            line("\(keyword) \(ident(name)): \(formatFunc(function));", indent: indent)
        case .interface(let name, let items):
            line("\(keyword) \(ident(name)): interface {", indent: indent)
            writeInterfaceItems(items, indent: indent + 1)
            line("}", indent: indent)
        }
    }

    // MARK: - Use paths

    func formatPackageName(_ packageName: PackageNameSyntax) -> String {
        var text = "\(ident(packageName.namespace)):\(ident(packageName.name))"
        if let version = packageName.version {
            text += "@\(version)"
        }
        return text
    }

    func formatUsePath(_ path: UsePathSyntax) -> String {
        switch path {
        case .id(let id): return ident(id)
        case .package(let packageName, let name):
            // WIT format: ns:pkg/iface@version (version after interface name)
            var text = "\(ident(packageName.namespace)):\(ident(packageName.name))/\(ident(name))"
            if let version = packageName.version {
                text += "@\(version)"
            }
            return text
        }
    }

    // MARK: - Helpers

    func ident(_ id: Identifier) -> String {
        WITKeyword(rawValue: id.text) == nil ? id.text : "%\(id.text)"
    }

    private mutating func writeSeparator(isUse: Bool, previousIsUse: Bool?) {
        if let previousIsUse, !(previousIsUse && isUse) {
            output.write("\n")
        }
    }

    private mutating func line(_ text: String, indent: Int) {
        output.write(String(repeating: "  ", count: indent) + text + "\n")
    }
}

// MARK: - String convenience

extension WITFormatter where Output == String {
    public static func format(sourceFile: SourceFileSyntax, includeDocs: Bool = true) -> String {
        var formatter = WITFormatter(output: "", includeDocs: includeDocs)
        formatter.write(sourceFile: sourceFile)
        return formatter.output
    }
}
