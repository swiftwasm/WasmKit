// Generates valid modules whose control flow crosses every place a resumable call can suspend:
// function entries, loop headers, `if` arms, bulk operations, calls, tail calls, exceptions, and
// host functions that tick the epoch or call back into the guest.

/// Draws decisions from fuzzer input. Once the input runs out it answers zero, which every
/// choice below treats as its simplest option, so generation always terminates.
public struct ByteRng {
    let bytes: [UInt8]
    var index = 0

    public init(_ bytes: [UInt8]) { self.bytes = bytes }

    public mutating func byte() -> UInt8 {
        guard index < bytes.count else { return 0 }
        defer { index += 1 }
        return bytes[index]
    }

    /// A value in `0..<n`.
    public mutating func below(_ n: Int) -> Int {
        guard n > 1 else { return 0 }
        if n <= 256 { return Int(byte()) % n }
        return (Int(byte()) << 8 | Int(byte())) % n
    }

    /// True with probability about `percent`%.
    public mutating func chance(_ percent: Int) -> Bool {
        below(100) >= 100 - percent
    }

    public var isExhausted: Bool { index >= bytes.count }
}

/// Every function has this type, so that any of them can be called directly, indirectly or from
/// a host function. The parameter is a depth budget: each call passes one less, and a function
/// returns early once it is not positive, so recursion is bounded.
let functionType = "(param i32) (result i32)"

public struct ProgramGenerator {
    var rng: ByteRng
    let functionCount: Int
    var labelCounter = 0
    /// Bounds the size of a function body.
    var nodeBudget = 0

    static let loopLocals = 5

    public init(rng: ByteRng) {
        self.rng = rng
        self.functionCount = 1 + self.rng.below(5)
    }

    public var remainingRng: ByteRng { rng }

    public var exportedFunctions: [String] { (0..<functionCount).map { "f\($0)" } }

    mutating func freshLabel() -> String {
        labelCounter += 1
        return "$L\(labelCounter)"
    }

    public mutating func generate() -> String {
        var out = """
            (module
              (type $t (func \(functionType)))
              (type $u (func (result i32)))
              (import "env" "tick" (func $tick))
              (import "env" "reenter" (func $reenter (param i32) (result i32)))
              (import "env" "nested" (func $nested (param i32) (result i32)))
              (import "env" "fail" (func $fail (param i32)))
              (memory (export "mem") 1 4)
              (table $tab (export "tab") 8 funcref)
              (global $g (export "g") (mut i32) (i32.const 0))
              (global $h (export "h") (mut i64) (i64.const 0))
              (tag $e (param i32))
              (data (i32.const 16) "WasmKit resumable call fuzzing")

            """
        var elems: [String] = []
        for _ in 0..<(1 + rng.below(8)) {
            elems.append("$f\(rng.below(functionCount))")
        }
        out += "  (elem (table $tab) (i32.const \(rng.below(2))) func \(elems.joined(separator: " ")))\n"
        out += "  (elem declare func \((0..<functionCount).map { "$f\($0)" }.joined(separator: " ")))\n"
        for index in 0..<functionCount {
            out += function(index)
        }
        out += ")\n"
        return out
    }

    mutating func function(_ index: Int) -> String {
        nodeBudget = 40 + rng.below(120)
        let loopLocals = (0..<Self.loopLocals).map { "(local $l\($0) i32)" }.joined(separator: " ")
        var body = "    (if (i32.le_s (local.get 0) (i32.const 0)) (then (return (i32.const \(index * 7 + 1)))))\n"
        body += statements(depth: 0, loopDepth: 0, indent: "    ")
        body += "    \(expr(depth: 0, loopDepth: 0))\n"
        return """
              (func $f\(index) (export "f\(index)") (type $t) (local $a i32) (local $b i32) (local $c i64) \(loopLocals)
            \(body)  )

            """
    }

    // MARK: Expressions (i32)

    mutating func constant() -> String {
        switch rng.below(8) {
        case 0: return "(i32.const 0)"
        case 1: return "(i32.const 1)"
        case 2: return "(i32.const -1)"
        case 3: return "(i32.const 0x7fffffff)"
        case 4: return "(i32.const 0x80000000)"
        case 5: return "(i32.const 65532)"
        default: return "(i32.const \(rng.below(1 << 16)))"
        }
    }

    mutating func leaf() -> String {
        switch rng.below(6) {
        case 0: return constant()
        case 1: return "(local.get 0)"
        case 2: return "(local.get $a)"
        case 3: return "(local.get $b)"
        case 4: return "(global.get $g)"
        default: return "(i32.wrap_i64 (local.get $c))"
        }
    }

    /// An address that is usually in bounds of the one-page memory.
    mutating func address(depth: Int, loopDepth: Int) -> String {
        let e = expr(depth: depth + 1, loopDepth: loopDepth)
        return rng.chance(90) ? "(i32.and \(e) (i32.const 0xfff8))" : e
    }

