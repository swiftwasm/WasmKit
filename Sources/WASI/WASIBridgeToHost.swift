import SystemPackage

/// A bridge that connects WebAssembly System Interface (WASI) calls to the host system.
///
/// `WASIBridgeToHost` provides a high-level interface for configuring and executing
/// WASI-compliant WebAssembly modules. It handles file system access, standard I/O,
/// command-line arguments, environment variables, and system resources like clocks
/// and random number generation.
///
/// ## Usage Example
/// ```swift
/// let bridge = try WASIBridgeToHost(
///     args: ["program", "--flag"],
///     environment: ["PATH": "/usr/bin"],
///     preopens: [WASIBridgeToHost.Preopen(guestPath: "/sandbox", hostPath: "/real/path")]
/// )
/// ```
public final class WASIBridgeToHost {
    internal let underlying: WASIImplementation

    /// A preopened directory mapping from a guest path to a host path.
    ///
    /// The order of preopens can be observable via file descriptor assignment (starting at 3).
    public struct Preopen: Sendable {
        public let guestPath: String
        public let hostPath: String

        public init(guestPath: String, hostPath: String) {
            self.guestPath = guestPath
            self.hostPath = hostPath
        }
    }

    /// Configuration options for the file system implementation used by WASI.
    ///
    /// This structure allows you to choose between different file system backends
    /// (host file system or in-memory file system) and configure standard I/O streams.
    public struct FileSystemOptions {
        internal let factory: () throws -> FileSystemImplementation
        internal var initializeStdio: ((inout FdTable) throws -> Void)?
        internal var initializePreopens: ((FileSystemImplementation, inout FdTable) throws -> Void)?

        /// Creates file system options that use the host operating system's file system.
        ///
        /// - Returns: A configured `FileSystemOptions` instance using the host file system.
        public static func host() -> FileSystemOptions {
            return FileSystemOptions(factory: { HostFileSystem() })
        }

        /// Creates file system options that use an in-memory file system.
        ///
        /// - Parameter fileSystem: A pre-configured `MemoryFileSystem` instance.
        /// - Returns: A configured `FileSystemOptions` instance using the memory file system.
        public static func memory(_ fileSystem: MemoryFileSystem) -> FileSystemOptions {
            return FileSystemOptions(factory: { fileSystem })
        }

        /// Configures the file system options with custom standard I/O streams.
        ///
        /// This method allows you to redirect stdin, stdout, and stderr to different
        /// file descriptors than the system defaults.
        ///
        /// - Parameters:
        ///   - stdin: The file descriptor to use for standard input. Defaults to `.standardInput`.
        ///   - stdout: The file descriptor to use for standard output. Defaults to `.standardOutput`.
        ///   - stderr: The file descriptor to use for standard error. Defaults to `.standardError`.
        /// - Returns: A new `FileSystemOptions` instance with the configured standard I/O streams.
        public func withStdio(
            stdin: FileDescriptor = .standardInput,
            stdout: FileDescriptor = .standardOutput,
            stderr: FileDescriptor = .standardError
        ) -> FileSystemOptions {
            var options = self
            options.initializeStdio = { fdTable in
                fdTable[0] = .file(StdioFileEntry(fd: stdin, accessMode: .read))
                fdTable[1] = .file(StdioFileEntry(fd: stdout, accessMode: .write))
                fdTable[2] = .file(StdioFileEntry(fd: stderr, accessMode: .write))
            }
            return options
        }

        /// Configures the file system options with preopens.
        ///
        /// - Parameter preopens: An ordered list mapping guest paths to host paths. These
        ///   directories will be pre-opened and made accessible to the WebAssembly module.
        /// - Returns: A new `FileSystemOptions` instance with the configured preopens.
        public func withPreopens(_ preopens: [Preopen]) -> FileSystemOptions {
            var options = self
            options.initializePreopens = { fileSystem, fdTable in
                for preopen in preopens {
                    let dirEntry = try fileSystem.preopenDirectory(guestPath: preopen.guestPath, hostPath: preopen.hostPath)
                    _ = try fdTable.push(.directory(dirEntry))
                }
            }
            return options
        }
    }

    /// The WASI host modules that implement the WASI system calls.
    ///
    /// This property provides access to the underlying host module implementations,
    /// which can be used to register with a WebAssembly runtime.
    public var wasiHostModules: [String: WASIHostModule] { underlying._hostModules }

