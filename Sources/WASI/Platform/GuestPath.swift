/// A parsed WASI guest path.
///
/// Guest paths always use `/` separators and UTF-8, independent of the host
/// platform's path conventions. This type carries the *guest-side* structural
/// interpretation used by sandboxed path resolution; conversion to host
/// platform paths happens only at the syscall boundary.
struct GuestPath: Equatable {
    enum Component: Equatable {
        case regular(String)
        case currentDirectory
        case parentDirectory

        init(_ name: some StringProtocol) {
            switch name {
            case ".": self = .currentDirectory
            case "..": self = .parentDirectory
            default: self = .regular(String(name))
            }
        }

        var string: String {
            switch self {
            case .regular(let name): return name
            case .currentDirectory: return "."
            case .parentDirectory: return ".."
            }
        }
    }

    let isAbsolute: Bool
    private(set) var components: [Component]

    init(_ string: String) {
        self.isAbsolute = string.hasPrefix("/")
        // Splitting on "/" drops empty segments, which normalizes redundant
        // and trailing separators; whether a trailing "/" requires a
        // directory is decided by callers before parsing.
        self.components = string.split(separator: "/").map(Component.init)
    }

    /// Matches `FilePath.isEmpty`: no root and no components.
    var isEmpty: Bool { !isAbsolute && components.isEmpty }

    var string: String {
        (isAbsolute ? "/" : "") + components.map(\.string).joined(separator: "/")
    }

    mutating func removeLastComponent() -> Component? {
        components.popLast()
    }
}

/// Split the given path into the parent directory path and the last component
/// to be passed to `openat`-style calls.
///
/// Paths that structurally require a directory (trailing `/`, `/.`, or a
/// final `..`) resolve to the directory itself with a `"."` basename.
internal func splitParent(path: String) -> (GuestPath, GuestPath.Component)? {
    func pathRequiresDirectory(path: String) -> Bool {
        return path.hasSuffix("/") || path.hasSuffix("/.")
    }

    guard !path.isEmpty else { return nil }

    if pathRequiresDirectory(path: path) {
        // Create a link to the directory itself
        return (GuestPath(path), .currentDirectory)
    }

    let originalPath = GuestPath(path)
    var guestPath = originalPath
    if let c = guestPath.removeLastComponent() {
        switch c {
        case .regular, .currentDirectory:
            return (guestPath, c)
        case .parentDirectory:
            // Create a link to the parent directory itself
            return (originalPath, .currentDirectory)
        }
    } else {
        // A non-empty path with no components is all separators, which the
        // trailing-slash check above already handled.
        preconditionFailure("non-empty path should have at least one component")
    }
}
