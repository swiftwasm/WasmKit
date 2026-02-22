import Foundation
import WasmParser
import WasmTypes

/// Converts a `ModuleInfo` (parsed from a Wasm binary) into WAT text.
struct WatPrinter {
    private let info: ModuleInfo
    private var output: String = ""

    init(info: ModuleInfo) {
        self.info = info
    }

    /// Produces the full WAT text for the module.
    mutating func print() throws -> String {
        output = ""
        writeLine("(module")
        try printTypes()
        try printImports()
        try printFunctions()
        printTables()
        printMemories()
        printGlobals()
        printExports()
        printStart()
        try printElements()
        printData()
        writeLine(")")
        return output
    }

    // MARK: - Section printers

    private mutating func printTypes() throws {
        for (i, ft) in info.types.enumerated() {
            writeLine("  (type (;\(i);) (func\(funcTypeSuffix(ft))))")
        }
    }

    private mutating func printImports() throws {
        for imp in info.imports {
            let desc: String
            switch imp.descriptor {
            case .function(let ti):
                desc = "(func (type \(ti)))"
            case .table(let tt):
                desc = "(table \(tableLimitsText(tt.limits)) \(refTypeName(tt.elementType)))"
            case .memory(let mt):
                desc = "(memory \(memoryLimitsText(mt)))"
            case .global(let gt):
                let mut =
                    gt.mutability == .variable
                    ? "(mut \(valueTypeName(gt.valueType)))"
                    : valueTypeName(gt.valueType)
                desc = "(global \(mut))"
            }
            writeLine("  (import \(quotedString(imp.module)) \(quotedString(imp.name)) \(desc))")
        }
    }

    private mutating func printFunctions() throws {
        let importedFuncCount = info.importedFunctionCount
        for (localIdx, typeIdx) in info.functionTypeIndices.enumerated() {
            let funcIdx = UInt32(importedFuncCount + localIdx)
            guard localIdx < info.codes.count else { continue }
            let code = info.codes[localIdx]
            let ft = typeIdx < info.types.count ? info.types[Int(typeIdx)] : FunctionType(parameters: [], results: [])

            let funcName = info.functionNames[funcIdx].map { " $\($0)" } ?? ""
            var header = "  (func\(funcName) (;\(funcIdx);) (type \(typeIdx))"

            let params = ft.parameters
            if !params.isEmpty {
                header += " (param"
                for vt in params { header += " \(valueTypeName(vt))" }
                header += ")"
            }
            if !ft.results.isEmpty {
                header += " (result"
                for vt in ft.results { header += " \(valueTypeName(vt))" }
                header += ")"
            }
            writeLine(header)

            let localNameMap = info.localNames[funcIdx] ?? [:]
            for (li, localType) in code.locals.enumerated() {
                let lIdx = UInt32(params.count + li)
                let localName = localNameMap[lIdx].map { " $\($0)" } ?? ""
                writeLine("    (local\(localName) \(valueTypeName(localType)))")
            }

            // Collect instruction lines
            var instrLines: [String] = []
            var visitor = TextInstructionVisitor(
                functionNames: info.functionNames,
                globalNames: [:],
                localNames: localNameMap,
                indentLevel: 2,
                append: { line in instrLines.append(line) }
            )
            try code.parseExpression(visitor: &visitor)
            for line in instrLines {
                output += line
            }

            writeLine("  )")
        }
    }

    private mutating func printTables() {
        let importedCount = info.imports.filter {
            if case .table = $0.descriptor { return true }
            return false
        }.count
        for (i, table) in info.tables.enumerated() {
            let idx = importedCount + i
            let limits = tableLimitsText(table.type.limits)
            let elemType = refTypeName(table.type.elementType)
            writeLine("  (table (;\(idx);) \(limits) \(elemType))")
        }
    }

    private mutating func printMemories() {
        let importedCount = info.imports.filter {
            if case .memory = $0.descriptor { return true }
            return false
        }.count
        for (i, mem) in info.memories.enumerated() {
            let idx = importedCount + i
            writeLine("  (memory (;\(idx);) \(memoryLimitsText(mem.type)))")
        }
    }

    private mutating func printGlobals() {
        let importedCount = info.imports.filter {
            if case .global = $0.descriptor { return true }
            return false
        }.count
        for (i, global) in info.globals.enumerated() {
            let idx = importedCount + i
            let mut = global.type.mutability == .variable
            let typeStr =
                mut
                ? "(mut \(valueTypeName(global.type.valueType)))"
                : valueTypeName(global.type.valueType)
            let initStr = constExprStr(global.initializer)
            writeLine("  (global (;\(idx);) \(typeStr) (\(initStr)))")
        }
    }

    private mutating func printExports() {
        for exp in info.exports {
            let desc: String
            switch exp.descriptor {
            case .function(let i): desc = "(func \(i))"
            case .table(let i): desc = "(table \(i))"
            case .memory(let i): desc = "(memory \(i))"
            case .global(let i): desc = "(global \(i))"
            }
            writeLine("  (export \(quotedString(exp.name)) \(desc))")
        }
    }

    private mutating func printStart() {
        if let s = info.start {
            let name = info.functionNames[s].map { "$\($0)" } ?? "\(s)"
            writeLine("  (start \(name))")
        }
    }

