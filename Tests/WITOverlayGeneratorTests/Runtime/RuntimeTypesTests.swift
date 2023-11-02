import XCTest
import WasmKit
import WIT
@testable import WITOverlayGenerator

class RuntimeTypesTests: XCTestCase {
    func testNumber() throws {
        var harness = try RuntimeTestHarness(fixture: "Number")
        let (runtime, instance) = try harness.build(link: NumberTestWorld.link(_:))
        let component = NumberTestWorld(moduleInstance: instance)

        XCTAssertEqual(try component.roundtripBool(runtime: runtime, v: true), true)
        XCTAssertEqual(try component.roundtripBool(runtime: runtime, v: false), false)

        for value in [0, 1, -1, .max, .min] as [Int8] {
            XCTAssertEqual(try component.roundtripS8(runtime: runtime, v: value), value)
        }
        for value in [0, 1, -1, .max, .min] as [Int16] {
            XCTAssertEqual(try component.roundtripS16(runtime: runtime, v: value), value)
        }
        for value in [0, 1, -1, .max, .min] as [Int32] {
            XCTAssertEqual(try component.roundtripS32(runtime: runtime, v: value), value)
        }
        for value in [0, 1, -1, .max, .min] as [Int64] {
            XCTAssertEqual(try component.roundtripS64(runtime: runtime, v: value), value)
        }
        for value in [0, 1, .max] as [UInt8] {
            XCTAssertEqual(try component.roundtripU8(runtime: runtime, v: value), value)
        }
        for value in [0, 1, .max] as [UInt16] {
            XCTAssertEqual(try component.roundtripU16(runtime: runtime, v: value), value)
        }
        for value in [0, 1, .max] as [UInt32] {
            XCTAssertEqual(try component.roundtripU32(runtime: runtime, v: value), value)
        }
        for value in [0, 1, .max] as [UInt64] {
            XCTAssertEqual(try component.roundtripU64(runtime: runtime, v: value), value)
        }

        let value1 = try component.retptrU8(runtime: runtime)
        XCTAssertEqual(value1.0, 1)
        XCTAssertEqual(value1.1, 2)

        let value2 = try component.retptrU16(runtime: runtime)
        XCTAssertEqual(value2.0, 1)
        XCTAssertEqual(value2.1, 2)

        let value3 = try component.retptrU32(runtime: runtime)
        XCTAssertEqual(value3.0, 1)
        XCTAssertEqual(value3.1, 2)

        let value4 = try component.retptrU64(runtime: runtime)
        XCTAssertEqual(value4.0, 1)
        XCTAssertEqual(value4.1, 2)

        let value5 = try component.retptrS8(runtime: runtime)
        XCTAssertEqual(value5.0, 1)
        XCTAssertEqual(value5.1, -2)

        let value6 = try component.retptrS16(runtime: runtime)
        XCTAssertEqual(value6.0, 1)
        XCTAssertEqual(value6.1, -2)

        let value7 = try component.retptrS32(runtime: runtime)
        XCTAssertEqual(value7.0, 1)
        XCTAssertEqual(value7.1, -2)

        let value8 = try component.retptrS64(runtime: runtime)
        XCTAssertEqual(value8.0, 1)
        XCTAssertEqual(value8.1, -2)
    }

    func testChar() throws {
        var harness = try RuntimeTestHarness(fixture: "Char")
        let (runtime, instance) = try harness.build(link: CharTestWorld.link(_:))
        let component = CharTestWorld(moduleInstance: instance)

        for char in "abcd🍏👨‍👩‍👦‍👦".unicodeScalars {
            XCTAssertEqual(try component.roundtrip(runtime: runtime, v: char), char)
        }
    }

    func testOption() throws {
        var harness = try RuntimeTestHarness(fixture: "Option")
        let (runtime, instance) = try harness.build(link: OptionTestWorld.link(_:))
        let component = OptionTestWorld(moduleInstance: instance)
        let value1 = try component.returnNone(runtime: runtime)
        XCTAssertEqual(value1, nil)

        let value2 = try component.returnOptionF32(runtime: runtime)
        XCTAssertEqual(value2, .some(0.5))

        let value3 = try component.returnOptionTypedef(runtime: runtime)
        XCTAssertEqual(value3, .some(42))

        let value4 = try component.returnSomeNone(runtime: runtime)
        XCTAssertEqual(value4, .some(nil))

        let value5 = try component.returnSomeSome(runtime: runtime)
        XCTAssertEqual(value5, .some(33550336))

        for value in [.some(1), nil] as [UInt32?] {
            let value6 = try component.roundtrip(runtime: runtime, v: value)
            XCTAssertEqual(value6, value)
        }
    }

