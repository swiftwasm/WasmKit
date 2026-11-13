import WasmParser
import WasmTypes

/// Writes a `ModuleInfo` as WAT text through `write`, in chunks of about 64 KiB.
///
/// Errors thrown by `write` propagate unchanged; every other error is a `WasmParserError`.
struct WatPrinter {
    private let info: ModuleInfo
    private let names: ModuleNames
    private let importCounts: ModuleInfo.ImportCounts
    private let write: (String) throws -> Void
    private var buffer = ""

    init(info: ModuleInfo, write: @escaping (String) throws -> Void) {
        self.info = info
        self.names = ModuleNames(info: info)
        self.importCounts = info.importCounts
        self.write = write
    }

    mutating func print() throws {
        try writeLine("(module\(moduleNameText())")
        try printTypes()
        try printImports()
        try printFunctions()
        try printTables()
        try printMemories()
        try printGlobals()
        try printTags()
        try printExports()
        try printStart()
        try printElements()
        try printData()
        try writeLine(")")
        try flush()
    }

    // MARK: - Section printers

    private func moduleNameText() -> String {
        guard let name = info.moduleName else { return "" }
        return IdentifierTable.id(for: name).map { " " + $0 } ?? #" (@name "")"#
    }

    private mutating func printTypes() throws {
        for (i, type) in info.types.enumerated() {
            let name = names.types.definition(UInt32(i))
            try writeLine("  (type\(name) (;\(i);) (func\(signatureText(type, parameterIds: nil))))")
        }
    }

    private mutating func printImports() throws {
        var next = ModuleInfo.ImportCounts()
        for entry in info.imports {
            let descriptor: String
            switch entry.descriptor {
            case .function(let typeIndex):
                let index = UInt32(next.functions)
                next.functions += 1
                let name = names.functions.definition(index) + names.functions.nameAnnotation(index)
                descriptor = "(func\(name) (type \(names.types.reference(typeIndex))))"
            case .table(let type):
                let index = UInt32(next.tables)
                next.tables += 1
                let name = names.tables.definition(index)
                descriptor = "(table\(name) \(limitsText(type.limits)) \(names.refType(type.elementType)))"
            case .memory(let limits):
                let index = UInt32(next.memories)
                next.memories += 1
                descriptor = "(memory\(names.memories.definition(index)) \(limitsText(limits)))"
            case .global(let type):
                let index = UInt32(next.globals)
                next.globals += 1
                descriptor = "(global\(names.globals.definition(index)) \(globalTypeText(type)))"
            case .tag(let typeIndex):
                let index = UInt32(next.tags)
                next.tags += 1
                let name = names.tags.definition(index) + names.tags.nameAnnotation(index)
                descriptor = "(tag\(name) (type \(names.types.reference(typeIndex))))"
            }
            try writeLine("  (import \(nameLiteral(entry.module)) \(nameLiteral(entry.name)) \(descriptor))")
        }
    }

    private mutating func printFunctions() throws {
        guard info.codes.count == info.functionTypeIndices.count else {
            throw WasmParserError(
                "function/code section length mismatch (function: \(info.functionTypeIndices.count), code: \(info.codes.count))"
            )
        }
        for (definitionIndex, (typeIndex, code)) in zip(info.functionTypeIndices, info.codes).enumerated() {
            let index = UInt32(importCounts.functions + definitionIndex)
            try printFunction(index: index, typeIndex: typeIndex, code: code)
        }
    }

    private mutating func printFunction(index: UInt32, typeIndex: TypeIndex, code: Code) throws {
        let type = typeIndex < info.types.count ? info.types[Int(typeIndex)] : FunctionType(parameters: [], results: [])
        let locals = IdentifierTable(names: info.localNames[index] ?? [:])
        let name = names.functions.definition(index) + names.functions.nameAnnotation(index)
        let typeUse = "(type \(names.types.reference(typeIndex)))"
        try writeLine("  (func\(name) (;\(index);) \(typeUse)\(signatureText(type, parameterIds: locals))")
        for (offset, localType) in code.locals.enumerated() {
            let localIndex = UInt32(type.parameters.count + offset)
            try writeLine("    (local\(locals.definition(localIndex)) \(names.valueType(localType)))")
        }

        var pendingText = ""
        var visitor = TextInstructionVisitor(
            names: names,
            locals: locals,
            labelIds: (info.labelNames[index] ?? [:]).compactMapValues(IdentifierTable.id(for:)),
            indentLevel: 2,
            append: { pendingText += $0 }
        )
        var expressionParser = WasmParser.ExpressionParser(code: code)
        let expressionOffset = expressionParser.offset
        while let visit = try nextInstruction(&expressionParser, expressionOffset: expressionOffset) {
            try visit(visitor: &visitor)
            try append(pendingText)
            pendingText.removeAll(keepingCapacity: true)
        }
        try visitor.finishExpression()
        try append(pendingText)
        try writeLine("  )")
    }

