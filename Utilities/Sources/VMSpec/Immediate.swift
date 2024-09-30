extension VMGen {
    struct PrimitiveType {
        var name: String
        var size: Int
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
