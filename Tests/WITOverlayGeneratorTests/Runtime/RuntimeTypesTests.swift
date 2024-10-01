import WIT
import WasmKit
import XCTest

@testable import WITOverlayGenerator

class RuntimeTypesTests: XCTestCase {
    func testNumber() throws {
        var harness = try RuntimeTestHarness(fixture: "Number")
        try harness.build(link: NumberTestWorld.link) { (instance) in
            let component = NumberTestWorld(instance: instance)

            XCTAssertEqual(try component.roundtripBool(v: true), true)
            XCTAssertEqual(try component.roundtripBool(v: false), false)

            for value in [0, 1, -1, .max, .min] as [Int8] {
                XCTAssertEqual(try component.roundtripS8(v: value), value)
            }
            for value in [0, 1, -1, .max, .min] as [Int16] {
                XCTAssertEqual(try component.roundtripS16(v: value), value)
            }
            for value in [0, 1, -1, .max, .min] as [Int32] {
                XCTAssertEqual(try component.roundtripS32(v: value), value)
            }
            for value in [0, 1, -1, .max, .min] as [Int64] {
                XCTAssertEqual(try component.roundtripS64(v: value), value)
            }
            for value in [0, 1, .max] as [UInt8] {
                XCTAssertEqual(try component.roundtripU8(v: value), value)
            }
            for value in [0, 1, .max] as [UInt16] {
                XCTAssertEqual(try component.roundtripU16(v: value), value)
            }
            for value in [0, 1, .max] as [UInt32] {
                XCTAssertEqual(try component.roundtripU32(v: value), value)
            }
            for value in [0, 1, .max] as [UInt64] {
                XCTAssertEqual(try component.roundtripU64(v: value), value)
            }

            let value1 = try component.retptrU8()
            XCTAssertEqual(value1.0, 1)
            XCTAssertEqual(value1.1, 2)

            let value2 = try component.retptrU16()
            XCTAssertEqual(value2.0, 1)
            XCTAssertEqual(value2.1, 2)

            let value3 = try component.retptrU32()
            XCTAssertEqual(value3.0, 1)
            XCTAssertEqual(value3.1, 2)

            let value4 = try component.retptrU64()
            XCTAssertEqual(value4.0, 1)
            XCTAssertEqual(value4.1, 2)

            let value5 = try component.retptrS8()
            XCTAssertEqual(value5.0, 1)
            XCTAssertEqual(value5.1, -2)

            let value6 = try component.retptrS16()
            XCTAssertEqual(value6.0, 1)
            XCTAssertEqual(value6.1, -2)

            let value7 = try component.retptrS32()
            XCTAssertEqual(value7.0, 1)
            XCTAssertEqual(value7.1, -2)

            let value8 = try component.retptrS64()
            XCTAssertEqual(value8.0, 1)
            XCTAssertEqual(value8.1, -2)
        }
    }

    func testChar() throws {
        var harness = try RuntimeTestHarness(fixture: "Char")
        try harness.build(link: CharTestWorld.link) { (instance) in
            let component = CharTestWorld(instance: instance)

            for char in "abcd🍏👨‍👩‍👦‍👦".unicodeScalars {
                XCTAssertEqual(try component.roundtrip(v: char), char)
            }
        }
    }

    func testOption() throws {
        var harness = try RuntimeTestHarness(fixture: "Option")
        try harness.build(link: OptionTestWorld.link) { (instance) in
            let component = OptionTestWorld(instance: instance)
            let value1 = try component.returnNone()
            XCTAssertEqual(value1, nil)

            let value2 = try component.returnOptionF32()
            XCTAssertEqual(value2, .some(0.5))

            let value3 = try component.returnOptionTypedef()
            XCTAssertEqual(value3, .some(42))

            let value4 = try component.returnSomeNone()
            XCTAssertEqual(value4, .some(nil))

            let value5 = try component.returnSomeSome()
            XCTAssertEqual(value5, .some(33_550_336))

            for value in [.some(1), nil] as [UInt32?] {
                let value6 = try component.roundtrip(v: value)
                XCTAssertEqual(value6, value)
            }
        }
    }

    func testRecord() throws {
        var harness = try RuntimeTestHarness(fixture: "Record")
        try harness.build(link: RecordTestWorld.link) { (instance) in
            let component = RecordTestWorld(instance: instance)
            _ = try component.returnEmpty()

            _ = try component.roundtripEmpty(v: RecordTestWorld.RecordEmpty())

            let value3 = try component.returnPadded()
            XCTAssertEqual(value3.f1, 28)
            XCTAssertEqual(value3.f2, 496)

            let value4 = try component.roundtripPadded(v: RecordTestWorld.RecordPadded(f1: 6, f2: 8128))
            XCTAssertEqual(value4.f1, 6)
            XCTAssertEqual(value4.f2, 8128)
        }
    }

    func testString() throws {
        var harness = try RuntimeTestHarness(fixture: "String")
        try harness.build(link: StringTestWorld.link) { (instance) in
            let component = StringTestWorld(instance: instance)
            XCTAssertEqual(try component.returnEmpty(), "")
            XCTAssertEqual(try component.roundtrip(v: "ok"), "ok")
            XCTAssertEqual(try component.roundtrip(v: "🍏"), "🍏")
            XCTAssertEqual(try component.roundtrip(v: "\u{0}"), "\u{0}")
            let longString = String(repeating: "a", count: 1000)
            XCTAssertEqual(try component.roundtrip(v: longString), longString)
        }
    }

