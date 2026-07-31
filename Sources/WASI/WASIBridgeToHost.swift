import Synchronization
import WasmTypes

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
/// try bridge.runAndClose { wasi in
///     // ... use wasi ...
/// }
/// ```
public final class WASIBridgeToHost: Sendable {
    internal let underlying: WASIImplementation
    private let isClosed = Mutex(false)

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

        /// Creates file system options backed by a custom ``FileSystemImplementation``.
        ///
        /// Use this to run WASI guests on platforms where the built-in host
        /// file system is unavailable (e.g. embedded systems), by providing
        /// your own implementation of the platform-independent
        /// ``FileSystemImplementation`` protocol.
        ///
        /// - Parameter factory: A closure creating the file system implementation.
        /// - Returns: A configured `FileSystemOptions` instance using the custom file system.
        @_spi(WASIPlatform) public static func custom(_ factory: @escaping () throws -> any FileSystemImplementation) -> FileSystemOptions {
            return FileSystemOptions(factory: factory)
        }

        /// Configures the file system options with custom standard I/O streams.
        ///
        /// This method allows you to redirect stdin, stdout, and stderr to different
        /// file descriptors than the system defaults.
        ///
        /// - Parameters:
        ///   - stdin: A caller-owned platform file descriptor for standard input.
        ///     Defaults to `0`. Stdio descriptors are borrowed: WASI never closes them.
        ///   - stdout: A caller-owned platform file descriptor for standard output. Defaults to `1`.
        ///   - stderr: A caller-owned platform file descriptor for standard error. Defaults to `2`.
        /// - Returns: A new `FileSystemOptions` instance with the configured standard I/O streams.
        public func withStdio(
            stdin: CInt = 0,
            stdout: CInt = 1,
            stderr: CInt = 2
        ) -> FileSystemOptions {
            var options = self
            options.initializeStdio = { fdTable in
                fdTable[0] = .file(StdioFileEntry(fd: FileDescriptor(rawValue: stdin), accessMode: .read))
                fdTable[1] = .file(StdioFileEntry(fd: FileDescriptor(rawValue: stdout), accessMode: .write))
                fdTable[2] = .file(StdioFileEntry(fd: FileDescriptor(rawValue: stderr), accessMode: .write))
            }
            return options
        }

