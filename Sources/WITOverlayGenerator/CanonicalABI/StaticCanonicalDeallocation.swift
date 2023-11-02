import WIT

struct StaticCanonicalDeallocation: CanonicalDeallocation {
    typealias Operand = StaticMetaOperand
    typealias Pointer = StaticMetaPointer

    let printer: SourcePrinter
    let builder: SwiftFunctionBuilder

    func deallocateString(pointer: Operand, length: Operand) {
        printer.write(line: "Prelude.deallocateString(pointer: \(pointer), length: \(length))")
    }

    func deallocateList(
        pointer: Operand, length: Operand, element: WITType,
        deallocateElement: (Pointer) throws -> Void
    ) throws {
        let deallocElemenetVar = builder.variable("deallocElement")
        printer.write(line: "let \(deallocElemenetVar): (UnsafeMutableRawPointer) -> Void = {")
        try printer.indent {
            printer.write(line: "_ = $0")
            try deallocateElement(.init(basePointerVar: "$0", offset: 0))
        }
        printer.write(line: "}")
        printer.write(
            line: "Prelude.deallocateList(pointer: \(pointer), length: \(length), elementSize: \(CanonicalABI.size(type: element)), deallocateElement: \(deallocElemenetVar))"
        )
    }

    func deallocateVariantLike(discriminant: Operand, cases: [WITType?], deallocatePayload: (Int) throws -> Void) throws {
        printer.write(line: "switch \(discriminant) {")
        for (i, _) in cases.enumerated() {
            printer.write(line: "case \(i):")
            try printer.indent {
                try deallocatePayload(i)
                printer.write(line: "break")
            }
        }
        printer.write(line: "default: fatalError(\"invalid variant discriminant\")")
        printer.write(line: "}")
    }
}
