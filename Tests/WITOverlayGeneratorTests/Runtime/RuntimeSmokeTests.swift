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

    @Test func staticConstructorsRunOncePerInstance() throws {
        var harness = try RuntimeTestHarness(fixture: "StaticConstructors")
        try harness.build(link: StaticConstructorsTestWorld.link) { (instance) in
            let component = StaticConstructorsTestWorld(instance: instance)
            let runsAfterFirstCall = try component.constructorRuns()
            let runsAfterSecondCall = try component.constructorRuns()
            #expect(runsAfterFirstCall == 1)
            #expect(runsAfterSecondCall == 1)
        }
    }
}