    /// Moves `ExpressionParser`'s decoding errors from offsets within the expression to
    /// module offsets, which its instruction offsets already use.
    private func nextInstruction(
        _ parser: inout WasmParser.ExpressionParser, expressionOffset: Int
    ) throws(WasmParserError) -> WasmParser.ExpressionParser.Visit? {
        do throws(WasmParserError) {
            return try parser.parse()
        } catch {
            var error = error
            error.location = error.location.map { $0 + expressionOffset }
            throw error
        }
    }

    private mutating func printTables() throws {
        for (offset, table) in info.tables.enumerated() {
            let index = UInt32(importCounts.tables + offset)
            var initializer = ""
            if let expression = table.initializer {
                initializer = try " " + foldedConstExpression(expression)
            }
            let type = "\(limitsText(table.type.limits)) \(names.refType(table.type.elementType))"
            try writeLine("  (table\(names.tables.definition(index)) (;\(index);) \(type)\(initializer))")
        }
    }

    private mutating func printMemories() throws {
        for (offset, memory) in info.memories.enumerated() {
            let index = UInt32(importCounts.memories + offset)
            try writeLine("  (memory\(names.memories.definition(index)) (;\(index);) \(limitsText(memory.type)))")
        }
    }

    private mutating func printGlobals() throws {
        for (offset, global) in info.globals.enumerated() {
            let index = UInt32(importCounts.globals + offset)
            let initializer = try foldedConstExpression(global.initializer)
            try writeLine(
                "  (global\(names.globals.definition(index)) (;\(index);) \(globalTypeText(global.type)) \(initializer))"
            )
        }
    }

    private mutating func printTags() throws {
        for (offset, tag) in info.tags.enumerated() {
            let index = UInt32(importCounts.tags + offset)
            let name = names.tags.definition(index) + names.tags.nameAnnotation(index)
            try writeLine("  (tag\(name) (;\(index);) (type \(names.types.reference(tag.type))))")
        }
    }

    private mutating func printExports() throws {
        for entry in info.exports {
            let descriptor: String
            switch entry.descriptor {
            case .function(let i): descriptor = "(func \(names.functions.reference(i)))"
            case .table(let i): descriptor = "(table \(names.tables.reference(i)))"
            case .memory(let i): descriptor = "(memory \(names.memories.reference(i)))"
            case .global(let i): descriptor = "(global \(names.globals.reference(i)))"
            case .tag(let i): descriptor = "(tag \(names.tags.reference(i)))"
            }
            try writeLine("  (export \(nameLiteral(entry.name)) \(descriptor))")
        }
    }

    private mutating func printStart() throws {
        if let start = info.start {
            try writeLine("  (start \(names.functions.reference(start)))")
        }
    }

    private mutating func printElements() throws {
        for (index, element) in info.elements.enumerated() {
            try printElement(element, index: UInt32(index))
        }
    }

    private mutating func printElement(_ element: ElementSegment, index: UInt32) throws {
        // The type a `func` index list has once assembled.
        let indexListType: ReferenceType =
            info.features.contains(.functionReferences) ? ReferenceType(isNullable: false, heapType: .funcRef) : .funcRef
        let functionIndices = element.initializer.compactMap { expression -> UInt32? in
            let instructions = constExprInstructions(expression)
            guard instructions.count == 1, case .refFunc(let functionIndex)? = instructions.first else { return nil }
            return functionIndex
        }

        var header = "  (elem\(names.elements.definition(index)) (;\(index);)"
        switch element.mode {
        case .active(let table, let offset):
            if table != 0 {
                header += " (table \(names.tables.reference(table)))"
            }
            header += " \(try offsetText(offset))"
        case .passive:
            break
        case .declarative:
            header += " declare"
        }
        try append(header)
        if element.type == indexListType, functionIndices.count == element.initializer.count {
            try append(" func")
            for functionIndex in functionIndices {
                try append(" \(names.functions.reference(functionIndex))")
            }
        } else {
            try append(" \(names.refType(element.type))")
            for expression in element.initializer {
                try append(" (item \(try constExprText(expression)))")
            }
        }
        try writeLine(")")
    }

    private mutating func printData() throws {
        if let declaredCount = info.dataCount, declaredCount != info.dataSegments.count {
            throw WasmParserError(
                "DataCount section declares \(declaredCount) data segments but data section has \(info.dataSegments.count)")
        }
        for (index, segment) in info.dataSegments.enumerated() {
            try printDataSegment(segment, index: UInt32(index))
        }
    }

