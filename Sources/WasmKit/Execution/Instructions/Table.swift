/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#table-instructions>

import WasmParser
extension Execution {
    mutating func tableGet(sp: Sp, immediate: Instruction.TableGetOperand) throws {
        let table = getTable(immediate.tableIndex, sp: sp, store: store.value)

        let elementIndex = try getElementIndex(sp: sp, VReg(immediate.index), table)

        let reference = table.elements[Int(elementIndex)]
        sp[immediate.result] = UntypedValue(.ref(reference))
    }
    mutating func tableSet(sp: Sp, immediate: Instruction.TableSetOperand) throws {
        let table = getTable(immediate.tableIndex, sp: sp, store: store.value)

        let reference = sp.getReference(VReg(immediate.value), type: table.tableType)
        let elementIndex = try getElementIndex(sp: sp, VReg(immediate.index), table)
        setTableElement(table: table, Int(elementIndex), reference)
    }
    mutating func tableSize(sp: Sp, immediate: Instruction.TableSizeOperand) {
        let table = getTable(immediate.tableIndex, sp: sp, store: store.value)
        let elementsCount = table.elements.count
        sp[immediate.result] = UntypedValue(table.limits.isMemory64 ? .i64(UInt64(elementsCount)) : .i32(UInt32(elementsCount)))
    }
    mutating func tableGrow(sp: Sp, immediate: Instruction.TableGrowOperand) throws {
        let table = getTable(immediate.tableIndex, sp: sp, store: store.value)

        let growthSize = sp[immediate.delta].asAddressOffset(table.limits.isMemory64)
        let growthValue = sp.getReference(VReg(immediate.value), type: table.tableType)

        let oldSize = table.elements.count
        guard try table.withValue({ try $0.grow(by: growthSize, value: growthValue, resourceLimiter: store.value.resourceLimiter) }) else {
            sp[immediate.result] = UntypedValue(.i32(Int32(-1).unsigned))
            return
        }
        sp[immediate.result] = UntypedValue(table.limits.isMemory64 ? .i64(UInt64(oldSize)) : .i32(UInt32(oldSize)))
    }
    mutating func tableFill(sp: Sp, immediate: Instruction.TableFillOperand) throws {
        let table = getTable(immediate.tableIndex, sp: sp, store: store.value)
        let fillCounter = sp[immediate.size].asAddressOffset(table.limits.isMemory64)
        let fillValue = sp.getReference(immediate.value, type: table.tableType)
        let startIndex = sp[immediate.destOffset].asAddressOffset(table.limits.isMemory64)

        try table.withValue { try $0.fill(repeating: fillValue, from: Int(startIndex), count: Int(fillCounter)) }
    }
    mutating func tableCopy(sp: Sp, immediate: Instruction.TableCopyOperand) throws {
        let sourceTableIndex = immediate.sourceIndex
        let destinationTableIndex = immediate.destIndex
        let store = self.store.value
        let sourceTable = getTable(sourceTableIndex, sp: sp, store: store)
        let destinationTable = getTable(destinationTableIndex, sp: sp, store: store)

        let size = sp[immediate.size].asAddressOffset(
            sourceTable.limits.isMemory64 || destinationTable.limits.isMemory64
        )
        let sourceIndex = sp[immediate.sourceOffset].asAddressOffset(sourceTable.limits.isMemory64)
        let destinationIndex = sp[immediate.destOffset].asAddressOffset(destinationTable.limits.isMemory64)

        try destinationTable.copy(sourceTable, from: Int(sourceIndex), to: Int(destinationIndex), count: Int(size))
    }
    mutating func tableInit(sp: Sp, immediate: Instruction.TableInitOperand) throws {
        let tableIndex = immediate.tableIndex
        let segmentIndex = immediate.segmentIndex
        let destinationTable = getTable(tableIndex, sp: sp, store: store.value)
        let sourceElement = currentInstance(sp: sp).elementSegments[Int(segmentIndex)]

        let copyCounter = UInt64(sp[immediate.size].i32)
        let sourceIndex = UInt64(sp[immediate.sourceOffset].i32)
        let destinationIndex = sp[immediate.destOffset].asAddressOffset(destinationTable.limits.isMemory64)

        try destinationTable.withValue {
            try $0.initialize(
                sourceElement,
                from: Int(sourceIndex), to: Int(destinationIndex),
                count: Int(copyCounter)
            )
        }
    }
    mutating func tableElementDrop(sp: Sp, immediate: Instruction.TableElementDropOperand) {
        let segment = currentInstance(sp: sp).elementSegments[Int(immediate.index)]
        segment.withValue { $0.drop() }
    }

    fileprivate func setTableElement(
        table: InternalTable,
        _ elementIndex: Int,
        _ reference: Reference
    ) {
        table.withValue {
            $0.elements[elementIndex] = reference
        }
    }
}

extension Execution {
    fileprivate func getTable(_ tableIndex: UInt32, sp: Sp, store: Store) -> InternalTable {
        return currentInstance(sp: sp).tables[Int(tableIndex)]
    }

    fileprivate mutating func getElementIndex(
        sp: Sp,
        _ register: VReg, _ table: InternalTable
    ) throws -> ElementIndex {
        let elementIndex = sp[register].asAddressOffset(table.limits.isMemory64)

        guard elementIndex < table.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(elementIndex))
        }

        return ElementIndex(elementIndex)
    }
}

extension Sp {
    fileprivate func getReference(_ register: VReg, type: TableType) -> Reference {
        return self[register].asReference(type.elementType)
    }
}
