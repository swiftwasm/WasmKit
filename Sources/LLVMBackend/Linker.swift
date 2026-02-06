import Subprocess
import SystemPackage

package enum Linker {
    enum Error: Swift.Error {
        case unexpectedTerminationStatus(TerminationStatus)
    }

    package static func link(objectFilePath: FilePath) async throws -> FilePath {
        var dylibPath = objectFilePath
        let arguments: Arguments
        #if os(macOS)
            dylibPath.extension = "dylib"
            arguments = [
                "-dylib", objectFilePath.string,
                "-lSystem", "-L", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib",
                "-o", dylibPath.string,
            ]
        #elseif os(Linux)
            dylibPath.extension = "so"
            arguments = [
                "-shared", objectFilePath.string,
                "-o", dylibPath.string,
            ]
        #else
            #error("Linking native binaries is currently only supported on macOS and Linux")
        #endif

        let result = try await run(
            .name("ld"),
            arguments: arguments,
            output: .standardError
        )

        guard result.terminationStatus.isSuccess else {
            throw Error.unexpectedTerminationStatus(result.terminationStatus)
        }

        return dylibPath
    }
}
