import WIT
import XCTest

@testable import WITOverlayGenerator

class RuntimeSmokeTests: XCTestCase {
    func testCallExportByGuest() throws {
        var harness = try RuntimeTestHarness(fixture: "Smoke")
        try harness.build(link: SmokeTestWorld.link(_:)) { (runtime, instance) in
            let component = SmokeTestWorld(instance: instance)
            _ = try component.hello()
        }
    }
}
