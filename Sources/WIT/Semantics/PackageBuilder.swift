/// A type responsible to build a package from parsed `.wit` ASTs
struct PackageBuilder {
    var packageName: PackageNameSyntax?
    var sourceFiles: [SyntaxNode<SourceFileSyntax>] = []

    mutating func append(_ ast: SyntaxNode<SourceFileSyntax>) throws {
        // Check package name consistency
        switch (self.packageName, ast.packageId) {
        case (_, nil): break
        case (nil, let name?):
            self.packageName = name
        case (let existingName?, let newName?):
            guard existingName.isSamePackage(as: newName) else {
                throw DiagnosticError(
                    diagnostic: .inconsistentPackageName(
                        newName,
                        existingName: existingName,
                        textRange: newName.textRange
                    )
                )
            }
        }
        self.sourceFiles.append(ast)
    }

    func build() throws -> PackageUnit {
        guard let packageName = self.packageName else {
            throw DiagnosticError(diagnostic: .noPackageHeader())
        }
        return PackageUnit(packageName: packageName, sourceFiles: sourceFiles)
    }
}
