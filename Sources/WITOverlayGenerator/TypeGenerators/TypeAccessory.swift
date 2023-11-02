import WIT

public protocol SourceSummaryProvider {
    func enumCaseNames(byWITName witName: String) -> [String]?
    func qualifiedSwiftTypeName(byWITName witName: String) -> String?
}

struct EnumWitRawValueGetter {
    let swiftTypeName: String
    let fieldNames: [String]
    let type: EnumSyntax

    func print(printer: SourcePrinter) throws {
        let discriminantType = CanonicalABI.discriminantType(numberOfCases: UInt32(type.cases.count))
        printer.write(line: "extension \(swiftTypeName) {")
        printer.indent {
            printer.write(line: "var witRawValue: \(discriminantType.swiftTypeName) {")
            printer.indent {
                printer.write(line: "switch self {")
                printer.indent {
                    for (index, caseName) in fieldNames.enumerated() {
                        printer.write(line: "case .\(SwiftName.makeName(caseName)): return \(index)")
                    }
                }
                printer.write(line: "}")
            }
            printer.write(line: "}")

            printer.write(line: "init(witRawValue: \(discriminantType.swiftTypeName)) {")
            printer.indent {
                printer.write(line: "switch witRawValue {")
                printer.indent {
                    for (index, caseName) in fieldNames.enumerated() {
                        printer.write(line: "case \(index): self = .\(caseName)")
                    }
                    printer.write(line: "default: fatalError(\"Invalid discriminant value \\(witRawValue) for enum \(swiftTypeName)\")")
                }
                printer.write(line: "}")
            }
            printer.write(line: "}")
        }
        printer.write(line: "}")
    }
}
