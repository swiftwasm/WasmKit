// Generated using Sourcery 0.10.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable superfluous_disable_command file_length vertical_whitespace

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

// MARK: - Data AutoEquatable

extension Data: Equatable {}
public func == (lhs: Data, rhs: Data) -> Bool {
    guard lhs.data == rhs.data else { return false }
    guard lhs.offset == rhs.offset else { return false }
    guard lhs.initializer == rhs.initializer else { return false }
    return true
}

// MARK: - Element AutoEquatable

extension Element: Equatable {}
public func == (lhs: Element, rhs: Element) -> Bool {
    guard lhs.table == rhs.table else { return false }
    guard lhs.offset == rhs.offset else { return false }
    guard lhs.initializer == rhs.initializer else { return false }
    return true
}

// MARK: - Export AutoEquatable

extension Export: Equatable {}
public func == (lhs: Export, rhs: Export) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.descriptor == rhs.descriptor else { return false }
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

// MARK: - FunctionType AutoEquatable

extension FunctionType: Equatable {}
public func == (lhs: FunctionType, rhs: FunctionType) -> Bool {
    guard compareOptionals(lhs: lhs.parameters, rhs: rhs.parameters, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.results, rhs: rhs.results, compare: ==) else { return false }
    return true
}

// MARK: - Global AutoEquatable

extension Global: Equatable {}
public func == (lhs: Global, rhs: Global) -> Bool {
    guard lhs.type == rhs.type else { return false }
    guard lhs.initializer == rhs.initializer else { return false }
    return true
}

// MARK: - GlobalType AutoEquatable

extension GlobalType: Equatable {}
public func == (lhs: GlobalType, rhs: GlobalType) -> Bool {
    guard compareOptionals(lhs: lhs.mutability, rhs: rhs.mutability, compare: ==) else { return false }
    guard lhs.valueType == rhs.valueType else { return false }
    return true
}

// MARK: - Import AutoEquatable

extension Import: Equatable {}
public func == (lhs: Import, rhs: Import) -> Bool {
    guard lhs.module == rhs.module else { return false }
    guard lhs.name == rhs.name else { return false }
    guard lhs.descripter == rhs.descripter else { return false }
    return true
}

// MARK: - Limits AutoEquatable

extension Limits: Equatable {}
public func == (lhs: Limits, rhs: Limits) -> Bool {
    guard lhs.min == rhs.min else { return false }
    guard compareOptionals(lhs: lhs.max, rhs: rhs.max, compare: ==) else { return false }
    return true
}

// MARK: - Memory AutoEquatable

extension Memory: Equatable {}
public func == (lhs: Memory, rhs: Memory) -> Bool {
    guard lhs.type == rhs.type else { return false }
    return true
}

// MARK: - Module AutoEquatable

extension Module: Equatable {}
public func == (lhs: Module, rhs: Module) -> Bool {
    guard lhs.types == rhs.types else { return false }
    guard lhs.functions == rhs.functions else { return false }
    guard lhs.tables == rhs.tables else { return false }
    guard lhs.memories == rhs.memories else { return false }
    guard lhs.globals == rhs.globals else { return false }
    guard lhs.elements == rhs.elements else { return false }
    guard lhs.data == rhs.data else { return false }
    guard compareOptionals(lhs: lhs.start, rhs: rhs.start, compare: ==) else { return false }
    guard lhs.imports == rhs.imports else { return false }
    guard lhs.exports == rhs.exports else { return false }
    return true
}

// MARK: - Table AutoEquatable

