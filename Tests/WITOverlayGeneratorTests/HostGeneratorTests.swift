import WIT
import XCTest

@testable import WITOverlayGenerator

class HostGeneratorTests: XCTestCase {
    // Host generators are already executed before running this test suite by SwiftPM build tool plugin,
    // but execute again here to collect coverage data.
    func testGenerateFromFixtures() throws {
        #if os(Android)
            throw XCTSkip("unable to run spectest on Android due to missing files on emulator")
        #endif
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