    var decremented: String { "(i32.sub (local.get 0) (i32.const 1))" }

    mutating func expr(depth: Int, loopDepth: Int) -> String {
        nodeBudget -= 1
        if depth > 4 || nodeBudget <= 0 { return leaf() }
        let d = depth + 1
        switch rng.below(24) {
        case 0, 1, 2: return leaf()
        case 3, 4:
            let ops = [
                "add", "sub", "mul", "and", "or", "xor", "shl", "shr_u", "shr_s", "rotl",
                "div_s", "div_u", "rem_s", "rem_u", "lt_s", "eq",
            ]
            let op = ops[rng.below(ops.count)]
            return "(i32.\(op) \(expr(depth: d, loopDepth: loopDepth)) \(expr(depth: d, loopDepth: loopDepth)))"
        case 5: return "(i32.eqz \(expr(depth: d, loopDepth: loopDepth)))"
        case 6: return "(i32.load \(address(depth: d, loopDepth: loopDepth)))"
        case 7: return "(i32.load8_u offset=3 \(address(depth: d, loopDepth: loopDepth)))"
        case 8, 9: return "(call $f\(rng.below(functionCount)) \(decremented))"
        case 10:
            // Masked with 15, not 7, so that it sometimes runs off the end of the table.
            let mask = rng.chance(85) ? 7 : 15
            if rng.chance(10) {
                return "(call_indirect $tab (type $u) (i32.and \(expr(depth: d, loopDepth: loopDepth)) (i32.const \(mask))))"
            }
            return
                "(call_indirect $tab (type $t) \(decremented) (i32.and \(expr(depth: d, loopDepth: loopDepth)) (i32.const \(mask))))"
        case 11: return "(call $reenter (local.get 0))"
        case 12: return "(call $nested (local.get 0))"
        case 13:
            return
                "(select \(expr(depth: d, loopDepth: loopDepth)) \(expr(depth: d, loopDepth: loopDepth)) \(expr(depth: d, loopDepth: loopDepth)))"
        case 14: return "(memory.size)"
        case 15: return "(memory.grow (i32.and \(expr(depth: d, loopDepth: loopDepth)) (i32.const 1)))"
        case 16:
            let l = freshLabel()
            return "(block \(l) (result i32) \(inlineStatements(depth: d, loopDepth: loopDepth, label: l)) \(expr(depth: d, loopDepth: loopDepth)))"
        case 17:
            return
                "(if (result i32) \(expr(depth: d, loopDepth: loopDepth)) (then \(inlineStatements(depth: d, loopDepth: loopDepth, label: nil)) \(expr(depth: d, loopDepth: loopDepth))) (else \(inlineStatements(depth: d, loopDepth: loopDepth, label: nil)) \(expr(depth: d, loopDepth: loopDepth))))"
        case 18, 19:
            let h = freshLabel()
            return
                "(block \(h) (result i32) (try_table (result i32) (catch $e \(h)) \(inlineStatements(depth: d, loopDepth: loopDepth, label: nil)) \(expr(depth: d, loopDepth: loopDepth))))"
        case 20: return "(local.tee $a \(expr(depth: d, loopDepth: loopDepth)))"
        case 21:
            // A loop in expression position, so that a suspension lands with values on the
            // operand stack below the loop.
            guard loopDepth < Self.loopLocals else { return leaf() }
            let l = freshLabel()
            let counter = "$l\(loopDepth)"
            return
                "(i32.add \(expr(depth: d, loopDepth: loopDepth)) (block (result i32) (local.set \(counter) (i32.const 0)) (loop \(l) \(inlineStatements(depth: d, loopDepth: loopDepth + 1, label: nil)) (local.set \(counter) (i32.add (local.get \(counter)) (i32.const 1))) (br_if \(l) (i32.lt_u (local.get \(counter)) (i32.const \(1 + rng.below(20)))))) (local.get \(counter))))"
        default:
            return "(i32.add \(expr(depth: d, loopDepth: loopDepth)) \(expr(depth: d, loopDepth: loopDepth)))"
        }
    }

    // MARK: Statements

    mutating func inlineStatements(depth: Int, loopDepth: Int, label: String?) -> String {
        var parts: [String] = []
        for _ in 0..<rng.below(3) {
            parts.append(statement(depth: depth, loopDepth: loopDepth, label: label))
        }
        return parts.joined(separator: " ")
    }

    mutating func statements(depth: Int, loopDepth: Int, indent: String) -> String {
        var out = ""
        for _ in 0..<rng.below(depth == 0 ? 8 : 4) {
            out += indent + statement(depth: depth, loopDepth: loopDepth, label: nil) + "\n"
        }
        return out
    }