    func testRecord() throws {
        var harness = try RuntimeTestHarness(fixture: "Record")
        let (runtime, instance) = try harness.build(link: RecordTestWorld.link(_:))
        let component = RecordTestWorld(moduleInstance: instance)
        _ = try component.returnEmpty(runtime: runtime)

        _ = try component.roundtripEmpty(runtime: runtime, v: RecordTestWorld.RecordEmpty())

        let value3 = try component.returnPadded(runtime: runtime)
        XCTAssertEqual(value3.f1, 28)
        XCTAssertEqual(value3.f2, 496)

        let value4 = try component.roundtripPadded(runtime: runtime, v: RecordTestWorld.RecordPadded(f1: 6, f2: 8128))
        XCTAssertEqual(value4.f1, 6)
        XCTAssertEqual(value4.f2, 8128)
    }

    func testString() throws {
        var harness = try RuntimeTestHarness(fixture: "String")
        let (runtime, instance) = try harness.build(link: StringTestWorld.link(_:))
        let component = StringTestWorld(moduleInstance: instance)
        XCTAssertEqual(try component.returnEmpty(runtime: runtime), "")
        XCTAssertEqual(try component.roundtrip(runtime: runtime, v: "ok"), "ok")
        XCTAssertEqual(try component.roundtrip(runtime: runtime, v: "🍏"), "🍏")
        XCTAssertEqual(try component.roundtrip(runtime: runtime, v: "\u{0}"), "\u{0}")
        let longString = String(repeating: "a", count: 1000)
        XCTAssertEqual(try component.roundtrip(runtime: runtime, v: longString), longString)
    }

    func testList() throws {
        var harness = try RuntimeTestHarness(fixture: "List")
        let (runtime, instance) = try harness.build(link: ListTestWorld.link(_:))
        let component = ListTestWorld(moduleInstance: instance)
        XCTAssertEqual(try component.returnEmpty(runtime: runtime), [])
        for value in [[], [1, 2, 3]] as [[UInt8]] {
            XCTAssertEqual(try component.roundtrip(runtime: runtime, v: value), value)
        }
        let value1 = ["foo", "bar"]
        XCTAssertEqual(try component.roundtripNonPod(runtime: runtime, v: value1), value1)
        let value2 = [["apple", "pineapple"], ["grape", "grapefruit"], [""]]
        XCTAssertEqual(try component.roundtripListList(runtime: runtime, v: value2), value2)
    }

    func testVariant() throws {
        var harness = try RuntimeTestHarness(fixture: "Variant")
        let (runtime, instance) = try harness.build(link: VariantTestWorld.link(_:))
        let component = VariantTestWorld(moduleInstance: instance)
        XCTAssertEqual(try component.returnSingle(runtime: runtime), .a(33550336))

        let value1 = try component.returnLarge(runtime: runtime)
        guard case let .c256(value1) = value1 else {
            XCTFail("unexpected variant case \(value1)")
            return
        }
        XCTAssertEqual(value1, 42)

        let value2 = try component.roundtripLarge(runtime: runtime, v: .c000)
        guard case .c000 = value2 else {
            XCTFail("unexpected variant case \(value2)")
            return
        }

        let value3 = try component.roundtripLarge(runtime: runtime, v: .c256(24))
        guard case let .c256(value3) = value3 else {
            XCTFail("unexpected variant case \(value3)")
            return
        }
        XCTAssertEqual(value3, 24)
    }

