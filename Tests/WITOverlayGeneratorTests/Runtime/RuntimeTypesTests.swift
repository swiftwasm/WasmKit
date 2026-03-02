import Testing
import WIT
import WasmKit

@testable import WITOverlayGenerator

@Suite(TestEnvironmentTraits.runtimeAvailability)
struct RuntimeTypesTests {
    @Test func number() throws {
        var harness = try RuntimeTestHarness(fixture: "Number")
        try harness.build(link: NumberTestWorld.link) { (instance) in
            let component = NumberTestWorld(instance: instance)

            let trueResult = try component.roundtripBool(v: true)
            #expect(trueResult == true)
            let falseResult = try component.roundtripBool(v: false)
            #expect(falseResult == false)

            for value in [0, 1, -1, .max, .min] as [Int8] {
                let roundtripped = try component.roundtripS8(v: value)
                #expect(roundtripped == value)
            }
            for value in [0, 1, -1, .max, .min] as [Int16] {
                let roundtripped = try component.roundtripS16(v: value)
                #expect(roundtripped == value)
            }
            for value in [0, 1, -1, .max, .min] as [Int32] {
                let roundtripped = try component.roundtripS32(v: value)
                #expect(roundtripped == value)
            }
            for value in [0, 1, -1, .max, .min] as [Int64] {
                let roundtripped = try component.roundtripS64(v: value)
                #expect(roundtripped == value)
            }
            for value in [0, 1, .max] as [UInt8] {
                let roundtripped = try component.roundtripU8(v: value)
                #expect(roundtripped == value)
            }
            for value in [0, 1, .max] as [UInt16] {
                let roundtripped = try component.roundtripU16(v: value)
                #expect(roundtripped == value)
            }
            for value in [0, 1, .max] as [UInt32] {
                let roundtripped = try component.roundtripU32(v: value)
                #expect(roundtripped == value)
            }
            for value in [0, 1, .max] as [UInt64] {
                let roundtripped = try component.roundtripU64(v: value)
                #expect(roundtripped == value)
            }

            let value1 = try component.retptrU8()
            #expect(value1.0 == 1)
            #expect(value1.1 == 2)

            let value2 = try component.retptrU16()
            #expect(value2.0 == 1)
            #expect(value2.1 == 2)

            let value3 = try component.retptrU32()
            #expect(value3.0 == 1)
            #expect(value3.1 == 2)

            let value4 = try component.retptrU64()
            #expect(value4.0 == 1)
            #expect(value4.1 == 2)

            let value5 = try component.retptrS8()
            #expect(value5.0 == 1)
            #expect(value5.1 == -2)

            let value6 = try component.retptrS16()
            #expect(value6.0 == 1)
            #expect(value6.1 == -2)

            let value7 = try component.retptrS32()
            #expect(value7.0 == 1)
            #expect(value7.1 == -2)

            let value8 = try component.retptrS64()
            #expect(value8.0 == 1)
            #expect(value8.1 == -2)
        }
    }

    @Test func char() throws {
        var harness = try RuntimeTestHarness(fixture: "Char")
        try harness.build(link: CharTestWorld.link) { (instance) in
            let component = CharTestWorld(instance: instance)

            for char in "abcd🍏👨‍👩‍👦‍👦".unicodeScalars {
                let echoed = try component.roundtrip(v: char)
                #expect(echoed == char)
            }
        }
    }

    @Test func option() throws {
        var harness = try RuntimeTestHarness(fixture: "Option")
        try harness.build(link: OptionTestWorld.link) { (instance) in
            let component = OptionTestWorld(instance: instance)
            let value1 = try component.returnNone()
            #expect(value1 == nil)

            let value2 = try component.returnOptionF32()
            #expect(value2 == .some(0.5))

            let value3 = try component.returnOptionTypedef()
            #expect(value3 == .some(42))

            let value4 = try component.returnSomeNone()
            #expect(value4 == .some(nil))

            let value5 = try component.returnSomeSome()
            #expect(value5 == .some(33_550_336))

            for value in [.some(1), nil] as [UInt32?] {
                let value6 = try component.roundtrip(v: value)
                #expect(value6 == value)
            }
        }
    }

