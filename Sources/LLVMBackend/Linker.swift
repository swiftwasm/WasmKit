import Subprocess
import SystemPackage

package enum Linker {
    enum Error: Swift.Error {
        case unexpectedTerminationStatus(TerminationStatus)
    }

    package static func link(objectFilePath: FilePath) async throws -> FilePath {
        #if os(macOS)
            var dylibPath = objectFilePath
            dylibPath.extension = "dylib"
            let result = try await run(
                .name("ld"),
                arguments: [
                    "-dylib", objectFilePath.string,
                    "-lSystem", "-L", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib",
                    "-o", dylibPath.string,
                ],
                output: .standardError
            )

            guard result.terminationStatus.isSuccess else {
                throw Error.unexpectedTerminationStatus(result.terminationStatus)
            }

            return dylibPath
        #else
            #error("Linking native binaries is currently only supported on macOS")
        #endif
    }
}
