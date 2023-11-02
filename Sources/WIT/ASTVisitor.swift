public protocol ASTVisitor {
    mutating func visit(_ astItem: ASTItemSyntax) throws
    mutating func visit(_ topLevelUse: SyntaxNode<TopLevelUseSyntax>) throws
    mutating func visit(_ world: SyntaxNode<WorldSyntax>) throws
    mutating func visit(_ worldItem: WorldItemSyntax) throws
    mutating func visit(_ `import`: ImportSyntax) throws
    mutating func visit(_ export: ExportSyntax) throws
    mutating func visit(_ interface: SyntaxNode<InterfaceSyntax>) throws
    mutating func visit(_ interfaceItem: InterfaceItemSyntax) throws
    mutating func visit(_ typeDef: SyntaxNode<TypeDefSyntax>) throws
    mutating func visit(_ alias: TypeAliasSyntax) throws
    mutating func visit(_ handle: HandleSyntax) throws
    mutating func visit(_ resource: ResourceSyntax) throws
    mutating func visit(_ resourceFunction: ResourceFunctionSyntax) throws
    mutating func visit(_ record: RecordSyntax) throws
    mutating func visit(_ flags: FlagsSyntax) throws
    mutating func visit(_ variant: VariantSyntax) throws
    mutating func visit(_ `enum`: EnumSyntax) throws
    mutating func visit(_ namedFunction: SyntaxNode<NamedFunctionSyntax>) throws
    mutating func visit(_ union: UnionSyntax) throws
    mutating func visit(_ function: FunctionSyntax) throws
    mutating func visit(_ use: SyntaxNode<UseSyntax>) throws
    mutating func visit(_ include: IncludeSyntax) throws

    mutating func visitPost(_ astItem: ASTItemSyntax) throws
    mutating func visitPost(_ topLevelUse: SyntaxNode<TopLevelUseSyntax>) throws
    mutating func visitPost(_ world: SyntaxNode<WorldSyntax>) throws
    mutating func visitPost(_ worldItem: WorldItemSyntax) throws
    mutating func visitPost(_ `import`: ImportSyntax) throws
    mutating func visitPost(_ export: ExportSyntax) throws
    mutating func visitPost(_ interface: SyntaxNode<InterfaceSyntax>) throws
    mutating func visitPost(_ interfaceItem: InterfaceItemSyntax) throws
    mutating func visitPost(_ typeDef: SyntaxNode<TypeDefSyntax>) throws
    mutating func visitPost(_ alias: TypeAliasSyntax) throws
    mutating func visitPost(_ handle: HandleSyntax) throws
    mutating func visitPost(_ resource: ResourceSyntax) throws
    mutating func visitPost(_ resourceFunction: ResourceFunctionSyntax) throws
    mutating func visitPost(_ record: RecordSyntax) throws
    mutating func visitPost(_ flags: FlagsSyntax) throws
    mutating func visitPost(_ variant: VariantSyntax) throws
    mutating func visitPost(_ `enum`: EnumSyntax) throws
    mutating func visitPost(_ namedFunction: SyntaxNode<NamedFunctionSyntax>) throws
    mutating func visitPost(_ union: UnionSyntax) throws
    mutating func visitPost(_ function: FunctionSyntax) throws
    mutating func visitPost(_ use: SyntaxNode<UseSyntax>) throws
    mutating func visitPost(_ include: IncludeSyntax) throws
}

