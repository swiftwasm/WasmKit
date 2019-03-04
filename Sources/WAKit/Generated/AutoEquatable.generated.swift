// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable file_length
private func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case let (lValue?, rValue?):
        return compare(lValue, rValue)
    case (nil, nil):
        return true
    default:
        return false
    }
}

private func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
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
    guard lhs.instrucions == rhs.instrucions else { return false }
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
    guard lhs.exports == rhs.exports else { return false }
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

// MARK: - ControlInstruction AutoEquatable

extension ControlInstruction: Equatable {}
internal func == (lhs: ControlInstruction, rhs: ControlInstruction) -> Bool {
    switch (lhs, rhs) {
    case (.unreachable, .unreachable):
        return true
    case (.nop, .nop):
        return true
    case let (.block(lhs), .block(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.loop(lhs), .loop(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.if(lhs), .if(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        if lhs.2 != rhs.2 { return false }
        return true
    case let (.br(lhs), .br(rhs)):
        return lhs == rhs
    case let (.brIf(lhs), .brIf(rhs)):
        return lhs == rhs
    case let (.brTable(lhs), .brTable(rhs)):
        return lhs == rhs
    case (.return, .return):
        return true
    case let (.call(lhs), .call(rhs)):
        return lhs == rhs
    case let (.callIndirect(lhs), .callIndirect(rhs)):
        return lhs == rhs
    default: return false
    }
}

// MARK: - ExternalType AutoEquatable

extension ExternalType: Equatable {}
public func == (lhs: ExternalType, rhs: ExternalType) -> Bool {
    switch (lhs, rhs) {
    case let (.function(lhs), .function(rhs)):
        return lhs == rhs
    case let (.table(lhs), .table(rhs)):
        return lhs == rhs
    case let (.memory(lhs), .memory(rhs)):
        return lhs == rhs
    case let (.global(lhs), .global(rhs)):
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
    case let (.some(lhs), .some(rhs)):
        if lhs.parameters != rhs.parameters { return false }
        if lhs.results != rhs.results { return false }
        return true
    default: return false
    }
}

// MARK: - MemoryInstruction AutoEquatable

extension MemoryInstruction: Equatable {}
internal func == (lhs: MemoryInstruction, rhs: MemoryInstruction) -> Bool {
    switch (lhs, rhs) {
    case (.currentMemory, .currentMemory):
        return true
    case (.growMemory, .growMemory):
        return true
    case let (.load(lhs), .load(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.load8s(lhs), .load8s(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.load8u(lhs), .load8u(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.load16s(lhs), .load16s(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.load16u(lhs), .load16u(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.load32s(lhs), .load32s(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.load32u(lhs), .load32u(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.store(lhs), .store(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.store8(lhs), .store8(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.store16(lhs), .store16(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.store32(lhs), .store32(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    default: return false
    }
}

// MARK: - NumericInstruction.Binary AutoEquatable

extension NumericInstruction.Binary: Equatable {}
internal func == (lhs: NumericInstruction.Binary, rhs: NumericInstruction.Binary) -> Bool {
    switch (lhs, rhs) {
    case let (.add(lhs), .add(rhs)):
        return lhs == rhs
    case let (.sub(lhs), .sub(rhs)):
        return lhs == rhs
    case let (.mul(lhs), .mul(rhs)):
        return lhs == rhs
    case let (.divS(lhs), .divS(rhs)):
        return lhs == rhs
    case let (.divU(lhs), .divU(rhs)):
        return lhs == rhs
    case let (.remS(lhs), .remS(rhs)):
        return lhs == rhs
    case let (.remU(lhs), .remU(rhs)):
        return lhs == rhs
    case let (.and(lhs), .and(rhs)):
        return lhs == rhs
    case let (.or(lhs), .or(rhs)):
        return lhs == rhs
    case let (.xor(lhs), .xor(rhs)):
        return lhs == rhs
    case let (.shl(lhs), .shl(rhs)):
        return lhs == rhs
    case let (.shrS(lhs), .shrS(rhs)):
        return lhs == rhs
    case let (.shrU(lhs), .shrU(rhs)):
        return lhs == rhs
    case let (.rotl(lhs), .rotl(rhs)):
        return lhs == rhs
    case let (.rotr(lhs), .rotr(rhs)):
        return lhs == rhs
    case let (.div(lhs), .div(rhs)):
        return lhs == rhs
    case let (.min(lhs), .min(rhs)):
        return lhs == rhs
    case let (.max(lhs), .max(rhs)):
        return lhs == rhs
    case let (.copysign(lhs), .copysign(rhs)):
        return lhs == rhs
    default: return false
    }
}

// MARK: - NumericInstruction.Comparison AutoEquatable

extension NumericInstruction.Comparison: Equatable {}
internal func == (lhs: NumericInstruction.Comparison, rhs: NumericInstruction.Comparison) -> Bool {
    switch (lhs, rhs) {
    case let (.eq(lhs), .eq(rhs)):
        return lhs == rhs
    case let (.ne(lhs), .ne(rhs)):
        return lhs == rhs
    case let (.ltS(lhs), .ltS(rhs)):
        return lhs == rhs
    case let (.ltU(lhs), .ltU(rhs)):
        return lhs == rhs
    case let (.gtS(lhs), .gtS(rhs)):
        return lhs == rhs
    case let (.gtU(lhs), .gtU(rhs)):
        return lhs == rhs
    case let (.leS(lhs), .leS(rhs)):
        return lhs == rhs
    case let (.leU(lhs), .leU(rhs)):
        return lhs == rhs
    case let (.geS(lhs), .geS(rhs)):
        return lhs == rhs
    case let (.geU(lhs), .geU(rhs)):
        return lhs == rhs
    case let (.lt(lhs), .lt(rhs)):
        return lhs == rhs
    case let (.gt(lhs), .gt(rhs)):
        return lhs == rhs
    case let (.le(lhs), .le(rhs)):
        return lhs == rhs
    case let (.ge(lhs), .ge(rhs)):
        return lhs == rhs
    default: return false
    }
}

// MARK: - NumericInstruction.Conversion AutoEquatable

extension NumericInstruction.Conversion: Equatable {}
internal func == (lhs: NumericInstruction.Conversion, rhs: NumericInstruction.Conversion) -> Bool {
    switch (lhs, rhs) {
    case let (.wrap(lhs), .wrap(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.extendS(lhs), .extendS(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.extendU(lhs), .extendU(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.truncS(lhs), .truncS(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.truncU(lhs), .truncU(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.convertS(lhs), .convertS(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.convertU(lhs), .convertU(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.demote(lhs), .demote(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.promote(lhs), .promote(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    case let (.reinterpret(lhs), .reinterpret(rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    default: return false
    }
}

// MARK: - NumericInstruction.Test AutoEquatable

extension NumericInstruction.Test: Equatable {}
internal func == (lhs: NumericInstruction.Test, rhs: NumericInstruction.Test) -> Bool {
    switch (lhs, rhs) {
    case let (.eqz(lhs), .eqz(rhs)):
        return lhs == rhs
    }
}

// MARK: - NumericInstruction.Unary AutoEquatable

extension NumericInstruction.Unary: Equatable {}
internal func == (lhs: NumericInstruction.Unary, rhs: NumericInstruction.Unary) -> Bool {
    switch (lhs, rhs) {
    case let (.clz(lhs), .clz(rhs)):
        return lhs == rhs
    case let (.ctz(lhs), .ctz(rhs)):
        return lhs == rhs
    case let (.popcnt(lhs), .popcnt(rhs)):
        return lhs == rhs
    case let (.abs(lhs), .abs(rhs)):
        return lhs == rhs
    case let (.neg(lhs), .neg(rhs)):
        return lhs == rhs
    case let (.ceil(lhs), .ceil(rhs)):
        return lhs == rhs
    case let (.floor(lhs), .floor(rhs)):
        return lhs == rhs
    case let (.trunc(lhs), .trunc(rhs)):
        return lhs == rhs
    case let (.nearest(lhs), .nearest(rhs)):
        return lhs == rhs
    case let (.sqrt(lhs), .sqrt(rhs)):
        return lhs == rhs
    default: return false
    }
}
