extension VMGen {

    static let CodeSlotSize: Int = 8

    /// A primitive type less than or equal to 64 bits.
    struct PrimitiveType {
        var name: String
        var size: Int
        var alignment: Int { size }
        var bitWidth: Int { size * 8 }
    }

    /// A field in an immediate type.
    struct ImmediateField {
        var name: String
        var type: PrimitiveType
    }

    /// A layout for an immediate type of VM instructions.
    struct ImmediateLayout {
        var name: String
        var fields: [ImmediateField] = []

        init(name: String) {
            self.name = name
        }

        init(name: String, _ build: (inout Self) -> Void) {
            self.name = name
            build(&self)
        }

        mutating func field(name: String, type: PrimitiveType) {
            fields.append(ImmediateField(name: name, type: type))
        }

        typealias SlotLayout = [ImmediateField]

        /// Splits the fields into CodeSlot sized slots.
        func slots() -> [SlotLayout] {
            let slotSize = VMGen.CodeSlotSize
            var slots: [SlotLayout] = []
            var currentSlot: SlotLayout = []
            var currentSize = 0

            for field in fields {
                currentSize = VMGen.alignUp(currentSize, to: field.type.alignment)
                if currentSize + field.type.size > slotSize {
                    slots.append(currentSlot)
                    currentSlot = []
                    currentSize = 0
                }
                currentSlot.append(field)
                currentSize += field.type.size
            }
            if !currentSlot.isEmpty {
                slots.append(currentSlot)
            }

            return slots
        }

        /// The expression that extracts `field`, placed `byteOffset` bytes into its
        /// code slot, out of the slot read as the 64-bit word `word` on a
        /// little-endian host.
        private static func wordExtraction(of field: ImmediateField, at byteOffset: Int, from word: String) -> String {
            let shifted = byteOffset == 0 ? word : "\(word) >> \(byteOffset * 8)"
            switch field.type.name {
            case "VReg": return "VReg(byteOffset: Int16(truncatingIfNeeded: \(shifted)))"
            case "LVReg": return "LVReg(storage: Int32(truncatingIfNeeded: \(shifted)))"
            case "LLVReg": return "LLVReg(storage: Int64(truncatingIfNeeded: \(shifted)))"
            case "UntypedValue": return "UntypedValue(storage: \(shifted))"
            default: return "\(field.type.name)(truncatingIfNeeded: \(shifted))"
            }
        }

