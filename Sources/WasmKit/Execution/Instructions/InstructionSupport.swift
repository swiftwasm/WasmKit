extension Instruction {
    struct Memarg: Equatable {
        let offset: UInt64
        let align: UInt32
    }

    // Just for migration purpose
    static func control(_ x: Instruction) -> Instruction { x }
    static func numeric(_ x: Instruction) -> Instruction { x }
    static func parametric(_ x: Instruction) -> Instruction { x }
    static func variable(_ x: Instruction) -> Instruction { x }
    static func reference(_ x: Instruction) -> Instruction { x }
}
