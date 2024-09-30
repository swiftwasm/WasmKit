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

            for (slotIndex, slot) in slots.enumerated() {
                let slotVar = "slot\(slotIndex)"
                output += """
                        let \(slotVar) = pc.read(CodeSlot.self)

                """

                var bitOffset = 0
                for field in slot {
                    let shiftWidth = VMGen.CodeSlotSize * 8 - bitOffset - field.type.bitWidth
                    output += """
                            let \(field.name) = \(field.type.name)(\(slotVar), shiftWidth: \(shiftWidth))

                    """

                    bitOffset += field.type.bitWidth
                }
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
                var slotFields: [String] = []
                var bitOffset = 0
                for field in slot {
                    let shiftWidth = VMGen.CodeSlotSize * 8 - bitOffset - field.type.bitWidth
                    slotFields.append("$0.\(field.name).bits(shiftWidth: \(shiftWidth))")
                    bitOffset += field.type.bitWidth
                }

                output += """
                        emitSlot { \(slotFields.joined(separator: " | ")) }

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
}

extension VMGen.PrimitiveType {
    static let VReg = Self(name: "VReg", size: 2)
    static let LVReg = Self(name: "LVReg", size: 4)
    static let LLVReg = Self(name: "LLVReg", size: 8)
    static let UInt32 = Self(name: "UInt32", size: 4)
    static let UInt64 = Self(name: "UInt64", size: 8)
    static let UntypedValue = Self(name: "UntypedValue", size: 8)
    static let MemoryIndex = Self.UInt32
}
