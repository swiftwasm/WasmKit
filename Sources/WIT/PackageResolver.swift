import Foundation

/// A unit of WIT package managing a collection of WIT source files
public final class PackageUnit: Hashable, CustomStringConvertible {
    public let packageName: PackageNameSyntax
    public let sourceFiles: [SyntaxNode<SourceFileSyntax>]

    init(packageName: PackageNameSyntax, sourceFiles: [SyntaxNode<SourceFileSyntax>]) {
        self.packageName = packageName
        self.sourceFiles = sourceFiles
    }

    public var description: String {
        "PackageUnit(\(packageName))"
    }

    public static func == (lhs: PackageUnit, rhs: PackageUnit) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(packageName.name.text)
    }
}

/// A collection of WIT packages.
///
/// Responsible to find a package that satisfies the given requirement.
public final class PackageResolver: Hashable {
    private(set) var packages: [PackageUnit] = []

    /// Create a new package resolver.
    public init() {}

    /// Register a package to this resolver, creating a new package from the given source files.
    ///
    /// - Returns: A newly created package from the given source files.
    public func register(packageSources: [SyntaxNode<SourceFileSyntax>]) throws -> PackageUnit {
        var packageBuilder = PackageBuilder()
        for sourceFile in packageSources {
            try packageBuilder.append(sourceFile)
        }
        let package = try packageBuilder.build()
        register(packageUnit: package)
        return package
    }

    /// Register the given package to this resolver.
    public func register(packageUnit: PackageUnit) {
        packages.append(packageUnit)
    }

    func findPackage(
        namespace: String,
        package: String,
        version: Version?
    ) -> PackageUnit? {
        for pkg in self.packages {
            let found = Self.satisfyRequirement(
                pkg: pkg,
                namespace: namespace,
                packageName: package,
                version: version
            )
            if found { return pkg }
        }
        return nil
    }

    private static func satisfyRequirement(
        pkg: PackageUnit,
        namespace: String,
        packageName: String,
        version: Version?
    ) -> Bool {
        guard pkg.packageName.namespace.text == namespace,
            pkg.packageName.name.text == packageName
        else { return false }
        // If package user specify version, check package version
        if let version {
            if let candidateVersion = pkg.packageName.version {
                return candidateVersion.isCompatible(with: version)
            }
            // If candidate does not have a version specification, reject.
            return false
        }
        return true
    }

    public static func == (lhs: PackageResolver, rhs: PackageResolver) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension Version {
    /// Whether this version satisfies the given requirement.
    fileprivate func isCompatible(with requirement: Version) -> Bool {
        // Currently the same pre-release and build metadata are required
        // for compatibility with other WIT tools.
        return major == requirement.major && minor == requirement.minor && patch == requirement.patch && prerelease == requirement.prerelease && buildMetadata == requirement.buildMetadata
    }
}

// - MARK: Directory structure convention

/// A type to interact with files and directories required to load packages.
public protocol PackageFileLoader {
    /// A type that represents a file path in this loader.
    associatedtype FilePath: CustomStringConvertible

    /// Returns a list of WIT file paths contained in the given package directory.
    func packageFiles(in packageDirectory: FilePath) throws -> [FilePath]

    /// Returns text contents of a file at the given file path.
    func contentsOfWITFile(at filePath: FilePath) throws -> String

