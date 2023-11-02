import XCTest
import WIT
@testable import WITOverlayGenerator

class RuntimeSmokeTests: XCTestCase {
    func testCallExportByGuest() throws {
        var harness = try RuntimeTestHarness(fixture: "Smoke")
        let (runtime, instance) = try harness.build(link: SmokeTestWorld.link(_:))
        let component = SmokeTestWorld(moduleInstance: instance)
        _ = try component.hello(runtime: runtime)
    }
}
