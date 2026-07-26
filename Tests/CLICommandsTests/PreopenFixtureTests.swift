import Foundation
import SystemExtras
import Testing

enum FixtureProbeError: Error, Equatable {
    case body
}

@Suite struct PreopenFixtureTests {
    @Test func aFailingDirectoryRemovalIsReportedOnce() throws {
        let error = #expect(throws: (any Error).self) {
            try PreopenFixture.withProbeDirectory { directory in
                try FileManager.default.removeItem(at: directory)
            }
        }
        let thrown = try #require(error)
        #expect(!(thrown is CleanupFailure))
    }

    @Test func theBodyErrorSurvivesTheCleanup() throws {
        var probeDirectory: URL?
        let error = #expect(throws: FixtureProbeError.self) {
            try PreopenFixture.withProbeDirectory { directory in
                probeDirectory = directory
                throw FixtureProbeError.body
            }
        }
        #expect(error == .body)
        #expect(!FileManager.default.fileExists(atPath: try #require(probeDirectory).path))
    }
}
