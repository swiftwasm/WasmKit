/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#table-instructions>
extension ExecutionState {
    mutating func tableGet(runtime: Runtime, stack: inout Stack, tableIndex: TableIndex) throws {
        let (_, table) = getTable(tableIndex, stack: &stack, store: runtime.store)

        let elementIndex = try getElementIndex(stack: &stack, table)

        guard let reference = table.elements[Int(elementIndex)] else {
            throw Trap.readingDroppedReference(index: elementIndex)
        }

        stack.push(value: .ref(reference))
    }
    mutating func tableSet(runtime: Runtime, stack: inout Stack, tableIndex: TableIndex) throws {
        let (tableAddress, table) = getTable(tableIndex, stack: &stack, store: runtime.store)

        let reference = stack.getReference()
        let elementIndex = try getElementIndex(stack: &stack, table)
        setTableElement(store: runtime.store, tableAddress: tableAddress, Int(elementIndex), reference)

    }
    mutating func tableSize(runtime: Runtime, stack: inout Stack, tableIndex: TableIndex) {
        let (_, table) = getTable(tableIndex, stack: &stack, store: runtime.store)
        let elementsCount = table.elements.count
        stack.push(value: table.limits.isMemory64 ? .i64(UInt64(elementsCount)) : .i32(UInt32(elementsCount)))
    }
    mutating func tableGrow(runtime: Runtime, stack: inout Stack, tableIndex: TableIndex) {
        let (tableAddress, table) = getTable(tableIndex, stack: &stack, store: runtime.store)

        let growthSize = stack.popValue().asAddressOffset(table.limits.isMemory64)
        let growthValue = stack.getReference()

        let oldSize = table.elements.count
        guard runtime.store.tables[tableAddress].grow(by: growthSize, value: growthValue) else {
            stack.push(value: .i32(Int32(-1).unsigned))
            return
        }

        stack.push(value: table.limits.isMemory64 ? .i64(UInt64(oldSize)) : .i32(UInt32(oldSize)))
    }
    mutating func tableFill(runtime: Runtime, stack: inout Stack, tableIndex: TableIndex) throws {
        let (tableAddress, table) = getTable(tableIndex, stack: &stack, store: runtime.store)
        let fillCounter = stack.popValue().asAddressOffset(table.limits.isMemory64)
        let fillValue = stack.getReference()
        let startIndex = stack.popValue().asAddressOffset(table.limits.isMemory64)

        guard fillCounter > 0 else {
            return
        }

        guard Int(startIndex + fillCounter) <= table.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(startIndex + fillCounter))
        }

        for i in 0..<fillCounter {
            setTableElement(store: runtime.store, tableAddress: tableAddress, Int(startIndex + i), fillValue)
        }
    }
    mutating func tableCopy(runtime: Runtime, stack: inout Stack, dest: TableIndex, src: TableIndex) throws {
        let destinationTableIndex = dest
        let sourceTableIndex = src
        let (_, sourceTable) = getTable(sourceTableIndex, stack: &stack, store: runtime.store)
        let (destinationTableAddress, destinationTable) = getTable(destinationTableIndex, stack: &stack, store: runtime.store)

        let copyCounter = stack.popValue().asAddressOffset(
            sourceTable.limits.isMemory64 || destinationTable.limits.isMemory64
        )
        let sourceIndex = stack.popValue().asAddressOffset(sourceTable.limits.isMemory64)
        let destinationIndex = stack.popValue().asAddressOffset(destinationTable.limits.isMemory64)

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

        for i in 0..<copyCounter {
            setTableElement(
                store: runtime.store,
                tableAddress: destinationTableAddress,
                Int(destinationIndex + i),
                sourceTable.elements[Int(sourceIndex + i)]
            )
        }
    }
    mutating func tableInit(runtime: Runtime, stack: inout Stack, tableIndex: TableIndex, elementIndex: ElementIndex) throws {
        let (destinationTableAddress, destinationTable) = getTable(tableIndex, stack: &stack, store: runtime.store)
        let elementAddress = currentModule(store: runtime.store, stack: &stack).elementAddresses[Int(elementIndex)]
        let sourceElement = runtime.store.elements[elementAddress]

        let copyCounter = UInt64(stack.popValue().i32)
        let sourceIndex = UInt64(stack.popValue().i32)
        let destinationIndex = stack.popValue().asAddressOffset(destinationTable.limits.isMemory64)

        guard copyCounter > 0 else {
            return
        }

        guard
            !sourceIndex.addingReportingOverflow(copyCounter).overflow && !destinationIndex.addingReportingOverflow(copyCounter).overflow
        else {
            throw Trap.tableSizeOverflow
        }

        guard sourceIndex + copyCounter <= sourceElement.references.count else {
            throw Trap.outOfBoundsTableAccess(Int(sourceIndex + copyCounter))
        }
        guard destinationIndex + copyCounter <= destinationTable.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(destinationIndex + copyCounter))
        }

        for i in 0..<copyCounter {
            let reference = sourceElement.references[Int(sourceIndex + i)]

            setTableElement(
                store: runtime.store,
                tableAddress: destinationTableAddress,
                Int(destinationIndex + i),
                reference
            )
        }
    }
    mutating func tableElementDrop(runtime: Runtime, stack: inout Stack, elementIndex: ElementIndex) {
        let elementAddress = currentModule(store: runtime.store, stack: &stack).elementAddresses[Int(elementIndex)]
        runtime.store.elements[elementAddress].drop()
    }

    fileprivate func setTableElement(
        store: Store,
        tableAddress: TableAddress,
        _ elementIndex: Int,
        _ reference: Reference?
    ) {
        store.tables[tableAddress].elements[elementIndex] = reference
    }
}

extension ExecutionState {
    fileprivate func getTable(_ tableIndex: UInt32, stack: inout Stack, store: Store) -> (TableAddress, TableInstance) {
        let address = currentModule(store: store, stack: &stack).tableAddresses[Int(tableIndex)]
        return (address, store.tables[address])
    }

    fileprivate mutating func getElementIndex(stack: inout Stack, _ table: TableInstance) throws -> ElementIndex {
        let elementIndex = stack.popValue().asAddressOffset(table.limits.isMemory64)

        guard elementIndex < table.elements.count else {
            throw Trap.outOfBoundsTableAccess(Int(elementIndex))
        }

        return ElementIndex(elementIndex)
    }
}

extension Stack {
    fileprivate mutating func getReference() -> Reference {
        let value = popValue()

        guard case let .ref(reference) = value else {
            fatalError("invalid value at the top of the stack \(value)")
        }

        return reference
    }
}
