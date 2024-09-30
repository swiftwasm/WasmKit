extension VMGen {

    static let CodeSlotSize: Int = 8

    struct PrimitiveType {
        var name: String
        var size: Int
        var alignment: Int { size }
        var bitWidth: Int { size * 8 }
    }
    struct ImmediateField {
        var name: String
        var type: PrimitiveType
    }
    struct ImmediateLayout {
        var name: String
        var fields: [ImmediateField] = []

        func field(name: String, type: PrimitiveType) -> ImmediateLayout {
            var new = self
            new.fields.append(ImmediateField(name: name, type: type))
            return new
        }

        typealias SlotLayout = [ImmediateField]

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
            }
            if !currentSlot.isEmpty {
                slots.append(currentSlot)
            }

            return slots
        }

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
    static let binary = Self(name: "BinaryOperand")
        .field(name: "result", type: .LVReg)
        .field(name: "lhs", type: .VReg)
        .field(name: "rhs", type: .VReg)

    static let unary = Self(name: "UnaryOperand")
        .field(name: "result", type: .LVReg)
        .field(name: "input", type: .LVReg)
}

extension VMGen.PrimitiveType {
    static let VReg = Self(name: "VReg", size: 2)
    static let LVReg = Self(name: "LVReg", size: 4)
}
