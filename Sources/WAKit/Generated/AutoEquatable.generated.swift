// Generated using Sourcery 0.16.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable file_length
fileprivate func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case let (lValue?, rValue?):
        return compare(lValue, rValue)
    case (nil, nil):
        return true
    default:
        return false
    }
}

fileprivate func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (idx, lhsItem) in lhs.enumerated() {
        guard compare(lhsItem, rhs[idx]) else { return false }
    }

    return true
}


// MARK: - AutoEquatable for classes, protocols, structs
// MARK: - ExportInstance AutoEquatable
extension ExportInstance: Equatable {}
internal func == (lhs: ExportInstance, rhs: ExportInstance) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.value == rhs.value else { return false }
    return true
}
// MARK: - Frame AutoEquatable
extension Frame: Equatable {}
internal func == (lhs: Frame, rhs: Frame) -> Bool {
    guard lhs.arity == rhs.arity else { return false }
    guard lhs.module == rhs.module else { return false }
    guard lhs.locals == rhs.locals else { return false }
    return true
}
// MARK: - Function AutoEquatable
extension Function: Equatable {}
public func == (lhs: Function, rhs: Function) -> Bool {
    guard lhs.type == rhs.type else { return false }
    guard lhs.locals == rhs.locals else { return false }
    guard lhs.body == rhs.body else { return false }
    return true
}
// MARK: - GlobalType AutoEquatable
extension GlobalType: Equatable {}
public func == (lhs: GlobalType, rhs: GlobalType) -> Bool {
    guard lhs.mutability == rhs.mutability else { return false }
    guard lhs.valueType == rhs.valueType else { return false }
    return true
}
// MARK: - Label AutoEquatable
extension Label: Equatable {}
internal func == (lhs: Label, rhs: Label) -> Bool {
    guard lhs.arity == rhs.arity else { return false }
    guard lhs.continuation == rhs.continuation else { return false }
    guard lhs.range == rhs.range else { return false }
    return true
}
// MARK: - ModuleInstance AutoEquatable
extension ModuleInstance: Equatable {}
public func == (lhs: ModuleInstance, rhs: ModuleInstance) -> Bool {
    guard lhs.types == rhs.types else { return false }
    guard lhs.functionAddresses == rhs.functionAddresses else { return false }
    guard lhs.tableAddresses == rhs.tableAddresses else { return false }
    guard lhs.memoryAddresses == rhs.memoryAddresses else { return false }
    guard lhs.globalAddresses == rhs.globalAddresses else { return false }
    guard lhs.exportInstances == rhs.exportInstances else { return false }
    return true
}
// MARK: - TableType AutoEquatable
extension TableType: Equatable {}
public func == (lhs: TableType, rhs: TableType) -> Bool {
    guard lhs.elementType == rhs.elementType else { return false }
    guard lhs.limits == rhs.limits else { return false }
    return true
}

// MARK: - AutoEquatable for Enums
// MARK: - ExternalType AutoEquatable
extension ExternalType: Equatable {}
public func == (lhs: ExternalType, rhs: ExternalType) -> Bool {
    switch (lhs, rhs) {
    case (.function(let lhs), .function(let rhs)):
        return lhs == rhs
    case (.table(let lhs), .table(let rhs)):
        return lhs == rhs
    case (.memory(let lhs), .memory(let rhs)):
        return lhs == rhs
    case (.global(let lhs), .global(let rhs)):
        return lhs == rhs
    default: return false
    }
}
// MARK: - FunctionType AutoEquatable
extension FunctionType: Equatable {}
public func == (lhs: FunctionType, rhs: FunctionType) -> Bool {
    switch (lhs, rhs) {
    case (.any, .any):
        return true
    case (.some(let lhs), .some(let rhs)):
        if lhs.parameters != rhs.parameters { return false }
        if lhs.results != rhs.results { return false }
        return true
    default: return false
    }
}