    @Test func record() throws {
        var harness = try RuntimeTestHarness(fixture: "Record")
        try harness.build(link: RecordTestWorld.link) { (instance) in
            let component = RecordTestWorld(instance: instance)
            _ = try component.returnEmpty()

            _ = try component.roundtripEmpty(v: RecordTestWorld.RecordEmpty())

            let value3 = try component.returnPadded()
            #expect(value3.f1 == 28)
            #expect(value3.f2 == 496)

            let value4 = try component.roundtripPadded(v: RecordTestWorld.RecordPadded(f1: 6, f2: 8128))
            #expect(value4.f1 == 6)
            #expect(value4.f2 == 8128)
        }
    }

    @Test func string() throws {
        var harness = try RuntimeTestHarness(fixture: "String")
        try harness.build(link: StringTestWorld.link) { (instance) in
            let component = StringTestWorld(instance: instance)
            let empty = try component.returnEmpty()
            #expect(empty == "")
            let ok = try component.roundtrip(v: "ok")
            #expect(ok == "ok")
            let apple = try component.roundtrip(v: "🍏")
            #expect(apple == "🍏")
            let nul = try component.roundtrip(v: "\u{0}")
            #expect(nul == "\u{0}")
            let longString = String(repeating: "a", count: 1000)
            let echoedLong = try component.roundtrip(v: longString)
            #expect(echoedLong == longString)
        }
    }

    @Test func list() throws {
        var harness = try RuntimeTestHarness(fixture: "List")
        try harness.build(link: ListTestWorld.link) { (instance) in
            let component = ListTestWorld(instance: instance)
            let empty = try component.returnEmpty()
            #expect(empty == [])
            for value in [[], [1, 2, 3]] as [[UInt8]] {
                let echoed = try component.roundtrip(v: value)
                #expect(echoed == value)
            }
            let value1 = ["foo", "bar"]
            let nonPod = try component.roundtripNonPod(v: value1)
            #expect(nonPod == value1)
            let value2 = [["apple", "pineapple"], ["grape", "grapefruit"], [""]]
            let listList = try component.roundtripListList(v: value2)
            #expect(listList == value2)
        }
    }

    @Test func variant() throws {
        var harness = try RuntimeTestHarness(fixture: "Variant")
        try harness.build(link: VariantTestWorld.link) { (instance) in
            let component = VariantTestWorld(instance: instance)
            let single = try component.returnSingle()
            #expect(single == .a(33_550_336))

            let value1 = try component.returnLarge()
            guard case .c256(let value1) = value1 else {
                Issue.record("unexpected variant case \(value1)")
                return
            }
            #expect(value1 == 42)

            let value2 = try component.roundtripLarge(v: .c000)
            guard case .c000 = value2 else {
                Issue.record("unexpected variant case \(value2)")
                return
            }

            let value3 = try component.roundtripLarge(v: .c256(24))
            guard case .c256(let value3) = value3 else {
                Issue.record("unexpected variant case \(value3)")
                return
            }
            #expect(value3 == 24)
        }
    }

    @Test func result() throws {
        var harness = try RuntimeTestHarness(fixture: "Result")
        try harness.build(link: ResultTestWorld.link) { (instance) in
            let component = ResultTestWorld(instance: instance)

            let value4 = try component.roundtripResult(v: .success(()))
            guard case .success = value4 else {
                Issue.record("unexpected variant case \(value4)")
                return
            }

            let value5 = try component.roundtripResult(v: .failure(.init(())))
            guard case .failure = value5 else {
                Issue.record("unexpected variant case \(value5)")
                return
            }

            let value6 = try component.roundtripResultOk(v: .success(8128))
            guard case .success(let value5) = value6 else {
                Issue.record("unexpected variant case \(value6)")
                return
            }
            #expect(value5 == 8128)

            let value7 = try component.roundtripResultOkError(v: .success(496))
            #expect(value7 == .success(496))

            let value8 = try component.roundtripResultOkError(v: .failure(.init("bad")))
            #expect(value8 == .failure(.init("bad")))
        }
    }

