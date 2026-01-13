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
        (component
          (core module)
          (core module)
          (core module)
        )
        (component $bar
          (core module
            (func (export "a") (result i32) i32.const 0)
            (func (export "b") (result i64) i64.const 0)
          )
          (core module
            (func (export "c") (result f32) f32.const 0)
            (func (export "d") (result f64) f64.const 0)
          )
        )
        """#, features: .default)

        var accummulated = [String?]()
        while let field = try parser.next() {
            switch field.kind {
            case .component(let name, let decls):
                accummulated.append(name?.value)
            case _:
                #expect((false), "Expected only component directive")
            }
        }

        #expect(accummulated == [nil, "$foo", nil, "$bar"])
    }
}