    /// One statement. `label`, when given, names an enclosing `block (result i32)` that a
    /// statement may branch to with a value.
    mutating func statement(depth: Int, loopDepth: Int, label: String?) -> String {
        nodeBudget -= 1
        let d = depth + 1
        if depth > 4 || nodeBudget <= 0 {
            return "(local.set $b \(leaf()))"
        }
        switch rng.below(26) {
        case 0, 1: return "(local.set $a \(expr(depth: d, loopDepth: loopDepth)))"
        case 2: return "(local.set $b \(expr(depth: d, loopDepth: loopDepth)))"
        case 3: return "(local.set $c (i64.add (i64.mul (local.get $c) (i64.const 31)) (i64.extend_i32_u \(expr(depth: d, loopDepth: loopDepth)))))"
        case 4: return "(global.set $g \(expr(depth: d, loopDepth: loopDepth)))"
        case 5: return "(global.set $h (i64.xor (global.get $h) (local.get $c)))"
        case 6, 7:
            return "(i32.store \(address(depth: d, loopDepth: loopDepth)) \(expr(depth: d, loopDepth: loopDepth)))"
        case 8:
            return "(i64.store offset=4 \(address(depth: d, loopDepth: loopDepth)) (local.get $c))"
        case 9, 10:
            return
                "(if \(expr(depth: d, loopDepth: loopDepth)) (then \(inlineStatements(depth: d, loopDepth: loopDepth, label: label))) (else \(inlineStatements(depth: d, loopDepth: loopDepth, label: label))))"
        case 11, 12, 13:
            guard loopDepth < Self.loopLocals else { return "(call $tick)" }
            let l = freshLabel()
            let counter = "$l\(loopDepth)"
            let bound = rng.chance(10) ? 300 + rng.below(700) : 1 + rng.below(30)
            return
                "(local.set \(counter) (i32.const 0)) (loop \(l) \(inlineStatements(depth: d, loopDepth: loopDepth + 1, label: label)) (local.set \(counter) (i32.add (local.get \(counter)) (i32.const 1))) (br_if \(l) (i32.lt_u (local.get \(counter)) (i32.const \(bound)))))"
        case 14:
            let b = self.freshLabel()
            return
                "(block \(b) \(inlineStatements(depth: d, loopDepth: loopDepth, label: label)) (br_if \(b) \(expr(depth: d, loopDepth: loopDepth))) \(inlineStatements(depth: d, loopDepth: loopDepth, label: label)))"
        case 15:
            let (b0, b1, b2) = (self.freshLabel(), self.freshLabel(), self.freshLabel())
            return
                "(block \(b0) (block \(b1) (block \(b2) (br_table \(b0) \(b1) \(b2) (i32.and \(expr(depth: d, loopDepth: loopDepth)) (i32.const 3)))) \(inlineStatements(depth: d, loopDepth: loopDepth, label: label))) \(inlineStatements(depth: d, loopDepth: loopDepth, label: label)))"
        case 16, 17: return "(call $tick)"
        case 18:
            let length = rng.chance(20) ? "(i32.and \(expr(depth: d, loopDepth: loopDepth)) (i32.const 0x1ffff))" : "(i32.const \(rng.below(4096)))"
            return "(memory.fill \(address(depth: d, loopDepth: loopDepth)) \(expr(depth: d, loopDepth: loopDepth)) \(length))"
        case 19:
            let length = rng.chance(20) ? "(i32.and \(expr(depth: d, loopDepth: loopDepth)) (i32.const 0x1ffff))" : "(i32.const \(rng.below(8192)))"
            return "(memory.copy \(address(depth: d, loopDepth: loopDepth)) \(address(depth: d, loopDepth: loopDepth)) \(length))"
        case 20:
            if rng.chance(50) {
                return "(table.copy $tab $tab (i32.const \(rng.below(9))) (i32.const \(rng.below(9))) (i32.const \(rng.below(9))))"
            }
            return "(table.fill $tab (i32.const \(rng.below(9))) (ref.func $f\(rng.below(functionCount))) (i32.const \(rng.below(9))))"
        case 21: return "(call $fail \(expr(depth: d, loopDepth: loopDepth)))"
        case 22:
            if rng.chance(30) { return "(throw $e \(expr(depth: d, loopDepth: loopDepth)))" }
            if let label, rng.chance(50) { return "(br \(label) \(expr(depth: d, loopDepth: loopDepth)))" }
            return "(drop \(expr(depth: d, loopDepth: loopDepth)))"
        case 23:
            if rng.chance(25) { return "(return \(expr(depth: d, loopDepth: loopDepth)))" }
            if rng.chance(50) { return "(return_call $f\(rng.below(functionCount)) \(decremented))" }
            return "(return_call_indirect $tab (type $t) \(decremented) (i32.and \(expr(depth: d, loopDepth: loopDepth)) (i32.const 7)))"
        case 24:
            return rng.chance(15) ? "(if (i32.eqz \(expr(depth: d, loopDepth: loopDepth))) (then unreachable))" : "(drop \(expr(depth: d, loopDepth: loopDepth)))"
        default:
            return "(drop \(expr(depth: d, loopDepth: loopDepth)))"
        }
    }
}
