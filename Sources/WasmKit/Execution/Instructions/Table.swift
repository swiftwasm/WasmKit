/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#table-instructions>
extension ExecutionState {
    mutating func tableGet(runtime: Runtime, tableIndex: TableIndex) throws {
        let (_, table) = try getTable(tableIndex, store: runtime.store)

        let elementIndex = try getElementIndex(table)

        guard let reference = table.elements[Int(elementIndex)] else {
            throw Trap.readingDroppedReference(index: elementIndex)
        }

        stack.push(value: .ref(reference))
    }
    mutating func tableSet(runtime: Runtime, tableIndex: TableIndex) throws {
        let (tableAddress, table) = try getTable(tableIndex, store: runtime.store)

        let reference = try stack.getReference()
        let elementIndex = try getElementIndex(table)
        setTableElement(store: runtime.store, tableAddress: tableAddress, elementIndex, reference)

    }
    mutating func tableSize(runtime: Runtime, tableIndex: TableIndex) throws {
        let (_, table) = try getTable(tableIndex, store: runtime.store)
        stack.push(value: .i32(UInt32(table.elements.count)))
    }
    mutating func tableGrow(runtime: Runtime, tableIndex: TableIndex) throws {
        let (tableAddress, table) = try getTable(tableIndex, store: runtime.store)

        let growthSize = try stack.popValue()

        guard case let .i32(growthSize) = growthSize else {
            fatalError("invalid value at the top of the stack \(growthSize)")
        }

        let growthValue = try stack.getReference()

        let oldSize = UInt32(table.elements.count)
        guard runtime.store.tables[tableAddress].grow(by: growthSize, value: growthValue) else {
            stack.push(value: .i32(Int32(-1).unsigned))
            return
        }

        stack.push(value: .i32(oldSize))
    }
    mutating func tableFill(runtime: Runtime, tableIndex: TableIndex) throws {
        let (tableAddress, table) = try getTable(tableIndex, store: runtime.store)
        let fillCounter = try stack.popValue().i32
        let fillValue = try stack.getReference()
        let startIndex = try stack.popValue().i32

        guard fillCounter > 0 else {
            return
        }

        guard Int(startIndex + fillCounter) <= table.elements.count else {
            throw Trap.outOfBoundsTableAccess(index: startIndex + fillCounter)
        }

        for i in 0..<fillCounter {
            setTableElement(store: runtime.store, tableAddress: tableAddress, startIndex + i, fillValue)
        }
    }
    mutating func tableCopy(runtime: Runtime, dest destinationTableIndex: TableIndex, src sourceTableIndex: TableIndex) throws {
        let (_, sourceTable) = try getTable(sourceTableIndex, store: runtime.store)
        let (destinationTableAddress, destinationTable) = try getTable(destinationTableIndex, store: runtime.store)

        let copyCounter = try stack.popValue().i32
        let sourceIndex = try stack.popValue().i32
        let destinationIndex = try stack.popValue().i32

        guard copyCounter > 0 else {
            return
        }

        guard
            !sourceIndex.addingReportingOverflow(copyCounter).overflow && !destinationIndex.addingReportingOverflow(copyCounter).overflow
        else {
            throw Trap.tableSizeOverflow
        }
        guard destinationIndex + copyCounter <= sourceTable.elements.count else {
            throw Trap.outOfBoundsTableAccess(index: destinationIndex + copyCounter)
        }
        guard destinationIndex + copyCounter <= sourceTable.elements.count && sourceIndex + copyCounter <= destinationTable.elements.count else {
            throw Trap.outOfBoundsTableAccess(index: destinationIndex + copyCounter)
        }

        for i in 0..<copyCounter {
            setTableElement(
                store: runtime.store,
                tableAddress: destinationTableAddress,
                destinationIndex + i,
                sourceTable.elements[Int(sourceIndex + i)]
            )
        }
    }
    mutating func tableInit(runtime: Runtime, tableIndex: TableIndex, elementIndex: ElementIndex) throws {
        let (destinationTableAddress, destinationTable) = try getTable(tableIndex, store: runtime.store)
        let elementAddress = stack.currentFrame.module.elementAddresses[Int(elementIndex)]
        let sourceElement = runtime.store.elements[elementAddress]

        let copyCounter = try stack.popValue().i32
        let sourceIndex = try stack.popValue().i32
        let destinationIndex = try stack.popValue().i32

        guard copyCounter > 0 else {
            return
        }

        guard
            !sourceIndex.addingReportingOverflow(copyCounter).overflow && !destinationIndex.addingReportingOverflow(copyCounter).overflow
        else {
            throw Trap.tableSizeOverflow
        }

        guard sourceIndex + copyCounter <= sourceElement.references.count else {
            throw Trap.outOfBoundsTableAccess(index: sourceIndex + copyCounter)
        }
        guard destinationIndex + copyCounter <= destinationTable.elements.count else {
            throw Trap.outOfBoundsTableAccess(index: destinationIndex + copyCounter)
        }

        for i in 0..<copyCounter {
            let reference = sourceElement.references[Int(sourceIndex + i)]

            setTableElement(
                store: runtime.store,
                tableAddress: destinationTableAddress,
                destinationIndex + i,
                reference
            )
        }
    }
    mutating func tableElementDrop(runtime: Runtime, elementIndex: ElementIndex) throws {
        let elementAddress = stack.currentFrame.module.elementAddresses[Int(elementIndex)]
        runtime.store.elements[elementAddress].drop()
    }
    
    fileprivate func setTableElement(
        store: Store,
        tableAddress: TableAddress,
        _ elementIndex: ElementIndex,
        _ reference: Reference?
    ) {
        store.tables[tableAddress].elements[Int(elementIndex)] = reference
    }
}

extension ExecutionState {
    fileprivate func getTable(_ tableIndex: UInt32, store: Store) throws -> (TableAddress, TableInstance) {
        let address = stack.currentFrame.module.tableAddresses[Int(tableIndex)]
        return (address, store.tables[address])
    }

    fileprivate mutating func getElementIndex(_ table: TableInstance) throws -> ElementIndex {
        let elementIndex = try stack.popValue().i32

        guard elementIndex < table.elements.count else {
            throw Trap.outOfBoundsTableAccess(index: elementIndex)
        }

        return elementIndex
    }
}

extension Stack {
    fileprivate mutating func getReference() throws -> Reference {
        let value = try popValue()

        guard case let .ref(reference) = value else {
            fatalError("invalid value at the top of the stack \(value)")
        }

        return reference
    }
}
