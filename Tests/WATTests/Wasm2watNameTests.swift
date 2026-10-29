import Testing
import WAT
import WasmParser

@Suite
struct Wasm2watNameTests {
    private static let names = EncodeOptions(nameSection: true)

    private static func printedText(of wat: String, features: WasmFeatureSet = .default) throws -> String {
        let binary = try wat2wasm(wat, features: features, options: names)
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary), features: features)
        #expect(try wat2wasm(text, features: features, options: names) == binary)
        return text
    }

    @Test func importAndExportStringsKeepTheirBytes() throws {
        let binary = try wat2wasm(#"(module (import "m\u{e9}" "a\nb" (func)) (export "\u{1}x" (func 0)))"#)
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary))
        #expect(text.contains(#"(import "mé" "a\nb" (func (type 0)))"#))
        #expect(text.contains(#"(export "\01x" (func 0))"#))
        #expect(try wat2wasm(text) == binary)
    }

    @Test func namedParametersAreDeclared() throws {
        let text = try Self.printedText(
            of: "(module (func $f (param $x i32) (param i32) (param $y i64) (result i32) local.get $x))")
        #expect(text.contains("(func $f (;0;) (type 0) (param $x i32) (param i32) (param $y i64) (result i32)"))
        #expect(text.contains("local.get $x"))
    }

    @Test func namesOutsideIdCharsAreQuoted() throws {
        let text = try Self.printedText(
            of: #"(module $"my module" (func $"foo bar(int)") (func $"λ") (global $"g\"" i32 (i32.const 0)))"#)
        #expect(text.hasPrefix(#"(module $"my module""#))
        #expect(text.contains(#"(func $"foo bar(int)" (;0;)"#))
        #expect(text.contains(#"(func $"λ" (;1;)"#))
        #expect(text.contains(#"(global $"g\"" (;0;) i32"#))
    }

    @Test func duplicateAndEmptyFunctionNamesUseAnnotations() throws {
        let text = try Self.printedText(
            of: #"(module (func $a (@name "x")) (func $b (@name "x") call $a) (func (@name "")) (func call $b))"#)
        #expect(text.contains("(func $x (;0;) (type 0)"))
        #expect(text.contains(#"(func (@name "x") (;1;) (type 0)"#))
        #expect(text.contains(#"(func (@name "") (;2;) (type 0)"#))
        #expect(text.contains("call $x"))
        #expect(text.contains("call 1"))
    }

    @Test func emptyModuleNameUsesAnAnnotation() throws {
        let text = try Self.printedText(of: #"(module (@name ""))"#)
        #expect(text.hasPrefix(#"(module (@name "")"#))
    }

    @Test func importedEntitiesKeepTheirNames() throws {
        let text = try Self.printedText(
            of: """
                (module
                  (import "m" "f" (func $f))
                  (import "m" "g" (global $g i32))
                  (import "m" "mem" (memory $mem 1))
                  (import "m" "t" (table $t 1 funcref))
                  (import "m" "e" (tag $e))
                  (func call $f))
                """)
        #expect(text.contains(#"(import "m" "f" (func $f (type 0)))"#))
        #expect(text.contains(#"(import "m" "g" (global $g i32))"#))
        #expect(text.contains(#"(import "m" "mem" (memory $mem 1))"#))
        #expect(text.contains(#"(import "m" "t" (table $t 1 funcref))"#))
        #expect(text.contains(#"(import "m" "e" (tag $e (type 0)))"#))
        #expect(text.contains("call $f"))
    }

    @Test func operandsUseNames() throws {
        let text = try Self.printedText(
            of: """
                (module
                  (type $sig (func (param i32) (result i32)))
                  (memory $m0 1)
                  (memory $m1 1)
                  (table $t0 1 funcref)
                  (table $t1 1 funcref)
                  (global $g (mut i32) (i32.const 0))
                  (tag $e)
                  (elem $seg func $id)
                  (data $bytes "x")
                  (func $id (type $sig) local.get 0)
                  (func
                    global.get $g
                    global.set $g
                    i32.const 0
                    i32.load $m1 offset=4
                    drop
                    i32.const 0
                    i32.const 0
                    i32.const 1
                    memory.init $m1 $bytes
                    data.drop $bytes
                    elem.drop $seg
                    table.size $t1
                    drop
                    i32.const 0
                    i32.const 0
                    call_indirect $t1 (type $sig)
                    drop
                    throw $e)
                  (export "id" (func $id)))
                """,
            features: .all)
        for expected in [
            "(func $id (;0;) (type $sig) (param i32) (result i32)", "global.get $g", "global.set $g",
            "i32.load $m1 offset=4", "memory.init $m1 $bytes", "data.drop $bytes", "elem.drop $seg",
            "table.size $t1", "call_indirect $t1 (type $sig)", "throw $e", #"(export "id" (func $id))"#,
            "(elem $seg (;0;) func $id)",
        ] {
            #expect(text.contains(expected), "missing \(expected)")
        }
    }

    @Test func labelNamesComeFromTheNameSection() throws {
        let text = try Self.printedText(of: "(module (func block $outer loop $inner br $outer end end))")
        #expect(text.contains("block $outer"))
        #expect(text.contains("loop $inner"))
        #expect(text.contains("br $outer"))
    }

    @Test func unnamedLabelsGetNoIds() throws {
        let text = try Self.printedText(of: "(module (func block br 0 end))")
        #expect(text.contains("    block\n"))
        #expect(text.contains("      br 0\n"))
    }

    @Test func shadowedLabelsAreReferencedByDepth() throws {
        let text = try Self.printedText(of: "(module (func block $l block $l br 1 br 0 end end))")
        #expect(text.contains("        br 1\n"))
        #expect(text.contains("        br $l\n"))
    }

    @Test func tryTableLabelsAreNumberedWithTheOthers() throws {
        let text = try Self.printedText(
            of: "(module (tag $e) (func block $o try_table $t (catch $e $o) br $t end end block $b br $b end))")
        #expect(text.contains("try_table $t (catch $e $o)"))
        #expect(text.contains("br $t"))
        #expect(text.contains("block $b"))
    }

    @Test func tagsKeepTheirNames() throws {
        let text = try Self.printedText(of: "(module (tag $e (param i32)) (func i32.const 0 throw $e))")
        #expect(text.contains("(tag $e (;0;) (type 0))"))
        #expect(text.contains("throw $e"))
    }

    @Test func richNameSectionRoundtrip() throws {
        let wat = """
            (module $myMod
              (type $T (func (param i32) (result i32)))
              (memory $mem 1)
              (table $tbl 1 funcref)
              (global $g i32 (i32.const 0))
              (func $main (type $T) (local $iter i32) local.get $iter))
            """
        let opts = EncodeOptions(nameSection: true)
        let binary = try wat2wasm(wat, options: opts)
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary))
        #expect(text.contains("$myMod"))
        #expect(text.contains("$T"))
        #expect(text.contains("$mem"))
        #expect(text.contains("$tbl"))
        #expect(text.contains("$g"))
        #expect(text.contains("$main"))
        #expect(text.contains("$iter"))
        let binary2 = try wat2wasm(text, options: opts)
        #expect(binary == binary2)
    }
}
