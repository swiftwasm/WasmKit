import Testing

enum TestEnvironmentTraits {
    static var runtimeAvailability: any SuiteTrait {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            return .disabled("Runtime tests require launching external processes (macOS/Linux only).")
        #else
            guard RuntimeTestHarness.Configuration.default != nil else {
                return .disabled("Runtime tests require Tests/default.json (see RuntimeTestHarness.Configuration).")
            }
            return .enabled(if: true)
        #endif
    }

    static var hostGeneratorAvailability: any SuiteTrait {
        #if os(Android)
            return .disabled("Host generator fixtures are unavailable on Android emulators.")
        #else
            return .enabled(if: true)
        #endif
    }
}
