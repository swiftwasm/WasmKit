#if os(macOS) || os(Linux)
    import Foundation

    /// The `wasmkit-cli` that SwiftPM built into the directory holding the running tests.
    package func wasmkitCLIExecutable() throws -> URL {
        let testBinary = runningTestBinary()
        let ancestors = sequence(first: testBinary) { $0.path == "/" ? nil : $0.deletingLastPathComponent() }
        // macOS loads `<products>/<name>.xctest/Contents/MacOS/<name>`. On Linux the test executable sits in
        // `<products>` itself, named `<name>.xctest`, or `<name>-test-runner` under Swift Build.
        let products = (ancestors.first { $0.pathExtension == "xctest" } ?? testBinary).deletingLastPathComponent()
        let executable = products.appendingPathComponent("wasmkit-cli")
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw MissingCLIExecutable(description: "No wasmkit-cli at \(executable.path); run `swift build` first.")
        }
        return executable
    }

    private func runningTestBinary() -> URL {
        #if os(macOS)
            // A host process loads the test bundle, and `Bundle.main` is that host.
            var info = Dl_info()
            if dladdr(#dsohandle, &info) != 0, let path = info.dli_fname {
                return URL(fileURLWithPath: String(cString: path))
            }
        #endif
        return Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0])
    }

    package struct MissingCLIExecutable: Error, CustomStringConvertible {
        package let description: String
    }
#endif