    /// Returns a list of directory paths contained in the given package directory.
    /// Typically, returns directory entries in `deps` directory under the package directory.
    func dependencyDirectories(from packageDirectory: FilePath) throws -> [FilePath]
}

extension PackageResolver {
    /// Parses a WIT package at the given directory path and its dependency packages.
    ///
    /// - Parameters:
    ///   - directory: A WIT package directory containing `*.wit` files and optionally `deps` directory.
    ///   - loader: A file loader used to load package contents.
    /// - Returns: A pair of the main package parsed from the given directory directly and package
    ///            resolver containing a set of packages including dependencies.
    public static func parse<Loader: PackageFileLoader>(
        directory: Loader.FilePath, loader: Loader
    ) throws -> (mainPackage: PackageUnit, packageResolver: PackageResolver) {
        let packageResolver = PackageResolver()
        let mainPackage = try PackageUnit.parse(directory: directory, loader: loader)
        packageResolver.register(packageUnit: mainPackage)

        for dependency in try loader.dependencyDirectories(from: directory) {
            let depPackage = try PackageUnit.parse(directory: dependency, loader: loader)
            packageResolver.register(packageUnit: depPackage)
        }
        return (mainPackage, packageResolver)
    }
}

extension PackageUnit {
    /// Parses a WIT package at the given directory path.
    ///
    /// - Parameters:
    ///   - directory: A WIT package directory containing `*.wit` files.
    ///   - loader: A file loader used to load package contents.
    /// - Returns: A package parsed from the given directory.
    public static func parse<Loader: PackageFileLoader>(
        directory: Loader.FilePath, loader: Loader
    ) throws -> PackageUnit {
        var packageBuilder = PackageBuilder()
        for filePath in try loader.packageFiles(in: directory) {
            try packageBuilder.append(
                SourceFileSyntax.parse(
                    filePath: filePath,
                    loader: loader
                )
            )
        }
        return try packageBuilder.build()
    }
}

extension SourceFileSyntax {
    /// Parses a WIT file at the given file path.
    ///
    /// - Parameters:
    ///   - filePath: A WIT file path.
    ///   - loader: A file loader used to load package contents.
    /// - Returns: A parsed WIT source file representation.
    public static func parse<Loader: PackageFileLoader>(
        filePath: Loader.FilePath, loader: Loader
    ) throws -> SyntaxNode<SourceFileSyntax> {
        let contents = try loader.contentsOfWITFile(at: filePath)
        return try SourceFileSyntax.parse(contents, fileName: filePath.description)
    }

    /// Parses the given WIT source
    ///
    /// - Parameters:
    ///   - contents: A WIT source contents
    ///   - fileName: A file name used for diagnostics
    /// - Returns: A parsed WIT source file representation.
    public static func parse(_ contents: String, fileName: String) throws -> SyntaxNode<SourceFileSyntax> {
        var lexer = Lexer(cursor: Lexer.Cursor(input: contents))
        return try SourceFileSyntax.parse(lexer: &lexer, fileName: fileName)
    }
}

#if !os(WASI)
    /// A ``PackageFileLoader`` adapter for local file system.
    public struct LocalFileLoader: PackageFileLoader {
        public typealias FilePath = String

        let fileManager: FileManager

        public init(fileManager: FileManager = .default) {
            self.fileManager = fileManager
        }

        enum Error: Swift.Error {
            case failedToLoadFile(FilePath)
        }

        private func isDirectory(filePath: String) -> Bool {
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory)
            return exists && isDirectory.boolValue
        }

        public func contentsOfWITFile(at filePath: String) throws -> String {
            guard let bytes = fileManager.contents(atPath: filePath) else {
                throw Error.failedToLoadFile(filePath)
            }
            return String(decoding: bytes, as: UTF8.self)
        }

        public func packageFiles(in packageDirectory: String) throws -> [String] {
            let dirURL = URL(fileURLWithPath: packageDirectory)
            return try fileManager.contentsOfDirectory(atPath: packageDirectory).filter { fileName in
                return fileName.hasSuffix(".wit")
                    && {
                        let filePath = dirURL.appendingPathComponent(fileName)
                        return !isDirectory(filePath: filePath.path)
                    }()
            }
            .map { dirURL.appendingPathComponent($0).path }
        }

        public func dependencyDirectories(from packageDirectory: String) throws -> [String] {
            let dirURL = URL(fileURLWithPath: packageDirectory)
            let depsDir = dirURL.appendingPathComponent("deps")
            guard isDirectory(filePath: depsDir.path) else { return [] }
            return try fileManager.contentsOfDirectory(atPath: depsDir.path)
        }
    }

#endif
