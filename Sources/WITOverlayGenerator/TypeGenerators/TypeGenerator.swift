import WIT

struct TypeGenerator {
    let context: SemanticsContext

    func generate(printer: SourcePrinter) throws {
        for sourceFile in context.rootPackage.sourceFiles {
            for case .interface(let item) in sourceFile.items {
                var generator = InterfaceTypeGenerator(
                    printer: printer,
                    packageUnit: context.rootPackage,
                    interface: item,
                    signatureTranslation: SignatureTranslation(interfaceContext: nil)
                )
                try generator.generate()
            }
        }
    }
}