    func testResult() throws {
        var harness = try RuntimeTestHarness(fixture: "Result")
        let (runtime, instance) = try harness.build(link: ResultTestWorld.link(_:))
        let component = ResultTestWorld(moduleInstance: instance)

        let value4 = try component.roundtripResult(runtime: runtime, v: .success(()))
        guard case .success = value4 else {
            XCTFail("unexpected variant case \(value4)")
            return
        }

        let value5 = try component.roundtripResult(runtime: runtime, v: .failure(.init(())))
        guard case .failure = value5 else {
            XCTFail("unexpected variant case \(value5)")
            return
        }

        let value6 = try component.roundtripResultOk(runtime: runtime, v: .success(8128))
        guard case .success(let value5) = value6 else {
            XCTFail("unexpected variant case \(value6)")
            return
        }
        XCTAssertEqual(value5, 8128)

        let value7 = try component.roundtripResultOkError(runtime: runtime, v: .success(496))
        XCTAssertEqual(value7, .success(496))

        let value8 = try component.roundtripResultOkError(runtime: runtime, v: .failure(.init("bad")))
        XCTAssertEqual(value8, .failure(.init("bad")))
    }

    func testEnum() throws {
        var harness = try RuntimeTestHarness(fixture: "Enum")
        let (runtime, instance) = try harness.build(link: EnumTestWorld.link(_:))
        let component = EnumTestWorld(moduleInstance: instance)

        let value1 = try component.roundtripSingle(runtime: runtime, v: .a)
        XCTAssertEqual(value1, .a)

        for c in [EnumTestWorld.Large.c000, .c127, .c128, .c255, .c256] {
            let value2 = try component.roundtripLarge(runtime: runtime, v: c)
            XCTAssertEqual(value2, c)
        }

        let value3 = try component.returnByPointer(runtime: runtime)
        XCTAssertEqual(value3.0, .a)
        XCTAssertEqual(value3.1, .b)
    }

    func testFlags() throws {
        var harness = try RuntimeTestHarness(fixture: "Flags")
        let (runtime, instance) = try harness.build(link: FlagsTestWorld.link(_:))
        let component = FlagsTestWorld(moduleInstance: instance)

        XCTAssertEqual(try component.roundtripSingle(runtime: runtime, v: []), [])

        let value1: FlagsTestWorld.Single = .a
        XCTAssertEqual(try component.roundtripSingle(runtime: runtime, v: value1), value1)

        let value2: FlagsTestWorld.ManyU8 = [.f00, .f01, .f07]
        XCTAssertEqual(try component.roundtripManyU8(runtime: runtime, v: value2), value2)

        let value3: FlagsTestWorld.ManyU16 = [.f00, .f01, .f07, .f15]
        XCTAssertEqual(try component.roundtripManyU16(runtime: runtime, v: value3), value3)

        let value4: FlagsTestWorld.ManyU32 = [.f00, .f01, .f07, .f15, .f23, .f31]
        XCTAssertEqual(try component.roundtripManyU32(runtime: runtime, v: value4), value4)

        let value5: FlagsTestWorld.ManyU64 = [.f00, .f01, .f07, .f15, .f23, .f31, .f39, .f47, .f55, .f63]
        XCTAssertEqual(try component.roundtripManyU64(runtime: runtime, v: value5), value5)
    }

    func testTuple() throws {
        var harness = try RuntimeTestHarness(fixture: "Tuple")
        let (runtime, instance) = try harness.build(link: TupleTestWorld.link(_:))
        let component = TupleTestWorld(moduleInstance: instance)
        let value1 = try component.roundtrip(runtime: runtime, v: (true, 42))
        XCTAssertEqual(value1.0, true)
        XCTAssertEqual(value1.1, 42)
    }

    func testInterface() throws {
        var harness = try RuntimeTestHarness(fixture: "Interface")
        let (runtime, instance) = try harness.build(link: InterfaceTestWorld.link(_:))
        let component = InterfaceTestWorld(moduleInstance: instance)
        let value1 = try component.roundtripT1(runtime: runtime, v: 42)
        XCTAssertEqual(value1, 42)

        let iface = InterfaceTestWorld.IfaceFuncs(moduleInstance: instance)
        let value2 = try iface.roundtripU8(runtime: runtime, v: 43)
        XCTAssertEqual(value2, 43)
    }

    func testNaming() throws {
        // Ensure compilation succeed for both host and guest
        var harness = try RuntimeTestHarness(fixture: "Naming")
        XCTAssertNoThrow(try harness.build(link: NamingTestWorld.link(_:)))
    }
}

extension VariantTestWorld.Single: Equatable {
    static func == (lhs: VariantTestWorld.Single, rhs: VariantTestWorld.Single) -> Bool {
        switch (lhs, rhs) {
        case let (.a(lhs), .a(rhs)): return lhs == rhs
        }
    }
}