    /// Creates a new WASI bridge with host file system access.
    ///
    /// This is a convenience initializer that automatically configures the bridge
    /// to use the host operating system's file system with the specified preopens
    /// and standard I/O descriptors.
    ///
    /// - Parameters:
    ///   - args: Command-line arguments to pass to the WASI module. Defaults to an empty array.
    ///   - environment: Environment variables to expose to the WASI module. Defaults to an empty dictionary.
    ///   - preopens: Pre-opened directories mapping guest paths to host paths. Defaults to an empty dictionary.
    ///   - stdin: File descriptor for standard input. Defaults to `.standardInput`.
    ///   - stdout: File descriptor for standard output. Defaults to `.standardOutput`.
    ///   - stderr: File descriptor for standard error. Defaults to `.standardError`.
    ///   - wallClock: Clock for wall-clock time queries. Defaults to `SystemWallClock()`.
    ///   - monotonicClock: Clock for monotonic time queries. Defaults to `SystemMonotonicClock()`.
    ///   - randomGenerator: Random number generator. Defaults to `SystemRandomNumberGenerator()`.
    /// - Throws: An error if the file system or preopens cannot be initialized.
    @available(*, deprecated, message: "Use the ordered `preopens: [WASIBridgeToHost.Preopen]` initializer instead.")
    @_disfavoredOverload
    public convenience init(
        args: [String] = [],
        environment: [String: String] = [:],
        preopens: [String: String] = [:],
        stdin: FileDescriptor = .standardInput,
        stdout: FileDescriptor = .standardOutput,
        stderr: FileDescriptor = .standardError,
        wallClock: WallClock = SystemWallClock(),
        monotonicClock: MonotonicClock = SystemMonotonicClock(),
        randomGenerator: RandomBufferGenerator = SystemRandomNumberGenerator()
    ) throws {
        let preopens = preopens.map { Preopen(guestPath: $0.key, hostPath: $0.value) }
        try self.init(
            args: args,
            environment: environment,
            preopens: preopens,
            stdin: stdin,
            stdout: stdout,
            stderr: stderr,
            wallClock: wallClock,
            monotonicClock: monotonicClock,
            randomGenerator: randomGenerator
        )
    }

    /// Creates a new WASI bridge with host file system access.
    ///
    /// This initializer takes an ordered list of preopens. The order can be observable
    /// via file descriptor assignment (starting at 3).
    ///
    /// - Parameters:
    ///   - args: Command-line arguments to pass to the WASI module. Defaults to an empty array.
    ///   - environment: Environment variables to expose to the WASI module. Defaults to an empty dictionary.
    ///   - preopens: Pre-opened directories mapping guest paths to host paths. Defaults to an empty array.
    ///   - stdin: File descriptor for standard input. Defaults to `.standardInput`.
    ///   - stdout: File descriptor for standard output. Defaults to `.standardOutput`.
    ///   - stderr: File descriptor for standard error. Defaults to `.standardError`.
    ///   - wallClock: Clock for wall-clock time queries. Defaults to `SystemWallClock()`.
    ///   - monotonicClock: Clock for monotonic time queries. Defaults to `SystemMonotonicClock()`.
    ///   - randomGenerator: Random number generator. Defaults to `SystemRandomNumberGenerator()`.
    /// - Throws: An error if the file system or preopens cannot be initialized.
    public convenience init(
        args: [String] = [],
        environment: [String: String] = [:],
        preopens: [Preopen] = [],
        stdin: FileDescriptor = .standardInput,
        stdout: FileDescriptor = .standardOutput,
        stderr: FileDescriptor = .standardError,
        wallClock: WallClock = SystemWallClock(),
        monotonicClock: MonotonicClock = SystemMonotonicClock(),
        randomGenerator: RandomBufferGenerator = SystemRandomNumberGenerator()
    ) throws {
        try self.init(
            args: args,
            environment: environment,
            fileSystem: .host().withStdio(stdin: stdin, stdout: stdout, stderr: stderr).withPreopens(preopens),
            wallClock: wallClock,
            monotonicClock: monotonicClock,
            randomGenerator: randomGenerator
        )
    }

    /// Creates a new WASI bridge with custom file system options.
    ///
    /// This is the designated initializer that allows full control over the file system
    /// backend (host or in-memory) and all other WASI subsystems.
    ///
    /// - Parameters:
    ///   - args: Command-line arguments to pass to the WASI module. Defaults to an empty array.
    ///   - environment: Environment variables to expose to the WASI module. Defaults to an empty dictionary.
    ///   - fileSystem: Configuration for the file system implementation. Defaults to `.host()`.
    ///   - wallClock: Clock for wall-clock time queries. Defaults to `SystemWallClock()`.
    ///   - monotonicClock: Clock for monotonic time queries. Defaults to `SystemMonotonicClock()`.
    ///   - randomGenerator: Random number generator. Defaults to `SystemRandomNumberGenerator()`.
    /// - Throws: An error if the file system or initialization fails.
    public init(
        args: [String] = [],
        environment: [String: String] = [:],
        fileSystem fileSystemOptions: FileSystemOptions = .host().withStdio(),
        wallClock: WallClock = SystemWallClock(),
        monotonicClock: MonotonicClock = SystemMonotonicClock(),
        randomGenerator: RandomBufferGenerator = SystemRandomNumberGenerator()
    ) throws {
        let fileSystem = try fileSystemOptions.factory()
        self.underlying = try WASIImplementation(
            args: args,
            environment: environment,
            fileSystem: fileSystem,
            wallClock: wallClock,
            monotonicClock: monotonicClock,
            randomGenerator: randomGenerator
        )
        try fileSystemOptions.initializeStdio?(&underlying.fdTable)
        try fileSystemOptions.initializePreopens?(fileSystem, &underlying.fdTable)
    }
}
