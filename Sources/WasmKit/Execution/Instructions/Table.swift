/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#table-instructions>

import WasmParser
extension ExecutionState {
    mutating func tableGet(context: inout StackContext, sp: Sp, tableGetOperand: Instruction.TableGetOperand) throws {
        let table = getTable(tableGetOperand.tableIndex, stack: &context, store: runtime.store)

        let elementIndex = try getElementIndex(sp: sp, tableGetOperand.index, table)

        let reference = table.elements[Int(elementIndex)]
        sp[tableGetOperand.result] = UntypedValue(.ref(reference))
    }
    mutating func tableSet(context: inout StackContext, sp: Sp, tableSetOperand: Instruction.TableSetOperand) throws {
        let table = getTable(tableSetOperand.tableIndex, stack: &context, store: runtime.store)

        let reference = sp.getReference(tableSetOperand.value, type: table.tableType)
        let elementIndex = try getElementIndex(sp: sp, tableSetOperand.index, table)
        setTableElement(table: table, Int(elementIndex), reference)

    }
    mutating func tableSize(context: inout StackContext, sp: Sp, tableSizeOperand: Instruction.TableSizeOperand) {
        let table = getTable(tableSizeOperand.tableIndex, stack: &context, store: runtime.store)
        let elementsCount = table.elements.count
        sp[tableSizeOperand.result] = UntypedValue(table.limits.isMemory64 ? .i64(UInt64(elementsCount)) : .i32(UInt32(elementsCount)))
    }
    mutating func tableGrow(context: inout StackContext, sp: Sp, tableGrowOperand: Instruction.TableGrowOperand) throws {
        let table = getTable(tableGrowOperand.tableIndex, stack: &context, store: runtime.store)

        let growthSize = sp[tableGrowOperand.delta].asAddressOffset(table.limits.isMemory64)
        let growthValue = sp.getReference(tableGrowOperand.value, type: table.tableType)

        let oldSize = table.elements.count
        guard try table.withValue({ try $0.grow(by: growthSize, value: growthValue, resourceLimiter: runtime.store.resourceLimiter) }) else {
            sp[tableGrowOperand.result] = UntypedValue(.i32(Int32(-1).unsigned))
            return
        }
        sp[tableGrowOperand.result] = UntypedValue(table.limits.isMemory64 ? .i64(UInt64(oldSize)) : .i32(UInt32(oldSize)))
    }
    mutating func tableFill(context: inout StackContext, sp: Sp, tableFillOperand: Instruction.TableFillOperand) throws {
        let table = getTable(tableFillOperand.tableIndex, stack: &context, store: runtime.store)
        let fillCounter = sp[tableFillOperand.size].asAddressOffset(table.limits.isMemory64)
        let fillValue = sp.getReference(tableFillOperand.value, type: table.tableType)
        let startIndex = sp[tableFillOperand.destOffset].asAddressOffset(table.limits.isMemory64)

        guard fillCounter > 0 else {
            return
        }

        guard Int(startIndex + fillCounter) <= table.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(startIndex + fillCounter))
        }

        for i in 0..<fillCounter {
            setTableElement(table: table, Int(startIndex + i), fillValue)
        }
    }
    mutating func tableCopy(context: inout StackContext, sp: Sp, tableCopyOperand: Instruction.TableCopyOperand) throws {
        let destinationTableIndex = tableCopyOperand.destIndex
        let sourceTableIndex = tableCopyOperand.sourceIndex
        let sourceTable = getTable(sourceTableIndex, stack: &context, store: runtime.store)
        let destinationTable = getTable(destinationTableIndex, stack: &context, store: runtime.store)

        let copyCounter = sp[tableCopyOperand.size].asAddressOffset(
            sourceTable.limits.isMemory64 || destinationTable.limits.isMemory64
        )
        let sourceIndex = sp[tableCopyOperand.sourceOffset].asAddressOffset(sourceTable.limits.isMemory64)
        let destinationIndex = sp[tableCopyOperand.destOffset].asAddressOffset(destinationTable.limits.isMemory64)

        guard copyCounter > 0 else {
            return
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
    }
    mutating func tableInit(context: inout StackContext, sp: Sp, tableInitOperand: Instruction.TableInitOperand) throws {
        let destinationTable = getTable(tableInitOperand.tableIndex, stack: &context, store: runtime.store)
        let sourceElement = context.currentInstance.elementSegments[Int(tableInitOperand.segmentIndex)]

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
    }
    mutating func tableElementDrop(context: inout StackContext, sp: Sp, elementIndex: ElementIndex) {
        let segment = context.currentInstance.elementSegments[Int(elementIndex)]
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
    fileprivate func getTable(_ tableIndex: UInt32, stack: inout StackContext, store: Store) -> InternalTable {
        return stack.currentInstance.tables[Int(tableIndex)]
    }

    fileprivate mutating func getElementIndex(
        sp: Sp,
        _ register: Instruction.Register, _ table: InternalTable
    ) throws -> ElementIndex {
        let elementIndex = sp[register].asAddressOffset(table.limits.isMemory64)

        guard elementIndex < table.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(elementIndex))
        }

        return ElementIndex(elementIndex)
    }
}

extension ExecutionState.FrameBase {
    fileprivate func getReference(_ register: Instruction.Register, type: TableType) -> Reference {
        return self[register].asReference(type.elementType)
    }
}