        /// Configures the file system options with custom standard I/O resources.
        ///
        /// Unlike the file-descriptor-based overload, this accepts arbitrary
        /// ``WASIFile`` implementations, so standard I/O can be routed to
        /// anything (e.g. a UART on an embedded system). The entries are
        /// treated as borrowed and are not closed by WASI unless their
        /// `isBorrowed` returns `false`.
        ///
        /// - Parameters:
        ///   - stdin: The resource serving file descriptor 0.
        ///   - stdout: The resource serving file descriptor 1.
        ///   - stderr: The resource serving file descriptor 2.
        /// - Returns: A new `FileSystemOptions` instance with the configured standard I/O streams.
        @_spi(WASIPlatform) public func withStdio(
            stdin: any WASIFile,
            stdout: any WASIFile,
            stderr: any WASIFile
        ) -> FileSystemOptions {
            var options = self
            options.initializeStdio = { fdTable in
                fdTable[0] = .file(stdin)
                fdTable[1] = .file(stdout)
                fdTable[2] = .file(stderr)
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

    /// Closes all owned file descriptors (preopened directories and any
    /// guest-opened files that were not closed by the WASI program).
    /// Borrowed descriptors (e.g. process stdio) are left open.
    public func close() throws {
        let shouldClose = isClosed.withLock { closed -> Bool in
            if closed { return false }
            closed = true
            return true
        }
        guard shouldClose else { return }
        try underlying.close()
    }

    /// Passes the bridge to `body`, then closes all owned file descriptors
    /// regardless of whether `body` returns normally or throws.
    ///
    /// - Parameter body: A closure that receives the bridge and returns a value.
    /// - Returns: The value returned by `body`.
    /// - Throws: `body`'s error, or the error from closing when `body` succeeded. When both fail, the
    ///   error carries both failures.
    public func runAndClose<R>(_ body: (WASIBridgeToHost) throws -> R) throws -> R {
        try withThrowing {
            try body(self)
        } defer: {
            try close()
        }
    }

    deinit {
        precondition(isClosed.withLock { $0 }, "WASIBridgeToHost.close() must be called before the bridge is deallocated")
    }

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
    ///   - stdin: Caller-owned platform file descriptor for standard input. Defaults to `0`.
    ///     Stdio descriptors are borrowed: WASI never closes them.
    ///   - stdout: Caller-owned platform file descriptor for standard output. Defaults to `1`.
    ///   - stderr: Caller-owned platform file descriptor for standard error. Defaults to `2`.
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
        stdin: CInt = 0,
        stdout: CInt = 1,
        stderr: CInt = 2,
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
    ///   - stdin: Caller-owned platform file descriptor for standard input. Defaults to `0`.
    ///     Stdio descriptors are borrowed: WASI never closes them.
    ///   - stdout: Caller-owned platform file descriptor for standard output. Defaults to `1`.
    ///   - stderr: Caller-owned platform file descriptor for standard error. Defaults to `2`.
    ///   - wallClock: Clock for wall-clock time queries. Defaults to `SystemWallClock()`.
    ///   - monotonicClock: Clock for monotonic time queries. Defaults to `SystemMonotonicClock()`.
    ///   - randomGenerator: Random number generator. Defaults to `SystemRandomNumberGenerator()`.
    /// - Throws: An error if the file system or preopens cannot be initialized.
    public convenience init(
        args: [String] = [],
        environment: [String: String] = [:],
        preopens: [Preopen] = [],
        stdin: CInt = 0,
        stdout: CInt = 1,
        stderr: CInt = 2,
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
    private init(
        args: [String],
        environment: [String: String],
        fileSystemOptions: FileSystemOptions,
        wallClock: WallClock,
        monotonicClock: MonotonicClock,
        randomGenerator: RandomBufferGenerator
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
        do {
            try underlying.fdTable.withLock { table in
                try fileSystemOptions.initializeStdio?(&table)
                try fileSystemOptions.initializePreopens?(fileSystem, &table)
            }
        } catch {
            // A throw here runs `deinit`, whose precondition requires `close()`, so release what was opened.
            throw CleanupFailure.preserving(error, cleanup: close)
        }
    }

    /// Creates a new WASI bridge with custom file system options.
    /// - Parameters:
    ///   - args: Command-line arguments to pass to the WASI module. Defaults to an empty array.
    ///   - environment: Environment variables to expose to the WASI module. Defaults to an empty dictionary.
    ///   - fileSystem: Configuration for the file system implementation. Defaults to `.host()`.
    ///   - wallClock: Clock for wall-clock time queries. Defaults to `SystemWallClock()`.
    ///   - monotonicClock: Clock for monotonic time queries. Defaults to `SystemMonotonicClock()`.
    ///   - randomGenerator: Random number generator. Defaults to `SystemRandomNumberGenerator()`.
    /// - Throws: An error if the file system or initialization fails.
    public convenience init(
        args: [String] = [],
        environment: [String: String] = [:],
        fileSystem fileSystemOptions: FileSystemOptions = .host().withStdio(),
        wallClock: WallClock = SystemWallClock(),
        monotonicClock: MonotonicClock = SystemMonotonicClock(),
        randomGenerator: RandomBufferGenerator = SystemRandomNumberGenerator()
    ) throws {
        try self.init(
            args: args, environment: environment, fileSystemOptions: fileSystemOptions,
            wallClock: wallClock, monotonicClock: monotonicClock,
            randomGenerator: randomGenerator
        )
    }
}
