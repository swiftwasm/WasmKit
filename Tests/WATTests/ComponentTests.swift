#if ComponentModel

import Testing

@testable import WAT

@Suite
struct ComponentTests {
    @Test
    func parseComponent() throws {
        let output = try ComponentWatParser(
            #"""
            (component)
            (component $foo)
            (component
              (core module)
              (core module)
              (core module)
            )
            (component $bar
              (core module $m1
                (func (export "a") (result i32) i32.const 0)
                (func (export "b") (result i64) i64.const 0)
              )
              (core module $m2
                (func (export "c") (result f32) f32.const 0)
                (func (export "d") (result f64) f64.const 0)
              )
              (core instance $M1 (instantiate $m1 (with "c" (instance $d))))
              (func (export "a") (canon lift (core func $m "")))
            )
            """#,
            features: .default
        ).parse()

        #expect(output.fields.count == 4)
        #expect(output.componentsMap.count == 4)

        let names = Array(output.componentsMap.nameToIndex.keys).sorted(by: {
            output.componentsMap.nameToIndex[$0]! < output.componentsMap.nameToIndex[$1]!
        })
        #expect(names == ["$foo", "$bar"])

        guard case .component(let comp0Index) = output.fields[0].kind else {
            Issue.record("Expected component at index 0")
            return
        }
        let comp0 = output.componentsMap[.init(comp0Index.rawValue)]
        #expect(comp0.fields.count == 0)
        #expect(comp0.id == nil)

        guard case .component(let comp1Index) = output.fields[1].kind else {
            Issue.record("Expected component at index 1")
            return
        }
        let comp1 = output.componentsMap[.init(comp1Index.rawValue)]
        #expect(comp1.fields.count == 0)
        #expect(comp1.id?.value == "$foo")

        guard case .component(let comp2Index) = output.fields[2].kind else {
            Issue.record("Expected component at index 2")
            return
        }
        let comp2 = output.componentsMap[.init(comp2Index.rawValue)]
        #expect(comp2.fields.count == 3)
        #expect(comp2.id == nil)
        for i in 0..<3 {
            guard case .coreModule = comp2.fields[i].kind else {
                Issue.record("Expected core module at comp2.fields[\(i)]")
                return
            }
        }

        guard case .component(let comp3Index) = output.fields[3].kind else {
            Issue.record("Expected component at index 3")
            return
        }
        let comp3 = output.componentsMap[.init(comp3Index.rawValue)]
        #expect(comp3.id?.value == "$bar")

        #expect(comp3.fields.count == 5)

        guard case .coreModule(let m1Index) = comp3.fields[0].kind else {
            Issue.record("Expected core module at comp3.fields[0]")
            return
        }
        let m1 = comp3.coreModulesMap[.init(m1Index.rawValue)]
        #expect(m1.id?.value == "$m1")

        guard case .coreModule(let m2Index) = comp3.fields[1].kind else {
            Issue.record("Expected core module at comp3.fields[1]")
            return
        }
        let m2 = comp3.coreModulesMap[.init(m2Index.rawValue)]
        #expect(m2.id?.value == "$m2")

        guard case .coreInstance(let M1Index) = comp3.fields[2].kind else {
            Issue.record("Expected core instance at comp3.fields[2]")
            return
        }
        let M1 = comp3.coreInstancesMap[.init(M1Index.rawValue)]
        #expect(M1.id?.value == "$M1")
        #expect(M1.arguments.count == 1)
        #expect(M1.arguments[0].importName == "c")

        guard case .canon(let canon) = comp3.fields[3].kind else {
            Issue.record("Expected canon at comp3.fields[3]")
            return
        }
        guard case .lift = canon.kind else {
            Issue.record("Expected canon lift")
            return
        }

        guard case .exportDef(let exportDef) = comp3.fields[4].kind else {
            Issue.record("Expected export at comp3.fields[4]")
            return
        }
        #expect(exportDef.exportName == "a")
        guard case .function = exportDef.descriptor else {
            Issue.record("Expected function export")
            return
        }

        #expect(comp3.coreModulesMap.count == 2)
        let moduleNames = Array(comp3.coreModulesMap.nameToIndex.keys).sorted(by: {
            comp3.coreModulesMap.nameToIndex[$0]! < comp3.coreModulesMap.nameToIndex[$1]!
        })
        #expect(moduleNames == ["$m1", "$m2"])

        #expect(comp3.coreInstancesMap.count == 1)
        let instanceNames = Array(comp3.coreInstancesMap.nameToIndex.keys)
        #expect(instanceNames == ["$M1"])
    }
}

#endif
