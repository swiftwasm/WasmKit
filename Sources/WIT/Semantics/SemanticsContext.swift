public struct SemanticsContext {
    let evaluator: Evaluator
    public let rootPackage: PackageUnit
    public let packageResolver: PackageResolver

    public init(rootPackage: PackageUnit, packageResolver: PackageResolver) {
        self.evaluator = Evaluator()
        self.rootPackage = rootPackage
        self.packageResolver = packageResolver
    }
}