    private mutating func printDataSegment(_ segment: DataSegment, index: UInt32) throws {
        var header = "  (data\(names.data.definition(index)) (;\(index);)"
        let bytes: ArraySlice<UInt8>
        switch segment {
        case .active(let active):
            if active.index != 0 {
                header += " (memory \(names.memories.reference(active.index)))"
            }
            header += " \(try offsetText(active.offset))"
            bytes = active.initializer
        case .passive(let passiveBytes):
            bytes = passiveBytes
        }
        try append(header)
        var start = bytes.startIndex
        repeat {
            let end = bytes.index(start, offsetBy: 1 << 14, limitedBy: bytes.endIndex) ?? bytes.endIndex
            try append(" \(watStringLiteral(bytes[start..<end], keepingUTF8: false))")
            start = end
        } while start < bytes.endIndex
        try writeLine(")")
    }

    // MARK: - Helpers

    /// Appends `text` to the output, passing the output to `write` once about 64 KiB have accumulated.
    private mutating func append(_ text: String) throws {
        buffer += text
        if buffer.utf8.count >= 1 << 16 {
            try flush()
        }
    }

    private mutating func writeLine(_ line: String) throws {
        try append(line)
        try append("\n")
    }

    private mutating func flush() throws {
        guard !buffer.isEmpty else { return }
        try write(buffer)
        buffer.removeAll(keepingCapacity: true)
    }

    private func nameLiteral(_ name: String) -> String {
        watStringLiteral(name.utf8, keepingUTF8: true)
    }

    /// A `param` that binds an id declares exactly one parameter.
    private func signatureText(_ type: FunctionType, parameterIds: IdentifierTable?) -> String {
        var text = ""
        var unnamed: [String] = []
        for (index, parameter) in type.parameters.enumerated() {
            guard let id = parameterIds?[UInt32(index)] else {
                unnamed.append(names.valueType(parameter))
                continue
            }
            if !unnamed.isEmpty {
                text += " (param \(unnamed.joined(separator: " ")))"
                unnamed = []
            }
            text += " (param \(id) \(names.valueType(parameter)))"
        }
        if !unnamed.isEmpty {
            text += " (param \(unnamed.joined(separator: " ")))"
        }
        if !type.results.isEmpty {
            text += " (result \(type.results.map { names.valueType($0) }.joined(separator: " ")))"
        }
        return text
    }

    private func limitsText(_ limits: Limits) -> String {
        var text = limits.isMemory64 ? "i64 \(limits.min)" : "\(limits.min)"
        if let max = limits.max { text += " \(max)" }
        if limits.shared { text += " shared" }
        return text
    }

    private func globalTypeText(_ type: GlobalType) -> String {
        let valueType = names.valueType(type.valueType)
        return type.mutability == .variable ? "(mut \(valueType))" : valueType
    }

    private func constExprInstructions(_ expression: ConstExpression) -> ArraySlice<Instruction> {
        expression.last == .end ? expression.dropLast() : expression[...]
    }

    private func constExprTexts(_ expression: ConstExpression) throws(WasmParserError) -> [String] {
        var text = ""
        var visitor = TextInstructionVisitor(
            names: names, locals: IdentifierTable(names: [:]), labelIds: [:], indentLevel: 0,
            append: { text += $0 }
        )
        do throws(WasmParserError) {
            for instruction in expression {
                try visitor.visit(instruction)
            }
            // An element segment that lists function indices has items with no `end`.
            if expression.last == .end {
                try visitor.finishExpression()
            }
        } catch {
            // Decoded const expressions keep no offsets.
            throw WasmParserError(kind: error.kind)
        }
        return text.split(separator: "\n").map(String.init)
    }

    private func constExprText(_ expression: ConstExpression) throws(WasmParserError) -> String {
        try constExprTexts(expression).joined(separator: " ")
    }

    /// Folds a single instruction only: a folded first instruction would take the
    /// rest as its operands.
    private func foldedConstExpression(_ expression: ConstExpression) throws(WasmParserError) -> String {
        let texts = try constExprTexts(expression)
        return texts.count == 1 ? "(\(texts[0]))" : texts.joined(separator: " ")
    }

    /// Longer offset expressions need the explicit `offset` form.
    private func offsetText(_ expression: ConstExpression) throws(WasmParserError) -> String {
        let texts = try constExprTexts(expression)
        return texts.count == 1 ? "(\(texts[0]))" : "(offset \(texts.joined(separator: " ")))"
    }
}
