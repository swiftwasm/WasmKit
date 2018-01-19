private func p2(_ n: Int) -> Int { return 1 << n }
private func p2(_ n: UInt) -> UInt { return 1 << n }

// https://webassembly.github.io/spec/binary/modules.html#binary-code
struct Code {
    let locals: [Value.Type]
    let expression: Expression
}

extension Code: Equatable {
    static func == (lhs: Code, rhs: Code) -> Bool {
        return lhs.locals == rhs.locals && lhs.expression == rhs.expression
    }
}

enum WASMParser {
    /// # Conventions
    /// - SeeAlso: https://webassembly.github.io/spec/binary/conventions.html#conventions

    /// ## Vector
    /// - SeeAlso: https://webassembly.github.io/spec/binary/conventions.html#vectors
    static func vector<S, R>(of parser: ChainableParser<S, R>) -> ChainableParser<S, [R]> where S.Element == Byte {
        return .init { stream, index in
            let (length, vectorStart) = try uint(32).parse(stream: stream, index: index)
            guard let parser = parser.repeated(count: Int(length)) else {
                throw ParserStreamError<S>.vectorInvalidLength(Int(length), location: index)
            }
            return try parser.parse(stream: stream, index: vectorStart)
        }
    }

    /// # Values
    /// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#values

    /// ## Bytes
    /// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#bytes
    static func byte<S>() -> ChainableParser<S, Byte> where S.Element == Byte {
        return .init { stream, index in
            guard let byte = stream.take(at: index) else {
                throw ParserStreamError<S>.unexpectedEnd
            }
            return (byte, stream.index(after: index))
        }
    }

    static func byte<S, C: Container>(in set: C) -> ChainableParser<S, Byte>
        where S.Element == Byte, C.Element == S.Element {
        return .init { stream, index in
            guard let byte = stream.take(at: index) else {
                throw ParserStreamError<S>.unexpectedEnd
            }
            guard set.contains(byte) else {
                throw ParserStreamError<S>.unexpected(byte, location: index)
            }
            return (byte, stream.index(after: index))
        }
    }

    static func byte<S>(_ b: UInt8) -> ChainableParser<S, Byte> where S.Element == Byte {
        return .init { stream, index in
            guard let byte = stream.take(at: index) else {
                throw ParserStreamError<S>.unexpectedEnd
            }
            guard byte == b else {
                throw ParserStreamError<S>.unexpected(byte, location: index)
            }
            return (byte, stream.index(after: index))
        }
    }

    static func bytes<S>(_ sequence: [UInt8]) -> ChainableParser<S, [Byte]>? where S.Element == Byte {
        return .concat(sequence.map { byte($0) })
    }

    static func bytes<S>(length: Int) -> ChainableParser<S, [Byte]>? where S.Element == Byte {
        return byte().repeated(count: length)
    }

    /// ## Integers
    /// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#integers
    static func uint<S>(_ bits: Int) -> ChainableParser<S, UInt> where S.Element == Byte {
        return .init { stream, index in
            let (byte, byteEnd) = try self.byte().parse(stream: stream, index: index)
            switch UInt(byte) {
            case let n where n < p2(7) && n < p2(bits):
                return (n, byteEnd)
            case let n where n >= p2(7) && bits > 7:
                let (m, mEnd) = try uint(bits - 7).parse(stream: stream, index: byteEnd)
                let result = p2(7) * m + (n - p2(7))
                return (result, mEnd)
            default:
                throw ParserStreamError<S>.unexpected(byte, location: index)
            }
        }
    }

    static func sint<S>(_ bits: Int) -> ChainableParser<S, Int> where S.Element == Byte {
        return .init { stream, index in
            let (byte, byteEnd) = try self.byte().parse(stream: stream, index: index)
            switch Int(byte) {
            case let n where n < p2(6) && n < p2(bits - 1):
                return (n, byteEnd)
            case let n where p2(6) <= n && n < p2(7) && n >= (p2(7) - p2(bits - 1)):
                return (n - p2(7), byteEnd)
            case let n where n >= p2(7) && bits > 7:
                let (m, mEnd) = try sint(bits - 7).parse(stream: stream, index: byteEnd)
                let result = m << 7 + (n - p2(7))
                return (result, mEnd)
            default:
                throw ParserStreamError<S>.unexpected(byte, location: index)
            }
        }
    }

