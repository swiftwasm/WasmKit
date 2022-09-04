// Generated using Sourcery 0.16.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// MARK: - Frame AutoEquatable
extension Frame: Equatable {}
internal func == (lhs: Frame, rhs: Frame) -> Bool {
    guard lhs.arity == rhs.arity else { return false }
    guard lhs.module == rhs.module else { return false }
    guard lhs.locals == rhs.locals else { return false }
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
