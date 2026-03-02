import Foundation
import Testing
import WIT

@testable import WITOverlayGenerator

@Suite(TestEnvironmentTraits.hostGeneratorAvailability)
struct HostGeneratorTests {
    // Host generators are already executed before running this test suite by SwiftPM build tool plugin,
    // but execute again here to collect coverage data.
    @Test func generateFromFixtures() throws {
        let fixturesDir = RuntimeTestHarness.testsDirectory.appendingPathComponent("Fixtures")
        for fixture in try FileManager.default.contentsOfDirectory(atPath: fixturesDir.path) {
            let inputFileDir = fixturesDir.appendingPathComponent(fixture).appendingPathComponent("wit")
            guard FileManager.default.isDirectory(filePath: inputFileDir.path) else { continue }
            let (mainPackage, packageResolver) = try PackageResolver.parse(
                directory: inputFileDir.path,
                loader: LocalFileLoader()
            )
            let context = SemanticsContext(rootPackage: mainPackage, packageResolver: packageResolver)
            _ = try WITOverlayGenerator.generateHost(context: context)
        }
    }
}

extension FileManager {
    internal func isDirectory(filePath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: filePath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