    @Test func `enum`() throws {
        var harness = try RuntimeTestHarness(fixture: "Enum")
        try harness.build(link: EnumTestWorld.link) { (instance) in
            let component = EnumTestWorld(instance: instance)

            let value1 = try component.roundtripSingle(v: .a)
            #expect(value1 == .a)

            for c in [EnumTestWorld.Large.c000, .c127, .c128, .c255, .c256] {
                let value2 = try component.roundtripLarge(v: c)
                #expect(value2 == c)
            }

            let value3 = try component.returnByPointer()
            #expect(value3.0 == .a)
            #expect(value3.1 == .b)
        }
    }

    @Test func flags() throws {
        var harness = try RuntimeTestHarness(fixture: "Flags")
        try harness.build(link: FlagsTestWorld.link) { (instance) in
            let component = FlagsTestWorld(instance: instance)

            let emptyFlags = try component.roundtripSingle(v: [])
            #expect(emptyFlags == [])

            let value1: FlagsTestWorld.Single = .a
            let singleEcho = try component.roundtripSingle(v: value1)
            #expect(singleEcho == value1)

            let value2: FlagsTestWorld.ManyU8 = [.f00, .f01, .f07]
            let manyU8 = try component.roundtripManyU8(v: value2)
            #expect(manyU8 == value2)

            let value3: FlagsTestWorld.ManyU16 = [.f00, .f01, .f07, .f15]
            let manyU16 = try component.roundtripManyU16(v: value3)
            #expect(manyU16 == value3)

            let value4: FlagsTestWorld.ManyU32 = [.f00, .f01, .f07, .f15, .f23, .f31]
            let manyU32 = try component.roundtripManyU32(v: value4)
            #expect(manyU32 == value4)

            let value5: FlagsTestWorld.ManyU64 = [.f00, .f01, .f07, .f15, .f23, .f31, .f39, .f47, .f55, .f63]
            let manyU64 = try component.roundtripManyU64(v: value5)
            #expect(manyU64 == value5)
        }
    }

    @Test func tuple() throws {
        var harness = try RuntimeTestHarness(fixture: "Tuple")
        try harness.build(link: TupleTestWorld.link) { (instance) in
            let component = TupleTestWorld(instance: instance)
            let value1 = try component.roundtrip(v: (true, 42))
            #expect(value1.0 == true)
            #expect(value1.1 == 42)
        }
    }

    @Test func interface() throws {
        var harness = try RuntimeTestHarness(fixture: "Interface")
        try harness.build(link: InterfaceTestWorld.link) { (instance) in
            let component = InterfaceTestWorld(instance: instance)
            let value1 = try component.roundtripT1(v: 42)
            #expect(value1 == 42)

            let iface = InterfaceTestWorld.IfaceFuncs(instance: instance)
            let value2 = try iface.roundtripU8(v: 43)
            #expect(value2 == 43)
        }
    }

    @Test func naming() throws {
        // Ensure compilation succeed for both host and guest
        var harness = try RuntimeTestHarness(fixture: "Naming")
        try harness.build(link: NamingTestWorld.link, run: { _ in })
    }
}

extension VariantTestWorld.Single: Equatable {
    static func == (lhs: VariantTestWorld.Single, rhs: VariantTestWorld.Single) -> Bool {
        switch (lhs, rhs) {
        case (.a(let lhs), .a(let rhs)): return lhs == rhs
        }
    }
}
