import WasmParser
import WasmTypes

/// Writes a `ModuleInfo` to `output` as WAT text, one module field at a time.
/// A function body is buffered and written whole.
struct WatPrinter<Output: TextOutputStream> {
    private let info: ModuleInfo
    private let names: ModuleNames
    private let importCounts: ModuleInfo.ImportCounts
    private(set) var output: Output

    init(info: ModuleInfo, output: Output) {
        self.info = info
        self.names = ModuleNames(info: info)
        self.importCounts = info.importCounts
        self.output = output
    }

    mutating func print() throws(WasmParserError) {
        writeLine("(module\(moduleNameText())")
        printTypes()
        printImports()
        try printFunctions()
        try printTables()
        printMemories()
        try printGlobals()
        printTags()
        printExports()
        printStart()
        try printElements()
        try printData()
        writeLine(")")
    }

    // MARK: - Section printers

    private func moduleNameText() -> String {
        guard let name = info.moduleName else { return "" }
        return IdentifierTable.id(for: name).map { " " + $0 } ?? #" (@name "")"#
    }

    private mutating func printTypes() {
        for (i, type) in info.types.enumerated() {
            let name = names.types.definition(UInt32(i))
            writeLine("  (type\(name) (;\(i);) (func\(signatureText(type, parameterIds: nil))))")
        }
    }

