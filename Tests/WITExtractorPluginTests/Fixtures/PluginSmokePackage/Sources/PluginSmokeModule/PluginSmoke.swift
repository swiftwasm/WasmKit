import WITMarker

@WIT
public struct StructA {
    @WIT public var memberB: Int

    @WIT public struct NestedStructC {
        @WIT public var memberD: Int
    }
}