    func testList() throws {
        var harness = try RuntimeTestHarness(fixture: "List")
        try harness.build(link: ListTestWorld.link) { (instance) in
            let component = ListTestWorld(instance: instance)
            XCTAssertEqual(try component.returnEmpty(), [])
            for value in [[], [1, 2, 3]] as [[UInt8]] {
                XCTAssertEqual(try component.roundtrip(v: value), value)
            }
            let value1 = ["foo", "bar"]
            XCTAssertEqual(try component.roundtripNonPod(v: value1), value1)
            let value2 = [["apple", "pineapple"], ["grape", "grapefruit"], [""]]
            XCTAssertEqual(try component.roundtripListList(v: value2), value2)
        }
    }

    func testVariant() throws {
        var harness = try RuntimeTestHarness(fixture: "Variant")
        try harness.build(link: VariantTestWorld.link) { (instance) in
            let component = VariantTestWorld(instance: instance)
            XCTAssertEqual(try component.returnSingle(), .a(33_550_336))

            let value1 = try component.returnLarge()
            guard case let .c256(value1) = value1 else {
                XCTFail("unexpected variant case \(value1)")
                return
            }
            XCTAssertEqual(value1, 42)

            let value2 = try component.roundtripLarge(v: .c000)
            guard case .c000 = value2 else {
                XCTFail("unexpected variant case \(value2)")
                return
            }

            let value3 = try component.roundtripLarge(v: .c256(24))
            guard case let .c256(value3) = value3 else {
                XCTFail("unexpected variant case \(value3)")
                return
            }
            XCTAssertEqual(value3, 24)
        }
    }

    func testResult() throws {
        var harness = try RuntimeTestHarness(fixture: "Result")
        try harness.build(link: ResultTestWorld.link) { (instance) in
            let component = ResultTestWorld(instance: instance)

            let value4 = try component.roundtripResult(v: .success(()))
            guard case .success = value4 else {
                XCTFail("unexpected variant case \(value4)")
                return
            }

            let value5 = try component.roundtripResult(v: .failure(.init(())))
            guard case .failure = value5 else {
                XCTFail("unexpected variant case \(value5)")
                return
            }

            let value6 = try component.roundtripResultOk(v: .success(8128))
            guard case .success(let value5) = value6 else {
                XCTFail("unexpected variant case \(value6)")
                return
            }
            XCTAssertEqual(value5, 8128)

            let value7 = try component.roundtripResultOkError(v: .success(496))
            XCTAssertEqual(value7, .success(496))

            let value8 = try component.roundtripResultOkError(v: .failure(.init("bad")))
            XCTAssertEqual(value8, .failure(.init("bad")))
        }
    }

    func testEnum() throws {
        var harness = try RuntimeTestHarness(fixture: "Enum")
        try harness.build(link: EnumTestWorld.link) { (instance) in
            let component = EnumTestWorld(instance: instance)

            let value1 = try component.roundtripSingle(v: .a)
            XCTAssertEqual(value1, .a)

            for c in [EnumTestWorld.Large.c000, .c127, .c128, .c255, .c256] {
                let value2 = try component.roundtripLarge(v: c)
                XCTAssertEqual(value2, c)
            }

            let value3 = try component.returnByPointer()
            XCTAssertEqual(value3.0, .a)
            XCTAssertEqual(value3.1, .b)
        }
    }

    func testFlags() throws {
        var harness = try RuntimeTestHarness(fixture: "Flags")
        try harness.build(link: FlagsTestWorld.link) { (instance) in
            let component = FlagsTestWorld(instance: instance)

            XCTAssertEqual(try component.roundtripSingle(v: []), [])

            let value1: FlagsTestWorld.Single = .a
            XCTAssertEqual(try component.roundtripSingle(v: value1), value1)

            let value2: FlagsTestWorld.ManyU8 = [.f00, .f01, .f07]
            XCTAssertEqual(try component.roundtripManyU8(v: value2), value2)

            let value3: FlagsTestWorld.ManyU16 = [.f00, .f01, .f07, .f15]
            XCTAssertEqual(try component.roundtripManyU16(v: value3), value3)

            let value4: FlagsTestWorld.ManyU32 = [.f00, .f01, .f07, .f15, .f23, .f31]
            XCTAssertEqual(try component.roundtripManyU32(v: value4), value4)

            let value5: FlagsTestWorld.ManyU64 = [.f00, .f01, .f07, .f15, .f23, .f31, .f39, .f47, .f55, .f63]
            XCTAssertEqual(try component.roundtripManyU64(v: value5), value5)
        }
    }

    func testTuple() throws {
        var harness = try RuntimeTestHarness(fixture: "Tuple")
        try harness.build(link: TupleTestWorld.link) { (instance) in
            let component = TupleTestWorld(instance: instance)
            let value1 = try component.roundtrip(v: (true, 42))
            XCTAssertEqual(value1.0, true)
            XCTAssertEqual(value1.1, 42)
        }
    }

    func testInterface() throws {
        var harness = try RuntimeTestHarness(fixture: "Interface")
        try harness.build(link: InterfaceTestWorld.link) { (instance) in
            let component = InterfaceTestWorld(instance: instance)
            let value1 = try component.roundtripT1(v: 42)
            XCTAssertEqual(value1, 42)

            let iface = InterfaceTestWorld.IfaceFuncs(instance: instance)
            let value2 = try iface.roundtripU8(v: 43)
            XCTAssertEqual(value2, 43)
        }
    }

    func testNaming() throws {
        // Ensure compilation succeed for both host and guest
        var harness = try RuntimeTestHarness(fixture: "Naming")
        try harness.build(link: NamingTestWorld.link, run: { _ in })
    }
}

extension VariantTestWorld.Single: Equatable {
    static func == (lhs: VariantTestWorld.Single, rhs: VariantTestWorld.Single) -> Bool {
        switch (lhs, rhs) {
        case let (.a(lhs), .a(rhs)): return lhs == rhs
        }
    }
}