    private mutating func printImports() {
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
            writeLine("  (import \(nameLiteral(entry.module)) \(nameLiteral(entry.name)) \(descriptor))")
        }
    }

    private mutating func printFunctions() throws(WasmParserError) {
        guard let section = info.codeSection else {
            try checkCodeEntryCount(0)
            return
        }
        try section.parse(features: info.features) { parser throws(WasmParserError) in
            let codeCount: UInt32 = try parser.parseUnsigned()
            try checkCodeEntryCount(codeCount)
            for (definitionIndex, typeIndex) in info.functionTypeIndices.enumerated() {
                let index = UInt32(importCounts.functions + definitionIndex)
                let code = try parser.parseCodeEntry()
                try printFunction(index: index, typeIndex: typeIndex, code: code)
            }
        }
    }

    private func checkCodeEntryCount(_ count: UInt32) throws(WasmParserError) {
        guard Int(count) == info.functionTypeIndices.count else {
            throw WasmParserError(
                "function/code section length mismatch (function: \(info.functionTypeIndices.count), code: \(count))"
            )
        }
    }

    private mutating func printFunction(index: UInt32, typeIndex: TypeIndex, code: Code) throws(WasmParserError) {
        let type =
            Int(typeIndex) < info.types.count ? info.types[Int(typeIndex)] : FunctionType(parameters: [], results: [])
        let locals = IdentifierTable(names: info.localNames[index] ?? [:])
        let name = names.functions.definition(index) + names.functions.nameAnnotation(index)
        let typeUse = "(type \(names.types.reference(typeIndex)))"
        writeLine("  (func\(name) (;\(index);) \(typeUse)\(signatureText(type, parameterIds: locals))")
        for (offset, localType) in code.locals.enumerated() {
            let localIndex = UInt32(type.parameters.count + offset)
            writeLine("    (local\(locals.definition(localIndex)) \(names.valueType(localType)))")
        }

        var body = ""
        var visitor = TextInstructionVisitor(
            names: names,
            locals: locals,
            labelIds: (info.labelNames[index] ?? [:]).compactMapValues(IdentifierTable.id(for:)),
            indentLevel: 2,
            append: { body += $0 }
        )
        var expressionParser = WasmParser.ExpressionParser(code: code)
        while let visit = try nextInstruction(&expressionParser, of: code) {
            try visit(visitor: &visitor)
        }
        output.write(body)
        writeLine("  )")
    }

    /// Moves `ExpressionParser`'s decoding errors from expression offsets to code
    /// section offsets, which its instruction offsets already use.
    private func nextInstruction(
        _ parser: inout WasmParser.ExpressionParser, of code: Code
    ) throws(WasmParserError) -> WasmParser.ExpressionParser.Visit? {
        do throws(WasmParserError) {
            return try parser.parse()
        } catch {
            var error = error
            error.location = error.location.map { $0 + code.offset }
            throw error
        }
    }

    private mutating func printTables() throws(WasmParserError) {
        for (offset, table) in info.tables.enumerated() {
            let index = UInt32(importCounts.tables + offset)
            var initializer = ""
            if let expression = table.initializer {
                initializer = try " " + foldedConstExpression(expression)
            }
            let type = "\(limitsText(table.type.limits)) \(names.refType(table.type.elementType))"
            writeLine("  (table\(names.tables.definition(index)) (;\(index);) \(type)\(initializer))")
        }
    }

    private mutating func printMemories() {
        for (offset, memory) in info.memories.enumerated() {
            let index = UInt32(importCounts.memories + offset)
            writeLine("  (memory\(names.memories.definition(index)) (;\(index);) \(limitsText(memory.type)))")
        }
    }

    private mutating func printGlobals() throws(WasmParserError) {
        for (offset, global) in info.globals.enumerated() {
            let index = UInt32(importCounts.globals + offset)
            let initializer = try foldedConstExpression(global.initializer)
            writeLine(
                "  (global\(names.globals.definition(index)) (;\(index);) \(globalTypeText(global.type)) \(initializer))"
            )
        }
    }

    private mutating func printTags() {
        for (offset, tag) in info.tags.enumerated() {
            let index = UInt32(importCounts.tags + offset)
            let name = names.tags.definition(index) + names.tags.nameAnnotation(index)
            writeLine("  (tag\(name) (;\(index);) (type \(names.types.reference(tag.type))))")
        }
    }

    private mutating func printExports() {
        for entry in info.exports {
            let descriptor: String
            switch entry.descriptor {
            case .function(let i): descriptor = "(func \(names.functions.reference(i)))"
            case .table(let i): descriptor = "(table \(names.tables.reference(i)))"
            case .memory(let i): descriptor = "(memory \(names.memories.reference(i)))"
            case .global(let i): descriptor = "(global \(names.globals.reference(i)))"
            case .tag(let i): descriptor = "(tag \(names.tags.reference(i)))"
            }
            writeLine("  (export \(nameLiteral(entry.name)) \(descriptor))")
        }
    }

    private mutating func printStart() {
        if let start = info.start {
            writeLine("  (start \(names.functions.reference(start)))")
        }
    }

    private mutating func printElements() throws(WasmParserError) {
        guard let section = info.elementSection else { return }
        try section.parse(features: info.features) { parser throws(WasmParserError) in
            let count: UInt32 = try parser.parseUnsigned()
            for index in 0..<count {
                let element = try parser.parseElementEntry()
                try printElement(element, index: index)
            }
        }
    }

    private mutating func printElement(_ element: ElementSegment, index: UInt32) throws(WasmParserError) {
        // The type a `func` index list has once assembled.
        let indexListType: ReferenceType =
            info.features.contains(.functionReferences) ? ReferenceType(isNullable: false, heapType: .funcRef) : .funcRef
        let functionIndices = element.initializer.compactMap { expression -> UInt32? in
            let instructions = constExprInstructions(expression)
            guard instructions.count == 1, case .refFunc(let functionIndex)? = instructions.first else { return nil }
            return functionIndex
        }

        let items: String
        if element.type == indexListType, functionIndices.count == element.initializer.count {
            items = (["func"] + functionIndices.map { names.functions.reference($0) }).joined(separator: " ")
        } else {
            var parts = [names.refType(element.type)]
            for expression in element.initializer {
                let item = try constExprText(expression)
                parts.append("(item \(item))")
            }
            items = parts.joined(separator: " ")
        }

        let name = names.elements.definition(index)
        switch element.mode {
        case .active(let table, let offset):
            let tableText = table == 0 ? "" : " (table \(names.tables.reference(table)))"
            let offsetText = try offsetText(offset)
            writeLine("  (elem\(name) (;\(index);)\(tableText) \(offsetText) \(items))")
        case .passive:
            writeLine("  (elem\(name) (;\(index);) \(items))")
        case .declarative:
            writeLine("  (elem\(name) (;\(index);) declare \(items))")
        }
    }

    private mutating func printData() throws(WasmParserError) {
        guard let section = info.dataSection else {
            if let dc = info.dataCount, dc != 0 {
                throw WasmParserError("DataCount declared \(dc) but no data section present")
            }
            return
        }
        try section.parse(features: info.features) { parser throws(WasmParserError) in
            let count: UInt32 = try parser.parseUnsigned()
            if let declaredCount = info.dataCount, declaredCount != count {
                throw WasmParserError(
                    "DataCount section declares \(declaredCount) data segments but data section has \(count)")
            }
            for index in 0..<count {
                let segment = try parser.parseDataSegmentEntry()
                try printDataSegment(segment, index: index)
            }
        }
    }

    private mutating func printDataSegment(_ segment: DataSegment, index: UInt32) throws(WasmParserError) {
        let name = names.data.definition(index)
        switch segment {
        case .active(let active):
            let memory = active.index == 0 ? "" : " (memory \(names.memories.reference(active.index)))"
            let offset = try offsetText(active.offset)
            let bytes = watStringLiteral(active.initializer, keepingUTF8: false)
            writeLine("  (data\(name) (;\(index);)\(memory) \(offset) \(bytes))")
        case .passive(let bytes):
            writeLine("  (data\(name) (;\(index);) \(watStringLiteral(bytes, keepingUTF8: false)))")
        }
    }

    // MARK: - Helpers

    private mutating func writeLine(_ line: String) {
        output.write(line)
        output.write("\n")
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
            for instruction in constExprInstructions(expression) {
                try visitor.visit(instruction)
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