extension Table: Equatable {}
public func == (lhs: Table, rhs: Table) -> Bool {
    guard lhs.type == rhs.type else { return false }
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

// MARK: - ExportDescriptor AutoEquatable

extension ExportDescriptor: Equatable {}
public func == (lhs: ExportDescriptor, rhs: ExportDescriptor) -> Bool {
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

// MARK: - ImportDescriptor AutoEquatable

extension ImportDescriptor: Equatable {}
public func == (lhs: ImportDescriptor, rhs: ImportDescriptor) -> Bool {
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

// MARK: - NumericInstruction AutoEquatable

extension NumericInstruction: Equatable {}
internal func == (lhs: NumericInstruction, rhs: NumericInstruction) -> Bool {
    switch (lhs, rhs) {
    case let (.const(lhs), .const(rhs)):
        return lhs == rhs
    case let (.eqz(lhs), .eqz(rhs)):
        return lhs == rhs
    case let (.eq(lhs), .eq(rhs)):
        return lhs == rhs
    case let (.ne(lhs), .ne(rhs)):
        return lhs == rhs
    case let (.ltS(lhs), .ltS(rhs)):
        return lhs == rhs
    case let (.ltU(lhs), .ltU(rhs)):
        return lhs == rhs
    case let (.lt(lhs), .lt(rhs)):
        return lhs == rhs
    case let (.gtS(lhs), .gtS(rhs)):
        return lhs == rhs
    case let (.gtU(lhs), .gtU(rhs)):
        return lhs == rhs
    case let (.gt(lhs), .gt(rhs)):
        return lhs == rhs
    case let (.leS(lhs), .leS(rhs)):
        return lhs == rhs
    case let (.leU(lhs), .leU(rhs)):
        return lhs == rhs
    case let (.le(lhs), .le(rhs)):
        return lhs == rhs
    case let (.geS(lhs), .geS(rhs)):
        return lhs == rhs
    case let (.geU(lhs), .geU(rhs)):
        return lhs == rhs
    case let (.ge(lhs), .ge(rhs)):
        return lhs == rhs
    case let (.clz(lhs), .clz(rhs)):
        return lhs == rhs
    case let (.ctz(lhs), .ctz(rhs)):
        return lhs == rhs
    case let (.popcnt(lhs), .popcnt(rhs)):
        return lhs == rhs
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
    case let (.div(lhs), .div(rhs)):
        return lhs == rhs
    case let (.min(lhs), .min(rhs)):
        return lhs == rhs
    case let (.max(lhs), .max(rhs)):
        return lhs == rhs
    case let (.copysign(lhs), .copysign(rhs)):
        return lhs == rhs
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

// MARK: - ParametricInstruction AutoEquatable

extension ParametricInstruction: Equatable {}
internal func == (lhs: ParametricInstruction, rhs: ParametricInstruction) -> Bool {
    switch (lhs, rhs) {
    case (.drop, .drop):
        return true
    case (.select, .select):
        return true
    default: return false
    }
}

// MARK: - PseudoInstruction AutoEquatable

extension PseudoInstruction: Equatable {}
internal func == (lhs: PseudoInstruction, rhs: PseudoInstruction) -> Bool {
    switch (lhs, rhs) {
    case (.end, .end):
        return true
    }
}

// MARK: - Section AutoEquatable

extension Section: Equatable {}
public func == (lhs: Section, rhs: Section) -> Bool {
    switch (lhs, rhs) {
    case let (.custom(lhs), .custom(rhs)):
        if lhs.name != rhs.name { return false }
        if lhs.bytes != rhs.bytes { return false }
        return true
    case let (.type(lhs), .type(rhs)):
        return lhs == rhs
    case let (.import(lhs), .import(rhs)):
        return lhs == rhs
    case let (.function(lhs), .function(rhs)):
        return lhs == rhs
    case let (.table(lhs), .table(rhs)):
        return lhs == rhs
    case let (.memory(lhs), .memory(rhs)):
        return lhs == rhs
    case let (.global(lhs), .global(rhs)):
        return lhs == rhs
    case let (.export(lhs), .export(rhs)):
        return lhs == rhs
    case let (.start(lhs), .start(rhs)):
        return lhs == rhs
    case let (.element(lhs), .element(rhs)):
        return lhs == rhs
    case let (.code(lhs), .code(rhs)):
        return lhs == rhs
    case let (.data(lhs), .data(rhs)):
        return lhs == rhs
    default: return false
    }
}

// MARK: - Value AutoEquatable

extension Value: Equatable {}
internal func == (lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case let (.i32(lhs), .i32(rhs)):
        return lhs == rhs
    case let (.i64(lhs), .i64(rhs)):
        return lhs == rhs
    case let (.f32(lhs), .f32(rhs)):
        return lhs == rhs
    case let (.f64(lhs), .f64(rhs)):
        return lhs == rhs
    default: return false
    }
}

// MARK: - ValueType AutoEquatable

extension ValueType: Equatable {}
internal func == (lhs: ValueType, rhs: ValueType) -> Bool {
    switch (lhs, rhs) {
    case (.i32, .i32):
        return true
    case (.i64, .i64):
        return true
    case (.f32, .f32):
        return true
    case (.f64, .f64):
        return true
    default: return false
    }
}

// MARK: - VariableInstruction AutoEquatable

extension VariableInstruction: Equatable {}
internal func == (lhs: VariableInstruction, rhs: VariableInstruction) -> Bool {
    switch (lhs, rhs) {
    case let (.getLocal(lhs), .getLocal(rhs)):
        return lhs == rhs
    case let (.setLocal(lhs), .setLocal(rhs)):
        return lhs == rhs
    case let (.teeLocal(lhs), .teeLocal(rhs)):
        return lhs == rhs
    case let (.getGlobal(lhs), .getGlobal(rhs)):
        return lhs == rhs
    case let (.setGlobal(lhs), .setGlobal(rhs)):
        return lhs == rhs
    default: return false
    }
}