        /// Builds the type declaration derived from the layout.
        ///
        /// With `decodesAsWords`, `load(from:)` reads each code slot as one 64-bit
        /// word and extracts the fields with shifts instead of reading every field
        /// separately. A handler that reads the next handler pointer right after its
        /// immediate can then have both loads combined into one.
        func buildDeclaration(decodesAsWords: Bool) -> String {
            let fieldDeclarations = fields.map { field in
                "    var \(field.name): \(field.type.name)"
            }.joined(separator: "\n")
            var output = """
            struct \(name): Equatable, InstructionImmediate {
            \(fieldDeclarations)

            """

            let slots = self.slots()

            func makeSlotTupleType(slot: SlotLayout) -> (tupleName: String, elements: [(type: String, name: String?)]) {
                var elemenets: [(type: String, String?)] = slot.map { ($0.type.name, $0.name) }
                var elementsSize = slot.reduce(0) {
                    VMGen.alignUp($0, to: $1.type.alignment) + $1.type.size
                }
                // Padding to make the tuple size CodeSlotSize
                while elementsSize < VMGen.CodeSlotSize {
                    elemenets.append(("UInt8", nil))
                    elementsSize += 1
                }
                return ("(" + elemenets.map { $0.type }.joined(separator: ", ") + ")", elemenets)
            }

            func typedReads(indent: String) -> String {
                slots.map { slot in
                    let (tupleTy, elements) = makeSlotTupleType(slot: slot)
                    return "\(indent)let (\(elements.map { $0.name ?? "_" }.joined(separator: ", "))) = pc.read(\(tupleTy).self)\n"
                }.joined()
            }

            func wordReads(indent: String) -> String {
                slots.enumerated().map { index, slot in
                    if slot.count == 1, slot[0].type.size == VMGen.CodeSlotSize {
                        return "\(indent)let \(slot[0].name) = pc.read(\(slot[0].type.name).self)\n"
                    }
                    let word = "word\(index)"
                    var output = "\(indent)let \(word) = pc.read(UInt64.self)\n"
                    var byteOffset = 0
                    for field in slot {
                        byteOffset = VMGen.alignUp(byteOffset, to: field.type.alignment)
                        output += "\(indent)let \(field.name) = \(Self.wordExtraction(of: field, at: byteOffset, from: word))\n"
                        byteOffset += field.type.size
                    }
                    return output
                }.joined()
            }

            // Emit `load` method

            let construct = "return Self(\(fields.map { "\($0.name): \($0.name)" }.joined(separator: ", ")))"
            if decodesAsWords {
                output += """

                    @inline(__always) static func load(from pc: inout Pc) -> Self {
                        #if _endian(little)
                \(wordReads(indent: "            "))            \(construct)
                        #else
                \(typedReads(indent: "            "))            \(construct)
                        #endif
                    }
                """
            } else {
                output += """

                    @inline(__always) static func load(from pc: inout Pc) -> Self {
                \(typedReads(indent: "        "))        \(construct)
                    }
                """
            }

            // Emit `emit` method

            output += """

                @inline(__always) static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {

            """

            for slot in slots {
                let (tupleTy, elements) = makeSlotTupleType(slot: slot)
                if slot.count == 1, slot[0].type.size == VMGen.CodeSlotSize {
                    // Special case for a single field that is the size of a CodeSlot
                    // to avoid suspicious warning diagnostic from the compiler.
                    switch slot[0].type.name {
                    case "UInt64":
                        output += """
                                emitSlot { $0.\(slot[0].name) }

                        """
                        continue
                    default: break
                    }
                }

                output += """
                        emitSlot { unsafeBitCast((\(elements.map { $0.name.flatMap { "$0.\($0)" } ?? "0" }.joined(separator: ", "))) as \(tupleTy), to: CodeSlot.self) }

                """
            }

            output += """

                }
            """


            output += """

            }

            """
            return output
        }
    }
}

extension VMGen.ImmediateLayout {
    static let binary = Self(name: "BinaryOperand") {
        // `result` is kept away from byte 0: decoded from there, its sign extension
        // folds into the store address, which slows down serial float chains.
        $0.field(name: "lhs", type: .VReg)
        $0.field(name: "rhs", type: .VReg)
        $0.field(name: "result", type: .LVReg)
    }

    static let unary = Self(name: "UnaryOperand") {
        $0.field(name: "result", type: .LVReg)
        $0.field(name: "input", type: .LVReg)
    }

    static let load = Self(name: "LoadOperand") {
        $0.field(name: "offset", type: .UInt64)
        $0.field(name: "pointer", type: .VReg)
        $0.field(name: "result", type: .VReg)
    }

    static let store = Self(name: "StoreOperand") {
        $0.field(name: "offset", type: .UInt64)
        $0.field(name: "pointer", type: .VReg)
        $0.field(name: "value", type: .VReg)
    }

    static let globalAndVRegOperand = Self(name: "GlobalAndVRegOperand") {
        $0.field(name: "reg", type: .LLVReg)
        $0.field(name: "rawGlobal", type: .UInt64)
    }

    static let brIfOperand = Self(name: "BrIfOperand") {
        $0.field(name: "condition", type: .LVReg)
        $0.field(name: "offset", type: .Int32)
    }

    /// Immediate layout of the fused integer compare + branch instructions
    /// (`brIf{I32,I64}{Eq,Ne,...}`). Fits in a single 8-byte code slot.
    static let brIfCmpOperand = Self(name: "BrIfCmpOperand") {
        $0.field(name: "lhs", type: .VReg)
        $0.field(name: "rhs", type: .VReg)
        $0.field(name: "offset", type: .Int32)
    }

