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
        private let bufferBase: UnsafePointer<LabelIndex>
        private let bufferCount: UInt32
        var labelIndices: UnsafeBufferPointer<LabelIndex> {
            UnsafeBufferPointer(start: bufferBase, count: Int(bufferCount - 1))
        }
        var defaultIndex: LabelIndex {
            bufferBase[Int(bufferCount - 1)]
        }

        init(labelIndices: [LabelIndex], defaultIndex: LabelIndex) {
            let buffer = UnsafeMutableBufferPointer<LabelIndex>.allocate(capacity: labelIndices.count + 1)
            for (index, labelindex) in labelIndices.enumerated() {
                buffer[index] = labelindex
            }
            buffer[labelIndices.count] = defaultIndex
            self.bufferBase = UnsafePointer(buffer.baseAddress!)
            self.bufferCount = UInt32(buffer.count)
        }

        static func == (lhs: Instruction.BrTable, rhs: Instruction.BrTable) -> Bool {
            lhs.labelIndices.baseAddress == rhs.labelIndices.baseAddress
        }
    }

    // Just for migration purpose
    static func control(_ x: Instruction) -> Instruction { x }
    static func numeric(_ x: Instruction) -> Instruction { x }
    static func parametric(_ x: Instruction) -> Instruction { x }
    static func variable(_ x: Instruction) -> Instruction { x }
    static func reference(_ x: Instruction) -> Instruction { x }
}
