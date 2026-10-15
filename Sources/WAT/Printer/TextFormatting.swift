import WasmParser

/// `bytes` as a quoted WAT string literal. Bytes from 0x80 up are written as
/// they are when `keepingUTF8` is set, and escaped otherwise.
func watStringLiteral(_ bytes: some Sequence<UInt8>, keepingUTF8: Bool) -> String {
    var text: [UInt8] = [UInt8(ascii: "\"")]
    for byte in bytes {
        switch byte {
        case 0x09: text += [UInt8(ascii: "\\"), UInt8(ascii: "t")]
        case 0x0A: text += [UInt8(ascii: "\\"), UInt8(ascii: "n")]
        case 0x0D: text += [UInt8(ascii: "\\"), UInt8(ascii: "r")]
        case 0x22, 0x5C: text += [UInt8(ascii: "\\"), byte]
        case 0x20...0x7E: text.append(byte)
        case 0x80... where keepingUTF8: text.append(byte)
        default: text += [UInt8(ascii: "\\"), hexDigit(byte >> 4), hexDigit(byte & 0x0F)]
        }
    }
    text.append(UInt8(ascii: "\""))
    return String(decoding: text, as: UTF8.self)
}

private func hexDigit(_ value: UInt8) -> UInt8 {
    value < 10 ? UInt8(ascii: "0") + value : UInt8(ascii: "a") + value - 10
}

func formatF32(_ v: IEEE754.Float32) -> String {
    let f = Float32(bitPattern: v.bitPattern)
    if f.isNaN {
        let payload = v.bitPattern & 0x7FFFFF
        let signStr = (v.bitPattern & 0x8000_0000) != 0 ? "-" : ""
        if payload == 0x400000 {
            return "\(signStr)nan"  // canonical NaN
        }
        return "\(signStr)nan:0x\(String(payload, radix: 16))"
    }
    if f.isInfinite { return f > 0 ? "inf" : "-inf" }
    return hexFloat32(v.bitPattern)
}

func formatF64(_ v: IEEE754.Float64) -> String {
    let f = Double(bitPattern: v.bitPattern)
    if f.isNaN {
        let payload = v.bitPattern & 0x000F_FFFF_FFFF_FFFF
        let signStr = (v.bitPattern & 0x8000_0000_0000_0000) != 0 ? "-" : ""
        if payload == 0x0008_0000_0000_0000 {
            return "\(signStr)nan"  // canonical NaN
        }
        return "\(signStr)nan:0x\(String(payload, radix: 16))"
    }
    if f.isInfinite { return f > 0 ? "inf" : "-inf" }
    return hexFloat64(v.bitPattern)
}

private func hexFloat32(_ bits: UInt32) -> String {
    let sign = (bits >> 31) != 0 ? "-" : ""
    let exp = Int((bits >> 23) & 0xFF)
    let mantissa = bits & 0x7FFFFF

    if exp == 0 {
        if mantissa == 0 { return "\(sign)0x0p+0" }
        return "\(sign)0x\(String(mantissa, radix: 16))p-149"
    }
    let e = exp - 127
    // Shift the 23 fraction bits to 24, a whole number of hex digits.
    let mant = fractionText(mantissa << 1, digits: 6)
    let eSign = e >= 0 ? "+" : ""
    return "\(sign)0x1\(mant)p\(eSign)\(e)"
}

private func hexFloat64(_ bits: UInt64) -> String {
    let sign = (bits >> 63) != 0 ? "-" : ""
    let exp = Int((bits >> 52) & 0x7FF)
    let mantissa = bits & 0x000F_FFFF_FFFF_FFFF

    if exp == 0 {
        if mantissa == 0 { return "\(sign)0x0p+0" }
        return "\(sign)0x\(String(mantissa, radix: 16))p-1074"
    }
    let e = exp - 1023
    let mant = fractionText(mantissa, digits: 13)
    let eSign = e >= 0 ? "+" : ""
    return "\(sign)0x1\(mant)p\(eSign)\(e)"
}

private func fractionText(_ bits: some BinaryInteger, digits: Int) -> String {
    var text = Array(String(bits, radix: 16).utf8)
    text.insert(contentsOf: repeatElement(UInt8(ascii: "0"), count: digits - text.count), at: 0)
    while text.last == UInt8(ascii: "0") {
        text.removeLast()
    }
    return text.isEmpty ? "" : "." + String(decoding: text, as: UTF8.self)
}
