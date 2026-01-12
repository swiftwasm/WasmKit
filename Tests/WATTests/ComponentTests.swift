import Testing

@testable import WAT

@Suite
struct ComponentTests {
    @Test
    func parseComponent() throws {
        var parser = ComponentWatParser(
        #"""
        (component)
        (component $foo)
        """#, features: .default)

        var accummulated = [String?]()
        while let field = try parser.next() {
            switch field.kind {
            case .component(let name):
                accummulated.append(name?.value)
            case _:
                #expect((false), "Expected only component directive")
            }
        }

        #expect(accummulated == [nil, "$foo"])
    }
}
