import Testing

enum TestEnvironmentTraits {
    static var witExtractorAvailability: any SuiteTrait {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            return .disabled("WITExtractor tests require Foundation.Process")
        #else
            guard TestSupport.Configuration.default != nil else {
                return .disabled("Please create 'Tests/default.json' before running WITExtractor tests")
            }
            return .enabled(if: true)
        #endif
    }
}
