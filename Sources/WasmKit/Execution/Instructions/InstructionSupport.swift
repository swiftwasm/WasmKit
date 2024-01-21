extension Instruction {
    struct Memarg: Equatable {
        let offset: UInt64
        let align: UInt32
    }

    struct BlockType: Equatable {
        let parameters: UInt16
        let results: UInt16
    }

    struct BrTable: Equatable {
        let labelIndices: UnsafeBufferPointer<LabelIndex>
        let defaultIndex: LabelIndex

        init(labelIndices: [LabelIndex], defaultIndex: LabelIndex) {
            let buffer = UnsafeMutableBufferPointer<LabelIndex>.allocate(capacity: labelIndices.count)
            for (index, labelindex) in labelIndices.enumerated() {
                buffer[index] = labelindex
            }
            self.labelIndices = UnsafeBufferPointer(buffer)
            self.defaultIndex = defaultIndex
        }
        static func == (lhs: Instruction.BrTable, rhs: Instruction.BrTable) -> Bool {
            lhs.defaultIndex == rhs.defaultIndex && lhs.labelIndices.baseAddress == rhs.labelIndices.baseAddress
        }
    }

    // Just for migration purpose
    static func control(_ x: Instruction) -> Instruction { x }
    static func numeric(_ x: Instruction) -> Instruction { x }
    static func parametric(_ x: Instruction) -> Instruction { x }
    static func variable(_ x: Instruction) -> Instruction { x }
    static func reference(_ x: Instruction) -> Instruction { x }
}