    /// Immediate layout of the two-operation superinstructions (`f64MulAdd`,
    /// `i32ShlAdd` and friends): `result = (x <op1> y) <op2> z`, or
    /// `result = z <op2> (x <op1> y)` for the reversed forms.
    ///
    /// Four registers at two bytes each fill one 8-byte code slot exactly, so
    /// the superinstruction is two code slots where the two instructions it
    /// replaces are four. `result` is a plain pre-shifted ``VReg`` rather than
    /// an ``LVReg``; nothing is lost, since a store into a 64-bit slot folds
    /// the scale into its addressing mode either way.
    static let binBin = Self(name: "BinBinOperand") {
        $0.field(name: "result", type: .VReg)
        $0.field(name: "x", type: .VReg)
        $0.field(name: "y", type: .VReg)
        $0.field(name: "z", type: .VReg)
    }

    static let call = Self(name: "CallOperand") {
        $0.field(name: "rawCallee", type: .UInt64)
        $0.field(name: "spAddend", type: .VReg)
    }

    static let v128Const = Self(name: "V128ConstOperand") {
        $0.field(name: "lo", type: .UInt64)
        $0.field(name: "hi", type: .UInt64)
        $0.field(name: "result", type: .VReg)
    }

    static let i8x16Shuffle = Self(name: "I8x16ShuffleOperand") {
        for i in 0..<16 {
            $0.field(name: "lane\(i)", type: .UInt8)
        }
        $0.field(name: "lhs", type: .VReg)
        $0.field(name: "rhs", type: .VReg)
        $0.field(name: "result", type: .VReg)
    }

    static let simd = Self(name: "SimdOperand") {
        $0.field(name: "opcode", type: .UInt16)
        $0.field(name: "lane", type: .UInt8)
        $0.field(name: "reserved", type: .UInt8)
        $0.field(name: "offset", type: .UInt64)
        $0.field(name: "input0", type: .VReg)
        $0.field(name: "input1", type: .VReg)
        $0.field(name: "input2", type: .VReg)
        $0.field(name: "result", type: .VReg)
    }

    static let rmw = Self(name: "RmwOperand") {
        $0.field(name: "offset", type: .UInt64)
        $0.field(name: "pointer", type: .VReg)
        $0.field(name: "value", type: .VReg)
        $0.field(name: "result", type: .VReg)
    }

    static let cmpxchg = Self(name: "CmpxchgOperand") {
        $0.field(name: "offset", type: .UInt64)
        $0.field(name: "pointer", type: .VReg)
        $0.field(name: "expected", type: .VReg)
        $0.field(name: "replacement", type: .VReg)
        $0.field(name: "result", type: .VReg)
    }

    static let atomicWait = Self(name: "AtomicWaitOperand") {
        $0.field(name: "offset", type: .UInt64)
        $0.field(name: "pointer", type: .VReg)
        $0.field(name: "expected", type: .VReg)
        $0.field(name: "timeout", type: .VReg)
        $0.field(name: "result", type: .VReg)
    }

    static let atomicNotify = Self(name: "AtomicNotifyOperand") {
        $0.field(name: "offset", type: .UInt64)
        $0.field(name: "pointer", type: .VReg)
        $0.field(name: "count", type: .VReg)
        $0.field(name: "result", type: .VReg)
    }
}

extension VMGen.PrimitiveType {
    /// An expression that produces the zero value of this type, used for the
    /// dummy instruction values the generator builds.
    var zeroLiteral: String {
        switch name {
        // Register types are wrappers around a pre-shifted byte offset and take
        // no integer literal.
        case "VReg", "LVReg", "LLVReg": return "\(name).zero"
        default: return "\(name)(0)"
        }
    }

    static let VReg = Self(name: "VReg", size: 2)
    static let LVReg = Self(name: "LVReg", size: 4)
    static let LLVReg = Self(name: "LLVReg", size: 8)
    static let Int32 = Self(name: "Int32", size: 4)
    static let UInt8 = Self(name: "UInt8", size: 1)
    static let UInt16 = Self(name: "UInt16", size: 2)
    static let UInt32 = Self(name: "UInt32", size: 4)
    static let UInt64 = Self(name: "UInt64", size: 8)
    static let UntypedValue = Self(name: "UntypedValue", size: 8)
    static let MemoryIndex = Self.UInt32
    static let FunctionIndex = Self.UInt32
    static let ElementIndex = Self.UInt32
}
