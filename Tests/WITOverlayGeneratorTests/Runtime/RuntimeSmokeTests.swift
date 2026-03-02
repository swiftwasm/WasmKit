import Testing
import WIT

@testable import WITOverlayGenerator

@Suite(TestEnvironmentTraits.runtimeAvailability)
struct RuntimeSmokeTests {
    @Test func callExportByGuest() throws {
        var harness = try RuntimeTestHarness(fixture: "Smoke")
        try harness.build(link: SmokeTestWorld.link) { (instance) in
            let component = SmokeTestWorld(instance: instance)
            _ = try component.hello()
        }
    }
}