    static func int<S>(_ bits: Int) -> ChainableParser<S, Int> where S.Element == Byte {
        return .init { stream, index in
            let (i, endIndex) = try sint(bits).parse(stream: stream, index: index)
            switch i {
            case ..<p2(bits - 1):
                return (i, endIndex)
            default:
                return (i - p2(bits), endIndex)
            }
        }
    }

    /// ## Floating-Point
    /// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#floating-point
    static func float32<S>() -> ChainableParser<S, Float> where S.Element == Byte {
        return bytes(length: 4)!.map { bytes in
            let bitPattern: UInt32 = bytes.reduce(0) { acc, byte in acc << 8 + UInt32(byte) }
            return Float(bitPattern: bitPattern)
        }
    }

    static func float64<S>() -> ChainableParser<S, Double> where S.Element == Byte {
        return bytes(length: 8)!.map { bytes in
            let bitPattern: UInt64 = bytes.reduce(0) { acc, byte in acc << 8 + UInt64(byte) }
            return Double(bitPattern: bitPattern)
        }
    }

    /// ## Names
    /// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#names
    static func name<S>() -> ChainableParser<S, Name> where S.Element == Byte {
        return .init { stream, index in
            var scalars = [UnicodeScalar]()
            let (length, vectorStart) = try uint(32).parse(stream: stream, index: index)
            var index = vectorStart

            while vectorStart.distance(to: index) < length {
                guard let b1 = stream.take(at: index) else {
                    throw ParserStreamError<S>.unexpectedEnd
                }
                index = stream.index(after: index)

                guard 0b1100_0000 <= b1 else {
                    let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1]))
                    scalars.append(scalar)
                    continue
                }

                guard let b2 = stream.take(at: index) else {
                    throw ParserStreamError<S>.unexpectedEnd
                }
                index = stream.index(after: index)

                guard 0b1110_0000 <= b1 else {
                    let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2]))
                    scalars.append(scalar)
                    continue
                }

                guard let b3 = stream.take(at: index) else {
                    throw ParserStreamError<S>.unexpectedEnd
                }
                index = stream.index(after: index)

                guard 0b1111_0000 <= b1 else {
                    let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2, b3]))
                    scalars.append(scalar)
                    continue
                }

                guard let b4 = stream.take(at: index) else {
                    throw ParserStreamError<S>.unexpectedEnd
                }
                index = stream.index(after: index)

                let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2, b3, b4]))
                scalars.append(scalar)
                continue
            }

            return (String(String.UnicodeScalarView(scalars)), index)
        }
    }

    /// # Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#types

    /// ## Value Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#value-types
    static func valueType<S>() -> ChainableParser<S, Value.Type> where S.Element == Byte {
        return .init { stream, index in
            guard let byte = stream.take(at: index) else {
                throw ParserStreamError<S>.unexpectedEnd
            }
            switch byte {
            case 0x7F: return (Int32.self, stream.index(after: index))
            case 0x7E: return (Int64.self, stream.index(after: index))
            case 0x7D: return (Float32.self, stream.index(after: index))
            case 0x7C: return (Float64.self, stream.index(after: index))
            default: throw ParserStreamError<S>.unexpected(byte, location: index)
            }
        }
    }

    /// ## Result Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#result-types
    static func resultType<S>() -> ChainableParser<S, [Value.Type]> where S.Element == Byte {
        return byte(0x40).map { _ in [] }.or(valueType().map { [$0] })
    }

    /// ## Function Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#function-types
    static func functionType<S>() -> ChainableParser<S, FunctionType> where S.Element == Byte {
        return byte(0x60)
            .followed(by: vector(of: valueType())) { _, types in types }
            .followed(by: vector(of: valueType())) { FunctionType(parameters: $0, results: $1) }
    }

    /// ## Limits Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#limits
    static func limits<S>() -> ChainableParser<S, Limits> where S.Element == Byte {
        let min: ChainableParser<S, UInt> = uint(32)
        let max: ChainableParser<S, UInt> = uint(32)
        let minOnly = byte(0x00).followed(by: min).map { _, min in Limits(min: UInt32(min), max: nil) }
        let minAndMax = byte(0x01)
            .followed(by: min) { _, min in min }
            .followed(by: max) { min, max in Limits(min: UInt32(min), max: UInt32(max)) }
        return minOnly.or(minAndMax)
    }

    /// ## Memory Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#memory-types
    static func memoryType<S>() -> ChainableParser<S, MemoryType> where S.Element == Byte {
        return limits()
    }

    /// ## Table Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#table-types
    static func tableType<S>() -> ChainableParser<S, TableType> where S.Element == Byte {
        return byte(0x70).followed(by: limits()) { TableType(limits: $1) }
    }

    /// ## Global Types
    /// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#global-types
    static func globalType<S>() -> ChainableParser<S, GlobalType> where S.Element == Byte {
        let mutabilityParser: ChainableParser<S, Mutability> = byte(0x00).map { _ in Mutability.constant }
            .or(byte(0x01).map { _ in Mutability.variable })
        return valueType().followed(by: mutabilityParser) { GlobalType(mutability: $1, valueType: $0) }
    }
}

