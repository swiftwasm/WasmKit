/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#table-instructions>
enum TableInstruction: Equatable {
    case get(TableIndex)
    case set(TableIndex)
    case size(TableIndex)
    case grow(TableIndex)
    case fill(TableIndex)
    case copy(TableIndex, TableIndex)
    case `init`(TableIndex, ElementIndex)
    case elementDrop(ElementIndex)

    func execute(runtime: Runtime) throws {
        switch self {
        case let .get(tableIndex):
            let (_, table) = try runtime.getTable(tableIndex)

            let elementIndex = try runtime.getElementIndex(table)

            guard let reference = table.elements[Int(elementIndex)] else {
                throw Trap.readingDroppedReference(index: elementIndex)
            }

            runtime.stack.push(value: .ref(reference))

        case let .set(tableIndex):
            let (tableAddress, table) = try runtime.getTable(tableIndex)

            let reference = try runtime.stack.getReference()
            let elementIndex = try runtime.getElementIndex(table)
            runtime.setTableElement(tableAddress: tableAddress, elementIndex, reference)

        case let .size(tableIndex):
            let (_, table) = try runtime.getTable(tableIndex)

            runtime.stack.push(value: .i32(UInt32(table.elements.count)))

        case let .grow(tableIndex):
            let (tableAddress, table) = try runtime.getTable(tableIndex)

            let growthSize = try runtime.stack.popValue()

            guard case let .i32(growthSize) = growthSize else {
                fatalError("invalid value at the top of the stack \(growthSize)")
            }

            let growthValue = try runtime.stack.getReference()

            let oldSize = UInt32(table.elements.count)
            guard runtime.store.tables[tableAddress].grow(by: growthSize, value: growthValue) else {
                runtime.stack.push(value: .i32(Int32(-1).unsigned))
                break
            }

            runtime.stack.push(value: .i32(oldSize))

        case let .fill(tableIndex):
            let (tableAddress, table) = try runtime.getTable(tableIndex)
            let fillCounter = try runtime.stack.popValue().i32
            let fillValue = try runtime.stack.getReference()
            let startIndex = try runtime.stack.popValue().i32

            guard fillCounter > 0 else {
                break
            }

            guard Int(startIndex + fillCounter) <= table.elements.count else {
                throw Trap.outOfBoundsTableAccess(index: startIndex + fillCounter)
            }

            for i in 0..<fillCounter {
                runtime.setTableElement(tableAddress: tableAddress, startIndex + i, fillValue)
            }

        case let .copy(destinationTableIndex, sourceTableIndex):
            let (_, sourceTable) = try runtime.getTable(sourceTableIndex)
            let (destinationTableAddress, destinationTable) = try runtime.getTable(destinationTableIndex)

            let copyCounter = try runtime.stack.popValue().i32
            let sourceIndex = try runtime.stack.popValue().i32
            let destinationIndex = try runtime.stack.popValue().i32

            guard copyCounter > 0 else {
                break
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
                runtime.setTableElement(
                    tableAddress: destinationTableAddress,
                    destinationIndex + i,
                    sourceTable.elements[Int(sourceIndex + i)]
                )
            }

        case let .`init`(tableIndex, elementIndex):
            let (destinationTableAddress, destinationTable) = try runtime.getTable(tableIndex)
            let elementAddress = runtime.stack.currentFrame.module.elementAddresses[Int(elementIndex)]
            let sourceElement = runtime.store.elements[elementAddress]

            let copyCounter = try runtime.stack.popValue().i32
            let sourceIndex = try runtime.stack.popValue().i32
            let destinationIndex = try runtime.stack.popValue().i32

            guard copyCounter > 0 else {
                break
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

                runtime.setTableElement(tableAddress: destinationTableAddress, destinationIndex + i, reference)
            }

        case let .elementDrop(elementIndex):
            let elementAddress = runtime.stack.currentFrame.module.elementAddresses[Int(elementIndex)]
            runtime.store.elements[elementAddress].drop()
        }
    }
}

extension Runtime {
    fileprivate func getTable(_ tableIndex: UInt32) throws -> (TableAddress, TableInstance) {
        let address = stack.currentFrame.module.tableAddresses[Int(tableIndex)]
        return (address, store.tables[address])
    }

    fileprivate func getElementIndex(_ table: TableInstance) throws -> ElementIndex {
        let elementIndex = try stack.popValue().i32

        guard elementIndex < table.elements.count else {
            throw Trap.outOfBoundsTableAccess(index: elementIndex)
        }

        return elementIndex
    }

    fileprivate func setTableElement(tableAddress: TableAddress, _ elementIndex: ElementIndex, _ reference: Reference?) {
        store.tables[tableAddress].elements[Int(elementIndex)] = reference
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
