protocol SourcePrintable {
    func print(printer: SourcePrinter)
}
struct WITRecord {
    struct Field {
        var name: String
        var type: String
    }
    var name: String
    var fields: [Field]
}

extension WITRecord: SourcePrintable {
    func print(printer: SourcePrinter) {
        printer.write(line: "record \(name) {")
        printer.indent {
            for field in fields {
                printer.write(line: "\(field.name): \(field.type),")
            }
        }
        printer.write(line: "}")
    }
}

struct WITVariant {
    struct Case {
        var name: String
        var type: String?
    }
    var name: String
    var cases: [Case]
}

extension WITVariant: SourcePrintable {
    func print(printer: SourcePrinter) {
        printer.write(line: "variant \(name) {")
        printer.indent {
            for variantCase in cases {
                if let payloadType = variantCase.type {
                    printer.write(line: "\(variantCase.name)(\(payloadType)),")
                } else {
                    printer.write(line: "\(variantCase.name),")
                }
            }
        }
        printer.write(line: "}")
    }
}

struct WITEnum {
    var name: String
    var cases: [String]
}

extension WITEnum: SourcePrintable {
    func print(printer: SourcePrinter) {
        printer.write(line: "enum \(name) {")
        printer.indent {
            for enumCase in cases {
                printer.write(line: "\(enumCase),")
            }
        }
        printer.write(line: "}")
    }
}

struct WITFunction {
    struct Parameter {
        let name: String
        let type: String
    }
    enum Results {
        case named([Parameter])
        case anon(String)
    }
    let name: String
    let parameters: [Parameter]
    let results: Results
}

extension WITFunction: SourcePrintable {
    func print(printer: SourcePrinter) {
        func paramsString(_ parameters: [Parameter]) -> String {
            parameters.map {
                "\($0.name): \($0.type)"
            }.joined(separator: ", ")
        }
        let params = paramsString(parameters)
        let result: String
        switch results {
        case .anon(let type):
            result = " -> " + type
        case .named(let types):
            if !types.isEmpty {
                result = " -> (" + paramsString(types) + ")"
            } else {
                result = ""
            }
        }
        printer.write(line: name + ": func(\(params))" + result)
    }
}

struct WITBuilder {
    let interfaceName: String
    var definitions: [SourcePrintable] = []

    mutating func define(record: WITRecord) {
        definitions.append(record)
    }

    mutating func define(variant: WITVariant) {
        definitions.append(variant)
    }

    mutating func define(enum: WITEnum) {
        definitions.append(`enum`)
    }

    mutating func define(function: WITFunction) {
        definitions.append(function)
    }

    func print(printer: SourcePrinter) {
        printer.write(line: "interface \(interfaceName) {")
        printer.indent {
            for (index, type) in definitions.enumerated() {
                type.print(printer: printer)
                let isLast = index == definitions.count - 1
                if !isLast {
                    printer.emptyLine()
                }
            }
        }
        printer.write(line: "}")
    }
}