extension ASTVisitor {
    public mutating func walk(_ sourceFile: SourceFileSyntax) throws {
        for item in sourceFile.items {
            try walk(item)
        }
    }
    public mutating func walk(_ astItem: ASTItemSyntax) throws {
        try visit(astItem)
        switch astItem {
        case .interface(let interface): try walk(interface)
        case .world(let world): try walk(world)
        case .use(let topLevelUse): try walk(topLevelUse)
        }
        try visitPost(astItem)
    }
    public mutating func walk(_ topLevelUse: SyntaxNode<TopLevelUseSyntax>) throws {
        try visit(topLevelUse)
        try visitPost(topLevelUse)
    }
    public mutating func walk(_ world: SyntaxNode<WorldSyntax>) throws {
        try visit(world)
        for item in world.items {
            try walk(item)
        }
        try visitPost(world)
    }
    public mutating func walk(_ worldItem: WorldItemSyntax) throws {
        try visit(worldItem)
        switch worldItem {
        case .import(let `import`):
            try walk(`import`)
        case .export(let export):
            try walk(export)
        case .use(let use):
            try walk(use)
        case .type(let typeDef):
            try walk(typeDef)
        case .include(let include):
            try walk(include)
        }
        try visitPost(worldItem)
    }
    public mutating func walk(_ importItem: ImportSyntax) throws {
        try visit(importItem)
        switch importItem.kind {
        case .function(_, let function):
            try walk(function)
        case .interface(_, let items):
            for item in items {
                try walk(item)
            }
        case .path: break
        }
        try visitPost(importItem)
    }
    public mutating func walk(_ export: ExportSyntax) throws {
        try visit(export)
        switch export.kind {
        case .function(_, let function):
            try walk(function)
        case .interface(_, let items):
            for item in items {
                try walk(item)
            }
        case .path: break
        }
        try visitPost(export)
    }
    public mutating func walk(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        try visit(interface)
        for item in interface.items {
            try walk(item)
        }
        try visitPost(interface)
    }
    public mutating func walk(_ interfaceItem: InterfaceItemSyntax) throws {
        try visit(interfaceItem)
        switch interfaceItem {
        case .typeDef(let typeDef):
            try walk(typeDef)
        case .function(let namedFunction):
            try walk(namedFunction)
        case .use(let use):
            try walk(use)
        }
        try visitPost(interfaceItem)
    }
    public mutating func walk(_ typeDef: SyntaxNode<TypeDefSyntax>) throws {
        try visit(typeDef)
        let body = typeDef.body
        switch body {
        case .flags(let flags):
            try walk(flags)
        case .resource(let resource):
            try walk(resource)
        case .record(let record):
            try walk(record)
        case .variant(let variant):
            try walk(variant)
        case .union(let union):
            try walk(union)
        case .enum(let `enum`):
            try walk(`enum`)
        case .alias(let alias):
            try walk(alias)
        }
        try visitPost(typeDef)
    }
    public mutating func walk(_ alias: TypeAliasSyntax) throws {
        try visit(alias)
        try visitPost(alias)
    }
    public mutating func walk(_ handle: HandleSyntax) throws {
        try visit(handle)
        try visitPost(handle)
    }
    public mutating func walk(_ resource: ResourceSyntax) throws {
        try visit(resource)
        try visitPost(resource)
    }
    public mutating func walk(_ resourceFunction: ResourceFunctionSyntax) throws {
        try visit(resourceFunction)
        switch resourceFunction {
        case .method(let namedFunction), .static(let namedFunction), .constructor(let namedFunction):
            try walk(namedFunction)
        }
        try visitPost(resourceFunction)
    }
    public mutating func walk(_ record: RecordSyntax) throws {
        try visit(record)
        try visitPost(record)
    }
    public mutating func walk(_ flags: FlagsSyntax) throws {
        try visit(flags)
        try visitPost(flags)
    }
    public mutating func walk(_ variant: VariantSyntax) throws {
        try visit(variant)
        try visitPost(variant)
    }
    public mutating func walk(_ `enum`: EnumSyntax) throws {
        try visit(`enum`)
        try visitPost(`enum`)
    }
    public mutating func walk(_ namedFunction: SyntaxNode<NamedFunctionSyntax>) throws {
        try visit(namedFunction)
        try walk(namedFunction.function)
        try visitPost(namedFunction)
    }
    public mutating func walk(_ union: UnionSyntax) throws {
        try visit(union)
        try visitPost(union)
    }
    public mutating func walk(_ function: FunctionSyntax) throws {
        try visit(function)
        try visitPost(function)
    }
    public mutating func walk(_ use: SyntaxNode<UseSyntax>) throws {
        try visit(use)
        try visitPost(use)
    }
    public mutating func walk(_ include: IncludeSyntax) throws {
        try visit(include)
        try visitPost(include)
    }
}
