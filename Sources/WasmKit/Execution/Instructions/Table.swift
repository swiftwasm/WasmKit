/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#table-instructions>

import WasmParser
extension ExecutionState {
    mutating func tableGet(sp: Sp, pc: Pc, tableGetOperand: Instruction.TableGetOperand) throws -> Pc {
        let runtime = runtime.value
        let table = getTable(tableGetOperand.tableIndex, store: runtime.store)

        let elementIndex = try getElementIndex(sp: sp, VReg(tableGetOperand.index), table)

        let reference = table.elements[Int(elementIndex)]
        sp[tableGetOperand.result] = UntypedValue(.ref(reference))
        return pc
    }
    mutating func tableSet(sp: Sp, pc: Pc, tableSetOperand: Instruction.TableSetOperand) throws -> Pc {
        let runtime = runtime.value
        let table = getTable(tableSetOperand.tableIndex, store: runtime.store)

        let reference = sp.getReference(VReg(tableSetOperand.value), type: table.tableType)
        let elementIndex = try getElementIndex(sp: sp, VReg(tableSetOperand.index), table)
        setTableElement(table: table, Int(elementIndex), reference)
        return pc
    }
    mutating func tableSize(sp: Sp, tableSizeOperand: Instruction.TableSizeOperand) {
        let runtime = runtime.value
        let table = getTable(tableSizeOperand.tableIndex, store: runtime.store)
        let elementsCount = table.elements.count
        sp[tableSizeOperand.result] = UntypedValue(table.limits.isMemory64 ? .i64(UInt64(elementsCount)) : .i32(UInt32(elementsCount)))
    }
    mutating func tableGrow(sp: Sp, pc: Pc, tableGrowOperand: Instruction.TableGrowOperand) throws -> Pc {
        let runtime = runtime.value
        let table = getTable(tableGrowOperand.tableIndex, store: runtime.store)

        let growthSize = sp[tableGrowOperand.delta].asAddressOffset(table.limits.isMemory64)
        let growthValue = sp.getReference(VReg(tableGrowOperand.value), type: table.tableType)

        let oldSize = table.elements.count
        guard try table.withValue({ try $0.grow(by: growthSize, value: growthValue, resourceLimiter: runtime.store.resourceLimiter) }) else {
            sp[tableGrowOperand.result] = UntypedValue(.i32(Int32(-1).unsigned))
            return pc
        }
        sp[tableGrowOperand.result] = UntypedValue(table.limits.isMemory64 ? .i64(UInt64(oldSize)) : .i32(UInt32(oldSize)))
        return pc
    }
    mutating func tableFill(sp: Sp, pc: Pc, tableFillOperand: Instruction.TableFillOperand) throws -> Pc {
        let runtime = runtime.value
        let table = getTable(tableFillOperand.tableIndex, store: runtime.store)
        let fillCounter = sp[tableFillOperand.size].asAddressOffset(table.limits.isMemory64)
        let fillValue = sp.getReference(tableFillOperand.value, type: table.tableType)
        let startIndex = sp[tableFillOperand.destOffset].asAddressOffset(table.limits.isMemory64)

        guard fillCounter > 0 else {
            return pc
        }

        guard Int(startIndex + fillCounter) <= table.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(startIndex + fillCounter))
        }

        for i in 0..<fillCounter {
            setTableElement(table: table, Int(startIndex + i), fillValue)
        }
        return pc
    }
    mutating func tableCopy(sp: Sp, pc: Pc, tableCopyOperand: Instruction.TableCopyOperand) throws -> Pc {
        let sourceTableIndex = tableCopyOperand.sourceIndex
        let destinationTableIndex = tableCopyOperand.destIndex
        let runtime = runtime.value
        let sourceTable = getTable(sourceTableIndex, store: runtime.store)
        let destinationTable = getTable(destinationTableIndex, store: runtime.store)

        let copyCounter = sp[tableCopyOperand.size].asAddressOffset(
            sourceTable.limits.isMemory64 || destinationTable.limits.isMemory64
        )
        let sourceIndex = sp[tableCopyOperand.sourceOffset].asAddressOffset(sourceTable.limits.isMemory64)
        let destinationIndex = sp[tableCopyOperand.destOffset].asAddressOffset(destinationTable.limits.isMemory64)

        guard copyCounter > 0 else {
            return pc
        }

        guard
            !sourceIndex.addingReportingOverflow(copyCounter).overflow && !destinationIndex.addingReportingOverflow(copyCounter).overflow
        else {
            throw Trap.tableSizeOverflow
        }
        guard destinationIndex + copyCounter <= sourceTable.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(destinationIndex + copyCounter))
        }
        guard destinationIndex + copyCounter <= sourceTable.elements.count && sourceIndex + copyCounter <= destinationTable.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(destinationIndex + copyCounter))
        }

        let valuesToCopy = Array(sourceTable.elements[Int(sourceIndex)..<Int(sourceIndex + copyCounter)])
        for (i, value) in valuesToCopy.enumerated() {
            setTableElement(
                table: destinationTable,
                Int(destinationIndex) + i,
                value
            )
        }
        return pc
    }
    mutating func tableInit(sp: Sp, pc: Pc, tableInitOperand: Instruction.TableInitOperand) throws -> Pc {
        let tableIndex = tableInitOperand.tableIndex
        let segmentIndex = tableInitOperand.segmentIndex
        let destinationTable = getTable(tableIndex, store: runtime.store)
        let sourceElement = currentInstance.elementSegments[Int(segmentIndex)]

        let copyCounter = UInt64(sp[tableInitOperand.size].i32)
        let sourceIndex = UInt64(sp[tableInitOperand.sourceOffset].i32)
        let destinationIndex = sp[tableInitOperand.destOffset].asAddressOffset(destinationTable.limits.isMemory64)

        try destinationTable.withValue {
            try $0.initialize(
                elements: sourceElement.references,
                from: Int(sourceIndex), to: Int(destinationIndex),
                count: Int(copyCounter)
            )
        }
        return pc
    }
    mutating func tableElementDrop(sp: Sp, elementIndex: ElementIndex) {
        let segment = currentInstance.elementSegments[Int(elementIndex)]
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

extension ExecutionState {
    fileprivate func getTable(_ tableIndex: UInt32, store: Store) -> InternalTable {
        return currentInstance.tables[Int(tableIndex)]
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
