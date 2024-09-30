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

        /// Builds the type declaration derived from the layout.
        func buildDeclaration() -> String {
            let fieldDeclarations = fields.map { field in
                "    var \(field.name): \(field.type.name)"
            }.joined(separator: "\n")
            var output = """
            struct \(name): Equatable, InstructionImmediate {
            \(fieldDeclarations)

            """

            // Emit `load` method

            output += """

                @inline(__always) static func load(from pc: inout Pc) -> Self {

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

            for slot in slots {
                let (tupleTy, elements) = makeSlotTupleType(slot: slot)
                output += """
                        let (\(elements.map { $0.name ?? "_" }.joined(separator: ", "))) = pc.read(\(tupleTy).self)

                """
            }

            output += """
                    return Self(\(fields.map { "\($0.name): \($0.name)" }.joined(separator: ", ")))
                }
            """

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
        $0.field(name: "result", type: .LVReg)
        $0.field(name: "lhs", type: .VReg)
        $0.field(name: "rhs", type: .VReg)
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

    static let call = Self(name: "CallOperand") {
        $0.field(name: "rawCallee", type: .UInt64)
        $0.field(name: "spAddend", type: .VReg)
    }
}

extension VMGen.PrimitiveType {
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