    private mutating func printElements() throws {
        for (i, elem) in info.elements.enumerated() {
            let useExpressions = elemUsesExpressions(elem)
            let typeStr = refTypeName(elem.type)

            let indicesPart: String
            if useExpressions {
                let exprs = elem.initializer.map { expr -> String in
                    let parts = constExprParts(expr)
                    if parts.count == 1 {
                        return "(\(singleInstrStr(parts[0])))"
                    }
                    return "(" + parts.map { singleInstrStr($0) }.joined(separator: " ") + ")"
                }
                indicesPart = "\(typeStr) \(exprs.joined(separator: " "))"
            } else {
                let indices = elem.initializer.compactMap { expr -> String? in
                    guard let first = expr.first, case .refFunc(let fi) = first else { return nil }
                    return info.functionNames[fi].map { "$\($0)" } ?? "\(fi)"
                }
                indicesPart = "func \(indices.joined(separator: " "))"
            }

            switch elem.mode {
            case .active(let table, let offset):
                let offsetStr = constExprStr(offset)
                if table == 0 {
                    writeLine("  (elem (;\(i);) (\(offsetStr)) \(indicesPart))")
                } else {
                    writeLine("  (elem (;\(i);) (table \(table)) (\(offsetStr)) \(indicesPart))")
                }
            case .passive:
                writeLine("  (elem (;\(i);) \(indicesPart))")
            case .declarative:
                writeLine("  (elem (;\(i);) declare \(indicesPart))")
            }
        }
    }

    private mutating func printData() {
        for (i, seg) in info.data.enumerated() {
            switch seg {
            case .active(let active):
                let offsetStr = constExprStr(active.offset)
                let dataStr = bytesToWatString(Array(active.initializer))
                writeLine("  (data (;\(i);) (\(offsetStr)) \"\(dataStr)\")")
            case .passive(let bytes):
                let dataStr = bytesToWatString(Array(bytes))
                writeLine("  (data (;\(i);) \"\(dataStr)\")")
            }
        }
    }

    // MARK: - Helpers

    private mutating func writeLine(_ s: String) {
        output += s + "\n"
    }

    private func funcTypeSuffix(_ ft: FunctionType) -> String {
        var s = ""
        if !ft.parameters.isEmpty {
            s += " (param"
            for vt in ft.parameters { s += " \(valueTypeName(vt))" }
            s += ")"
        }
        if !ft.results.isEmpty {
            s += " (result"
            for vt in ft.results { s += " \(valueTypeName(vt))" }
            s += ")"
        }
        return s
    }

    private func tableLimitsText(_ limits: Limits) -> String {
        if let max = limits.max {
            return "\(limits.min) \(max)"
        }
        return "\(limits.min)"
    }

    private func memoryLimitsText(_ limits: Limits) -> String {
        var s = ""
        if limits.isMemory64 { s += "i64 " }
        s += "\(limits.min)"
        if let max = limits.max { s += " \(max)" }
        if limits.shared { s += " shared" }
        return s
    }

    /// Returns whether an element segment was stored using const expressions
    /// vs bare function indices.
    private func elemUsesExpressions(_ seg: ElementSegment) -> Bool {
        guard let first = seg.initializer.first else { return false }
        return first.last == .end
    }

    /// Renders a `ConstExpression` as text, stripping the trailing `end`.
    private func constExprStr(_ expr: ConstExpression) -> String {
        let parts = constExprParts(expr)
        return parts.map { singleInstrStr($0) }.joined(separator: " ")
    }

    /// Returns the instructions of a const expression without the trailing `end`.
    private func constExprParts(_ expr: ConstExpression) -> [Instruction] {
        if let last = expr.last, last == .end {
            return Array(expr.dropLast())
        }
        return expr
    }

    /// Returns the WAT text for a single instruction (for const expressions).
    private func singleInstrStr(_ instr: Instruction) -> String {
        switch instr {
        case .i32Const(let v): return "i32.const \(v)"
        case .i64Const(let v): return "i64.const \(v)"
        case .f32Const(let v): return "f32.const \(formatF32(v))"
        case .f64Const(let v): return "f64.const \(formatF64(v))"
        case .globalGet(let i): return "global.get \(i)"
        case .refNull(let ht): return "ref.null \(heapTypeName(ht))"
        case .refFunc(let fi):
            return "ref.func \(info.functionNames[fi].map { "$\($0)" } ?? "\(fi)")"
        default:
            return "nop"
        }
    }

    /// Converts raw bytes to a WAT-safe escaped string (without surrounding quotes).
    private func bytesToWatString(_ bytes: [UInt8]) -> String {
        var s = ""
        for byte in bytes {
            switch byte {
            case 0x09: s += "\\t"
            case 0x0A: s += "\\n"
            case 0x0D: s += "\\r"
            case 0x22: s += "\\\""
            case 0x5C: s += "\\\\"
            case 0x20...0x7E: s += String(UnicodeScalar(byte))
            default: s += String(format: "\\%02x", byte)
            }
        }
        return s
    }

    /// Wraps a string in WAT-style double quotes with proper escaping.
    private func quotedString(_ s: String) -> String {
        var result = "\""
        for byte in s.utf8 {
            switch byte {
            case 0x22: result += "\\\""
            case 0x5C: result += "\\\\"
            default: result += String(UnicodeScalar(byte))
            }
        }
        result += "\""
        return result
    }
}