extension WASMParser {
    /// # Instructions
    /// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#instructions

    static func instruction<S>() -> ChainableParser<S, Instruction> where S.Element == Byte {
        return .init { stream, index in
            let (byte, index) = try self.byte().parse(stream: stream, index: index)
            switch byte {
            case 0x00:
                return (ControlInstruction.unreachable, index)
            case 0x01:
                return (ControlInstruction.nop, index)
            case 0x02:
                let (type, typeIndex) = try self.resultType().parse(stream: stream, index: index)
                let (ex, exEnd) = try expression().parse(stream: stream, index: typeIndex)
                return (ControlInstruction.block(type, ex.instructions), exEnd)
            case 0x03:
                let (type, typeIndex) = try self.resultType().parse(stream: stream, index: index)
                let (ex, exEnd) = try expression().parse(stream: stream, index: typeIndex)
                return (ControlInstruction.loop(type, ex.instructions), exEnd)
            case 0x04:
                let (type, typeIndex) = try self.resultType().parse(stream: stream, index: index)
                let (ex1, ex1End) = try expression().parse(stream: stream, index: typeIndex)
                guard let (_, elseEnd) = try? self.byte(0x05).parse(stream: stream, index: ex1End) else {
                    return (ControlInstruction.if(type, ex1.instructions, []), ex1End)
                }
                let (ex2, ex2End) = try expression().parse(stream: stream, index: elseEnd)
                return (ControlInstruction.if(type, ex1.instructions, ex2.instructions), ex2End)
            case 0x0B:
                return (PseudoInstruction.end, index)
            case 0x0C:
                let (label, labelEnd) = try self.index().parse(stream: stream, index: index)
                return (ControlInstruction.br(label), labelEnd)
            case 0x0D:
                let (label, labelEnd) = try self.index().parse(stream: stream, index: index)
                return (ControlInstruction.brIf(label), labelEnd)
            case 0x0E:
                let (labels, labelsEnd) = try vector(of: self.index()).parse(stream: stream, index: index)
                return (ControlInstruction.brTable(labels), labelsEnd)
            case 0x0F:
                return (ControlInstruction.return, index)
            case 0x10:
                let (index, indexEnd) = try self.index().parse(stream: stream, index: index)
                return (ControlInstruction.call(index), indexEnd)
            case 0x11:
                let (index, indexEnd) = try self.index().parse(stream: stream, index: index)
                return (ControlInstruction.callIndirect(index), indexEnd)

            case 0x1A:
                return (ParametricInstruction.drop, index)
            case 0x1B:
                return (ParametricInstruction.select, index)

            case 0x20:
                let (index, indexEnd) = try self.index().parse(stream: stream, index: index)
                return (VariableInstruction.getLocal(index), indexEnd)
            case 0x21:
                let (index, indexEnd) = try self.index().parse(stream: stream, index: index)
                return (VariableInstruction.setLocal(index), indexEnd)
            case 0x22:
                let (index, indexEnd) = try self.index().parse(stream: stream, index: index)
                return (VariableInstruction.teeLocal(index), indexEnd)
            case 0x23:
                let (index, indexEnd) = try self.index().parse(stream: stream, index: index)
                return (VariableInstruction.getGlobal(index), indexEnd)
            case 0x24:
                let (index, indexEnd) = try self.index().parse(stream: stream, index: index)
                return (VariableInstruction.setGlobal(index), indexEnd)

            case 0x28:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i32.load((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x29:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x2A:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.f32.load((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x2B:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.f64.load((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x2C:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i32.load8s((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x2D:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load8u((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x2E:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i32.load16s((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x2F:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i32.load16u((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x30:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load8s((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x31:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load8u((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x32:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load16s((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x33:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load16u((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x34:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load32s((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x35:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.load32u((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x36:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i32.store((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x37:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.store((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x38:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.f32.store((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x39:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.f64.store((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x3A:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i32.store8((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x3B:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i32.store16((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x3C:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.store8((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x3D:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.store16((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x3E:
                let (align, alignEnd) = try self.uint(32).parse(stream: stream, index: index)
                let (offset, offsetEnd) = try self.uint(32).parse(stream: stream, index: alignEnd)
                return (MemoryInstruction.i64.store32((UInt32(align), UInt32(offset))), offsetEnd)
            case 0x3F:
                let (_, byteEnd) = try self.byte(0x00).parse(stream: stream, index: index)
                return (MemoryInstruction.currentMemory, byteEnd)
            case 0x40:
                let (_, byteEnd) = try self.byte(0x00).parse(stream: stream, index: index)
                return (MemoryInstruction.growMemory, byteEnd)

            case 0x41:
                let (n, nEnd) = try self.int(32).parse(stream: stream, index: index)
                return (NumericInstruction.i32.const(Int32(n)), nEnd)
            case 0x42:
                let (n, nEnd) = try self.int(64).parse(stream: stream, index: index)
                return (NumericInstruction.i64.const(Int64(n)), nEnd)
            case 0x43:
                let (n, nEnd) = try self.float32().parse(stream: stream, index: index)
                return (NumericInstruction.f32.const(n), nEnd)
            case 0x44:
                let (n, nEnd) = try self.float64().parse(stream: stream, index: index)
                return (NumericInstruction.f64.const(n), nEnd)

            case 0x45:
                return (NumericInstruction.i32.eqz, index)
            case 0x46:
                return (NumericInstruction.i32.eq, index)
            case 0x47:
                return (NumericInstruction.i32.ne, index)
            case 0x48:
                return (NumericInstruction.i32.ltS, index)
            case 0x49:
                return (NumericInstruction.i32.ltU, index)
            case 0x4A:
                return (NumericInstruction.i32.gtS, index)
            case 0x4B:
                return (NumericInstruction.i32.gtU, index)
            case 0x4C:
                return (NumericInstruction.i32.leS, index)
            case 0x4D:
                return (NumericInstruction.i32.leU, index)
            case 0x4E:
                return (NumericInstruction.i32.geS, index)
            case 0x4F:
                return (NumericInstruction.i32.geU, index)

            case 0x50:
                return (NumericInstruction.i64.eqz, index)
            case 0x51:
                return (NumericInstruction.i64.eq, index)
            case 0x52:
                return (NumericInstruction.i64.ne, index)
            case 0x53:
                return (NumericInstruction.i64.ltS, index)
            case 0x54:
                return (NumericInstruction.i64.ltU, index)
            case 0x55:
                return (NumericInstruction.i64.gtS, index)
            case 0x56:
                return (NumericInstruction.i64.gtU, index)
            case 0x57:
                return (NumericInstruction.i64.leS, index)
            case 0x58:
                return (NumericInstruction.i64.leU, index)
            case 0x59:
                return (NumericInstruction.i64.geS, index)
            case 0x5A:
                return (NumericInstruction.i64.geU, index)

            case 0x5B:
                return (NumericInstruction.f32.eq, index)
            case 0x5C:
                return (NumericInstruction.f32.ne, index)
            case 0x5D:
                return (NumericInstruction.f32.lt, index)
            case 0x5E:
                return (NumericInstruction.f32.gt, index)
            case 0x5F:
                return (NumericInstruction.f32.le, index)
            case 0x60:
                return (NumericInstruction.f32.ge, index)

            case 0x61:
                return (NumericInstruction.f64.eq, index)
            case 0x62:
                return (NumericInstruction.f64.ne, index)
            case 0x63:
                return (NumericInstruction.f64.lt, index)
            case 0x64:
                return (NumericInstruction.f64.gt, index)
            case 0x65:
                return (NumericInstruction.f64.le, index)
            case 0x66:
                return (NumericInstruction.f64.ge, index)

            case 0x67:
                return (NumericInstruction.i32.clz, index)
            case 0x68:
                return (NumericInstruction.i32.ctz, index)
            case 0x69:
                return (NumericInstruction.i32.popcnt, index)
            case 0x6A:
                return (NumericInstruction.i32.add, index)
            case 0x6B:
                return (NumericInstruction.i32.sub, index)
            case 0x6C:
                return (NumericInstruction.i32.mul, index)
            case 0x6D:
                return (NumericInstruction.i32.divS, index)
            case 0x6E:
                return (NumericInstruction.i32.divU, index)
            case 0x6F:
                return (NumericInstruction.i32.remS, index)
            case 0x70:
                return (NumericInstruction.i32.remU, index)
            case 0x71:
                return (NumericInstruction.i32.add, index)
            case 0x72:
                return (NumericInstruction.i32.or, index)
            case 0x73:
                return (NumericInstruction.i32.xor, index)
            case 0x74:
                return (NumericInstruction.i32.shl, index)
            case 0x75:
                return (NumericInstruction.i32.shrS, index)
            case 0x76:
                return (NumericInstruction.i32.shrU, index)
            case 0x77:
                return (NumericInstruction.i32.rotl, index)
            case 0x78:
                return (NumericInstruction.i32.rotr, index)

            case 0x79:
                return (NumericInstruction.i64.clz, index)
            case 0x7A:
                return (NumericInstruction.i64.ctz, index)
            case 0x7B:
                return (NumericInstruction.i64.popcnt, index)
            case 0x7C:
                return (NumericInstruction.i64.add, index)
            case 0x7D:
                return (NumericInstruction.i64.sub, index)
            case 0x7E:
                return (NumericInstruction.i64.mul, index)
            case 0x7F:
                return (NumericInstruction.i64.divS, index)
            case 0x80:
                return (NumericInstruction.i64.divU, index)
            case 0x81:
                return (NumericInstruction.i64.remS, index)
            case 0x82:
                return (NumericInstruction.i64.remU, index)
            case 0x83:
                return (NumericInstruction.i64.add, index)
            case 0x84:
                return (NumericInstruction.i64.or, index)
            case 0x85:
                return (NumericInstruction.i64.xor, index)
            case 0x86:
                return (NumericInstruction.i64.shl, index)
            case 0x87:
                return (NumericInstruction.i64.shrS, index)
            case 0x88:
                return (NumericInstruction.i64.shrU, index)
            case 0x89:
                return (NumericInstruction.i64.rotl, index)
            case 0x8A:
                return (NumericInstruction.i64.rotr, index)

            case 0x8B:
                return (NumericInstruction.f32.abs, index)
            case 0x8C:
                return (NumericInstruction.f32.neg, index)
            case 0x8D:
                return (NumericInstruction.f32.ceil, index)
            case 0x8E:
                return (NumericInstruction.f32.floor, index)
            case 0x8F:
                return (NumericInstruction.f32.trunc, index)
            case 0x90:
                return (NumericInstruction.f32.nearest, index)
            case 0x91:
                return (NumericInstruction.f32.sqrt, index)
            case 0x92:
                return (NumericInstruction.f32.add, index)
            case 0x93:
                return (NumericInstruction.f32.sub, index)
            case 0x94:
                return (NumericInstruction.f32.mul, index)
            case 0x95:
                return (NumericInstruction.f32.div, index)
            case 0x96:
                return (NumericInstruction.f32.min, index)
            case 0x97:
                return (NumericInstruction.f32.max, index)
            case 0x98:
                return (NumericInstruction.f32.copysign, index)

            case 0x99:
                return (NumericInstruction.f64.abs, index)
            case 0x9A:
                return (NumericInstruction.f64.neg, index)
            case 0x9B:
                return (NumericInstruction.f64.ceil, index)
            case 0x9C:
                return (NumericInstruction.f64.floor, index)
            case 0x9D:
                return (NumericInstruction.f64.trunc, index)
            case 0x9E:
                return (NumericInstruction.f64.nearest, index)
            case 0x9F:
                return (NumericInstruction.f64.sqrt, index)
            case 0xA0:
                return (NumericInstruction.f64.add, index)
            case 0xA1:
                return (NumericInstruction.f64.sub, index)
            case 0xA2:
                return (NumericInstruction.f64.mul, index)
            case 0xA3:
                return (NumericInstruction.f64.div, index)
            case 0xA4:
                return (NumericInstruction.f64.min, index)
            case 0xA5:
                return (NumericInstruction.f64.max, index)
            case 0xA6:
                return (NumericInstruction.f64.copysign, index)

            case 0xA7:
                return (NumericInstruction.i32.wrapI64, index)
            case 0xA8:
                return (NumericInstruction.i32.truncSF32, index)
            case 0xA9:
                return (NumericInstruction.i32.truncUF32, index)
            case 0xAA:
                return (NumericInstruction.i32.truncSF64, index)
            case 0xAB:
                return (NumericInstruction.i32.truncUF64, index)
            case 0xAC:
                return (NumericInstruction.i64.extendSI32, index)
            case 0xAD:
                return (NumericInstruction.i64.extendUI32, index)
            case 0xAE:
                return (NumericInstruction.i64.truncSF32, index)
            case 0xAF:
                return (NumericInstruction.i64.truncUF32, index)
            case 0xB0:
                return (NumericInstruction.i64.truncSF64, index)
            case 0xB1:
                return (NumericInstruction.i64.truncUF64, index)
            case 0xB2:
                return (NumericInstruction.f32.convertSI32, index)
            case 0xB3:
                return (NumericInstruction.f32.convertUI32, index)
            case 0xB4:
                return (NumericInstruction.f32.convertSI64, index)
            case 0xB5:
                return (NumericInstruction.f32.convertUI64, index)
            case 0xB6:
                return (NumericInstruction.f32.demoteF64, index)
            case 0xB7:
                return (NumericInstruction.f64.convertSI32, index)
            case 0xB8:
                return (NumericInstruction.f64.convertUI32, index)
            case 0xB9:
                return (NumericInstruction.f64.convertSI64, index)
            case 0xBA:
                return (NumericInstruction.f64.convertUI64, index)
            case 0xBB:
                return (NumericInstruction.f64.promoteF32, index)
            case 0xBC:
                return (NumericInstruction.i32.reinterpretF32, index)
            case 0xBD:
                return (NumericInstruction.i64.reinterpretF64, index)
            case 0xBE:
                return (NumericInstruction.f32.reinterpretI32, index)
            case 0xBF:
                return (NumericInstruction.f64.reinterpretI64, index)

            default:
                throw ParserStreamError<ByteStream>.unexpected(byte, location: index)
            }
        }
    }

    /// ## Expressions
    /// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#expressions
    static func expression<S>() -> ChainableParser<S, Expression> where S.Element == Byte {
        return ChainableParser<S, Expression> { stream, index in
            var instruction: Instruction
            var index = index
            var instructions: [Instruction] = []
            repeat {
                (instruction, index) = try self.instruction().parse(stream: stream, index: index)
                instructions.append(instruction)
            } while !instruction.isEqual(to: PseudoInstruction.end)
            return (Expression(instructions: instructions), index)
        }
    }
}

extension WASMParser {
    /// # Modules
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#modules

    /// ## Indices
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#indices
    static func index<S>() -> ChainableParser<S, UInt32> where S.Element == Byte {
        return uint(32).map { UInt32($0) }
    }

    /// ## Sections
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#sections
    static func section<S, Content>(_ n: UInt8, of contentParser: ChainableParser<S, Content>)
        -> ChainableParser<S, Content> where S.Element == Byte {
        return .init { stream, index in
            let (_, idEnd) = try byte(n).parse(stream: stream, index: index)
            let (size, sizeEnd) = try uint(32).parse(stream: stream, index: idEnd)
            let (content, contentEnd) = try contentParser.parse(stream: stream, index: sizeEnd)
            let actualSize = sizeEnd.distance(to: contentEnd)
            guard actualSize == S.Index(size) else {
                throw ParserStreamError<S>.sectionInvalidSize(actualSize, expected: Int(size), location: sizeEnd)
            }
            return (content, contentEnd)
        }
    }

    /// ## Type Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#type-section
    static func typeSection<S>() -> ChainableParser<S, [FunctionType]> where S.Element == Byte {
        return section(1, of: vector(of: functionType()))
    }

    /// ## Import Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#import-section
    static func importDescriptor<S>() -> ChainableParser<S, ImportDescriptor> where S.Element == Byte {
        return byte(0x00).followed(by: index()) { ImportDescriptor.function($1) }
            .or(byte(0x01).followed(by: tableType()) { ImportDescriptor.table($1) })
            .or(byte(0x02).followed(by: memoryType()) { ImportDescriptor.memory($1) })
            .or(byte(0x03).followed(by: globalType()) { ImportDescriptor.global($1) })
    }

    static func importSection<S>() -> ChainableParser<S, [Import]> where S.Element == Byte {
        let `import`: ChainableParser<S, Import> = name().followed(by: name())
            .followed(by: importDescriptor()) { Import(module: $0.0, name: $0.1, descripter: $1) }

        return section(2, of: vector(of: `import`))
    }

    /// ## Function Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#function-section
    static func functionSection<S>() -> ChainableParser<S, [TypeIndex]> where S.Element == Byte {
        return section(3, of: vector(of: index()))
    }

    /// ## Table Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#table-section
    static func tableSection<S>() -> ChainableParser<S, [Table]> where S.Element == Byte {
        return section(4, of: vector(of: tableType().map { Table(type: $0) }))
    }

    /// ## Memory Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#memory-section
    static func memorySection<S>() -> ChainableParser<S, [Memory]> where S.Element == Byte {
        return section(5, of: vector(of: memoryType().map { Memory(type: $0) }))
    }

    /// ## Global Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#global-section
    static func globalSection<S>() -> ChainableParser<S, [Global]> where S.Element == Byte {
        let globalParser: ChainableParser<S, Global> = globalType()
            .followed(by: expression()) { Global(type: $0, initializer: $1) }
        return section(6, of: vector(of: globalParser))
    }

    /// ## Export Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#export-section
    static func exportDescriptor<S>() -> ChainableParser<S, ExportDescriptor> where S.Element == Byte {
        return byte(0x00).followed(by: index()) { ExportDescriptor.function($1) }
            .or(byte(0x01).followed(by: index()) { ExportDescriptor.table($1) })
            .or(byte(0x02).followed(by: index()) { ExportDescriptor.memory($1) })
            .or(byte(0x03).followed(by: index()) { ExportDescriptor.global($1) })
    }

    static func exportSection<S>() -> ChainableParser<S, [Export]> where S.Element == Byte {
        let export: ChainableParser<S, Export> = name()
            .followed(by: exportDescriptor()) { Export(name: $0, descriptor: $1) }
        return section(7, of: vector(of: export))
    }

    /// ## Start Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#start-section
    static func startSection<S>() -> ChainableParser<S, FunctionIndex> where S.Element == Byte {
        return section(8, of: index())
    }

    /// ## Element Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#element-section
    static func elementSection<S>() -> ChainableParser<S, [Element]> where S.Element == Byte {
        let element: ChainableParser<S, Element> = index()
            .followed(by: expression()).followed(by: vector(of: index())) {
                Element(table: $0.0, offset: $0.1, initializer: $1)
            }
        return section(9, of: vector(of: element))
    }

    /// ## Code Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#code-section
    static func codeSection<S>() -> ChainableParser<S, [Code]> where S.Element == Byte {
        let locals: ChainableParser<S, [Value.Type]> = .init { stream, index in
            let (n, nEnd) = try uint(32).parse(stream: stream, index: index)
            let (type, typeEnd) = try valueType().parse(stream: stream, index: nEnd)
            return (Array(repeating: type, count: Int(n)), typeEnd)
        }
        let code: ChainableParser<S, Code> = .init { stream, index in
            let (size, sizeEnd) = try uint(32).parse(stream: stream, index: index)
            let (types, typesEnd) = try vector(of: locals).parse(stream: stream, index: sizeEnd)
            let (e, eEnd) = try expression().parse(stream: stream, index: typesEnd)
            let actualSize = sizeEnd.distance(to: eEnd)
            guard actualSize == size else {
                throw ParserStreamError<S>.codeInvalidSize(actualSize, expected: Int(size), location: eEnd)
            }
            let code = Code(locals: Array(types.joined()), expression: e)
            return (code, eEnd)
        }
        return section(10, of: vector(of: code))
    }

    /// ## Data Section
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#data-section
    static func dataSection<S>() -> ChainableParser<S, [Data]> where S.Element == Byte {
        let data: ChainableParser<S, Data> = index().followed(by: expression()).followed(by: vector(of: byte())) {
            Data(data: $0.0, offset: $0.1, initializer: $1)
        }
        return section(11, of: vector(of: data))
    }

    /// ## Module
    /// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#binary-module
    static func module<S>() -> ChainableParser<S, Module> where S.Element == Byte {
        return .init { stream, index in
            var index = index
            (_, index) = try bytes([0x00, 0x61, 0x73, 0x6D])!.parse(stream: stream, index: index)
            (_, index) = try bytes([0x01, 0x00, 0x00, 0x00])!.parse(stream: stream, index: index)

            var types: [FunctionType] = []
            var typeIndices: [TypeIndex] = []
            var codes: [Code] = []
            var tables: [Table] = []
            var memories: [Memory] = []
            var globals: [Global] = []
            var elements: [Element] = []
            var data: [Data] = []
            var start: FunctionIndex?
            var imports: [Import] = []
            var exports: [Export] = []

            do {
                let (result, i) = try typeSection().parse(stream: stream, index: index)
                index = i
                types = result
            } catch let error {
                print("typeSection", error)
            }

            do {
                let (result, i) = try importSection().parse(stream: stream, index: index)
                index = i
                imports = result
            } catch let error {
                print("importSection", error)
            }

            do {
                let (result, i) = try functionSection().parse(stream: stream, index: index)
                index = i
                typeIndices = result
            } catch let error {
                print("functionSection", error)
            }

            do {
                let (result, i) = try tableSection().parse(stream: stream, index: index)
                index = i
                tables = result
            } catch let error {
                print("tableSection", error)
            }

            do {
                let (result, i) = try memorySection().parse(stream: stream, index: index)
                index = i
                memories = result
            } catch let error {
                print("memorySection", error)
            }

            do {
                let (result, i) = try globalSection().parse(stream: stream, index: index)
                index = i
                globals = result
            } catch let error {
                print("globalSection", error)
            }

            do {
                let (result, i) = try exportSection().parse(stream: stream, index: index)
                index = i
                exports = result
            } catch let error {
                print("exportSection", error)
            }

            do {
                let (result, i) = try startSection().parse(stream: stream, index: index)
                index = i
                start = result
            } catch let error {
                print("startSection", error)
            }

            do {
                let (result, i) = try elementSection().parse(stream: stream, index: index)
                index = i
                elements = result
            } catch let error {
                print("elementSection", error)
            }

            do {
                let (result, i) = try codeSection().parse(stream: stream, index: index)
                index = i
                codes = result
            } catch let error {
                print("codeSection", error)
            }

            do {
                let (result, i) = try dataSection().parse(stream: stream, index: index)
                index = i
                data = result
            } catch let error {
                print("dataSection", error)
            }

            let functions = codes.enumerated().map { index, code in
                Function(type: typeIndices[index], locals: code.locals, body: code.expression)
            }

            let module = Module(
                types: types,
                functions: functions,
                tables: tables,
                memories: memories,
                globals: globals,
                elements: elements,
                data: data,
                start: start,
                imports: imports,
                exports: exports
            )

            return (module, index)
        }
    }
}
