#if ComponentModel
    import ComponentModel
    import Foundation

    /// WAVE Formatter - Converts ComponentValues to WAVE text format
public enum WAVEFormatter {

    /// Format a ComponentValue to WAVE text
    public static func format(_ value: ComponentValue) -> String {
        switch value {
        case .bool(let b):
            return b ? "true" : "false"

        case .u8(let v):
            return String(v)
        case .u16(let v):
            return String(v)
        case .u32(let v):
            return String(v)
        case .u64(let v):
            return String(v)

        case .s8(let v):
            return String(v)
        case .s16(let v):
            return String(v)
        case .s32(let v):
            return String(v)
        case .s64(let v):
            return String(v)

        case .float32(let v):
            return formatFloat32(v)
        case .float64(let v):
            return formatFloat64(v)

        case .char(let scalar):
            return formatChar(scalar)

        case .string(let str):
            return formatString(str)

        case .list(let elements):
            let formatted = elements.map { format($0) }
            return "[" + formatted.joined(separator: ", ") + "]"

        case .tuple(let elements):
            let formatted = elements.map { format($0) }
            return "(" + formatted.joined(separator: ", ") + ")"

        case .record(let fields):
            return formatRecord(fields)

        case .variant(let caseName, let payload):
            return formatVariant(caseName: caseName, payload: payload)

        case .enum(let caseName):
            return formatLabel(caseName, isKeyword: isKeyword(caseName))

        case .flags(let flagSet):
            return formatFlags(flagSet)

        case .option(let inner):
            return formatOption(inner)

        case .result(let ok, let error):
            return formatResult(ok: ok, error: error)
        }
    }
}
        // MARK: - Float Formatting

        private func formatFloat32(_ value: Float) -> String {
            if value.isNaN {
                return "nan"
            } else if value.isInfinite {
                return value > 0 ? "inf" : "-inf"
            } else if value == 0 {
                // Preserve negative zero
                return value.sign == .minus ? "-0" : "0"
            } else {
                // f32 has ~7-8 significant decimal digits
                return formatFloatWithSignificantDigits(Double(value), significantDigits: 8)
            }
        }

        private func formatFloat64(_ value: Double) -> String {
            if value.isNaN {
                return "nan"
            } else if value.isInfinite {
                return value > 0 ? "inf" : "-inf"
            } else if value == 0 {
                // Preserve negative zero
                return value.sign == .minus ? "-0" : "0"
            } else {
                // f64 has ~15-17 significant decimal digits
                return formatFloatWithSignificantDigits(value, significantDigits: 15)
            }
        }

        private func formatFloatWithSignificantDigits(_ value: Double, significantDigits: Int) -> String {
            let absValue = abs(value)
            let sign = value < 0 ? "-" : ""

            // Check if it's effectively an integer
            if absValue >= 1 && absValue < Double(Int64.max) && absValue.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int64(value))
            }

            // Get the exponent (power of 10)
            let exponent = absValue > 0 ? Int(floor(log10(absValue))) : 0

            // For very small subnormal-range values (< ~1e-38), use just 1 significant digit
            // to match reference implementation behavior
            let effectiveSigDigits = exponent < -38 ? 1 : significantDigits

            // Round to significant digits
            let scale = pow(10.0, Double(effectiveSigDigits - 1 - exponent))
            let rounded = (absValue * scale).rounded() / scale

            // Format based on magnitude
            if exponent >= significantDigits || exponent < -(significantDigits + 5) {
                // Very large or very small - expand to full decimal
                return sign + expandToDecimal(rounded, exponent: exponent, significantDigits: effectiveSigDigits)
            } else if exponent >= 0 {
                // Normal range >= 1
                let formatted = String(format: "%.\(max(0, effectiveSigDigits - 1 - exponent))f", rounded)
                return sign + trimTrailingZeros(formatted)
            } else {
                // Fractional (0 < abs < 1)
                let decimalPlaces = -exponent + effectiveSigDigits - 1
                let formatted = String(format: "%.\(decimalPlaces)f", rounded)
                return sign + trimTrailingZeros(formatted)
            }
        }

        private func expandToDecimal(_ value: Double, exponent: Int, significantDigits: Int) -> String {
            if exponent >= 0 {
                // Large number - expand with trailing zeros
                let mantissa = Int64((value / pow(10.0, Double(exponent - significantDigits + 1))).rounded())
                var result = String(mantissa)
                let trailingZeros = exponent - significantDigits + 1
                if trailingZeros > 0 {
                    result += String(repeating: "0", count: trailingZeros)
                }
                return result
            } else {
                // Small number - expand with leading zeros
                let leadingZeros = -exponent - 1
                let mantissa = Int64((value * pow(10.0, Double(-exponent + significantDigits - 1))).rounded())
                var mantissaStr = String(mantissa)
                // Trim trailing zeros from mantissa
                while mantissaStr.hasSuffix("0") && mantissaStr.count > 1 {
                    mantissaStr = String(mantissaStr.dropLast())
                }
                return "0." + String(repeating: "0", count: leadingZeros) + mantissaStr
            }
        }

        private func trimTrailingZeros(_ str: String) -> Substring {
            var result = Substring(str)
            if result.contains(".") {
                while result.hasSuffix("0") {
                    result = result.dropLast()
                }
                if result.hasSuffix(".") {
                    result = result.dropLast()
                }
            }
            return result
        }

        // MARK: - Char Formatting

        private func formatChar(_ scalar: Unicode.Scalar) -> String {
            var result = "'"
            appendEscaped(scalar, to: &result, forChar: true)
            result.append("'")
            return result
        }

        // MARK: - String Formatting

        private func formatString(_ str: String) -> String {
            var result = "\""
            for scalar in str.unicodeScalars {
                appendEscaped(scalar, to: &result, forChar: false)
            }
            result.append("\"")
            return result
        }

        private func appendEscaped(_ scalar: Unicode.Scalar, to result: inout String, forChar: Bool) {
            switch scalar {
            case "\\": result.append("\\\\")
            case "\"": result.append("\\\"")
            case "'": result.append("\\'")
            case "\t": result.append("\\t")
            case "\n": result.append("\\n")
            case "\r": result.append("\\r")
            default:
                // Direct character for printable ASCII and common Unicode
                if scalar.value >= 0x20 && scalar.value < 0x7F {
                    result.append(Character(scalar))
                } else if scalar.value >= 0x80 {
                    // Non-ASCII Unicode - output directly
                    result.append(Character(scalar))
                } else {
                    // Control characters - use unicode escape
                    result.append("\\u{")
                    result.append(String(scalar.value, radix: 16))
                    result.append("}")
                }
            }
        }

        // MARK: - Record Formatting

        private func formatRecord(_ fields: [(name: String, value: ComponentValue)]) -> String {
            // Filter out none values for optional fields
            let nonNoneFields = fields.filter { field in
                if case .option(nil) = field.value {
                    return false
                }
                return true
            }

            if nonNoneFields.isEmpty {
                return "{:}"
            }

            let formatted = nonNoneFields.map { field in
                "\(field.name): \(WAVEFormatter.format(field.value))"
            }

            return "{" + formatted.joined(separator: ", ") + "}"
        }

        // MARK: - Variant Formatting

        private func formatVariant(caseName: String, payload: ComponentValue?) -> String {
            let label = formatLabel(caseName, isKeyword: isKeyword(caseName))

            if let payload = payload {
                return "\(label)(\(WAVEFormatter.format(payload)))"
            } else {
                return label
            }
        }

        // MARK: - Flags Formatting

        private func formatFlags(_ flagSet: Set<String>) -> String {
            if flagSet.isEmpty {
                return "{}"
            }

            // Sort flags for consistent output
            let sorted = flagSet.sorted()
            return "{" + sorted.joined(separator: ", ") + "}"
        }

        // MARK: - Option Formatting

        private func formatOption(_ inner: ComponentValue?) -> String {
            guard let inner = inner else {
                return "none"
            }

            // Always use explicit some() form to match reference implementation
            return "some(\(WAVEFormatter.format(inner)))"
        }

        // MARK: - Result Formatting

        private func formatResult(ok: ComponentValue?, error: ComponentValue?) -> String {
            if let error = error {
                // Check for empty tuple marker (err case with no payload)
                if case .tuple(let elements) = error, elements.isEmpty {
                    return "err"
                }
                return "err(\(WAVEFormatter.format(error)))"
            }

            if let ok = ok {
                // Always use explicit ok() form to match reference implementation
                return "ok(\(WAVEFormatter.format(ok)))"
            }

            return "ok"
        }

        // MARK: - Label Formatting

        /// Format a label, escaping with % if it's a keyword
        private func formatLabel(_ name: String, isKeyword: Bool) -> String {
            if isKeyword {
                return "%\(name)"
            }
            return name
        }

        /// Check if a name is a WAVE keyword
        private func isKeyword(_ name: String) -> Bool {
            switch name {
            case "true", "false", "nan", "inf", "some", "none", "ok", "err":
                return true
            default:
                return false
            }
        }

        // MARK: - Function Call Formatting

        /// Format a function call with named parameters
        public func formatFunctionCall(
            name: String,
            params: [(name: String, value: ComponentValue)]
        ) -> String {
            let formatted = params.map { param in
                "\(param.name): \(WAVEFormatter.format(param.value))"
            }

            return "\(name)(\(formatted.joined(separator: ", ")))"
        }

#endif
