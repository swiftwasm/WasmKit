@_spi(WIT)
public struct StructA {
    @_spi(WIT) public var memberB: Int

    @_spi(WIT) public struct NestedStructC {
        @_spi(WIT) public var memberD: Int
    }
}
