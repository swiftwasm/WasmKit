import WIT

/// A printer responsible for printing a source code of WasmKit
struct WasmKitSourcePrinter {
    /// Prints a core value representation
    /// - Parameters:
    ///   - operand: Lowered core value representation
    ///   - type: Core type of the operand
    func printNewValue<Operand: CustomStringConvertible>(
        _ operand: Operand, type: CanonicalABI.CoreType
    ) -> String {
        // Integers are lowered as signed but ``WasmKit/Value`` use unsigned
        let rawValue: String
        switch type {
        case .i32: rawValue = "UInt32(bitPattern: \(operand))"
        case .i64: rawValue = "UInt64(bitPattern: \(operand))"
        case .f32, .f64: rawValue = "\(operand).bitPattern"
        }
        return "Value.\(type)(\(rawValue))"
    }
}
