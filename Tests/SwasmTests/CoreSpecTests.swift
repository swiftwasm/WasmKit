@testable import Swasm
import XCTest

internal final class CoreSpecTests: XCTestCase {
    static var allTests: [() -> Void] = []

    func assertEqual(_ input: String, _ expected: Module, file: StaticString = #file, line: UInt = #line) {

        do {
            let module = try Module(wast: input)
            XCTAssertEqual(module, expected, file: file, line: line)
        } catch let WASTParseError.syntaxError(line: lineOffset, column: _, message: message) {
            XCTFail(message, line: line + UInt(lineOffset) + 1)
        } catch let error {
            XCTFail("\(error)", file: file, line: line)
        }
    }

    /// https://github.com/WebAssembly/spec/blob/master/test/core/comments.wast
    func testComments() {
        assertEqual(
            """
            ;;comment

            ;;;;;;;;;;;

            ;;comment

            ( ;;comment
            module;;comment
            );;comment

            ;;)
            ;;;)
            ;; ;)
            ;; (;

            (;;)

            (;comment;)

            (;;comment;)

            (;;;comment;)

            (;;;;;;;;;;;;;;)

            (;(((((((((( ;)

            (;)))))))))));)

            (;comment";)

            (;comment"";)

            (;comment\"\"\";)

            (;Heiße Würstchen;)

            (;comment
            comment;)

            (;comment;)

            (;comment;)((;comment;)
            (;comment;)module(;comment;)
            (;comment;))(;comment;)

            (;comment(;nested;)comment;)

            (;comment
            (;nested
            ;)comment
            ;)
            """,
            Module()
        )
    }

    /// https://github.com/WebAssembly/spec/blob/master/test/core/const.wast
    func testConst() {
//        assertEqual("(module (func (i32.const 0xffffffff) drop))", Module())
    }

    /// https://github.com/WebAssembly/spec/blob/master/test/core/func.wast
    func testFunc() {
        assertEqual(
            """
            (module
                (func)
                (func (export "f"))
                (func $f)
                (func $h (export "g"))
                ;; (func (local))
                ;; (func (local) (local))
                (func (local i32))
                (func (local $x i32))
                ;; (func (local i32 f64 i64))
                (func (local i32) (local f64))
                ;; (func (local i32 f32) (local $x i64) (local) (local i32 f64))

                (func (param))
                (func (param) (param))
                (func (param i32))
                (func (param $x i32))
                (func (param i32 f64 i64))
                (func (param i32) (param f64))
                (func (param i32 f32) (param $x i64) (param) (param i32 f64))

                (func (result i32) (unreachable))

                (type $sig-1 (func))
                (type $sig-2 (func (result i32)))
                (type $sig-3 (func (param $x i32)))
                (type $sig-4 (func (param i32 f64 i32) (result i32)))
            )
            """,
            Module(
                types: [
                    FunctionType(parameters: [], results: []),
                    FunctionType(parameters: [], results: [Int32.self]),
                    FunctionType(parameters: [Int32.self], results: []),
                    FunctionType(parameters: [Int32.self, Float64.self, Int32.self], results: [Int32.self]),
                ],
                functions: [
                    Function(type: 0),
                    Function(type: 0),
                    Function(type: 0),
                    Function(type: 0),

                    Function(type: 0),
                    Function(type: 0),

                    Function(type: 0),

                    Function(type: 0),
                    Function(type: 0),
                    Function(type: 0),
                    Function(type: 0),
                    Function(type: 0),
                    Function(type: 0),
                    Function(type: 0),

                    Function(type: 0),
                ]
        ))
    }

    /// https://github.com/WebAssembly/spec/blob/master/test/core/type.wast
    func testType() {
        assertEqual(
            """
            (module
                (type (func))
                (type $t (func))

                (type (func (param i32)))
                (type (func (param $x i32)))
                (type (func (result i32)))
                (type (func (param i32) (result i32)))
                (type (func (param $x i32) (result i32)))

                (type (func (param f32 f64)))
                ;; (type (func (result i64 f32)))
                ;; (type (func (param i32 i64) (result f32 f64)))

                (type (func (param f32) (param f64)))
                (type (func (param $x f32) (param f64)))
                (type (func (param f32) (param $y f64)))
                (type (func (param $x f32) (param $y f64)))
                ;; (type (func (result i64) (result f32)))
                ;; (type (func (param i32) (param i64) (result f32) (result f64)))
                ;; (type (func (param $x i32) (param $y i64) (result f32) (result f64)))

                (type (func (param f32 f64) (param $x i32) (param f64 i32 i32)))
                ;; (type (func (result i64 i64 f32) (result f32 i32)))
                ;; (type
                ;;   (func (param i32 i32) (param i64 i32) (result f32 f64) (result f64 i32))
                ;; )

                (type (func (param) (param $x f32) (param) (param) (param f64 i32) (param)))
                ;; (type
                ;;   (func (result) (result) (result i64 i64) (result) (result f32) (result))
                ;; )
                ;; (type
                ;;   (func
                ;;     (param i32 i32) (param i64 i32) (param) (param $x i32) (param)
                ;;     (result) (result f32 f64) (result f64 i32) (result)
                ;;   )
                ;; )
            )
            """,

            Module(types: [
                FunctionType(parameters: [], results: []),
                FunctionType(parameters: [], results: []),

                FunctionType(parameters: [Int32.self], results: []),
                FunctionType(parameters: [Int32.self], results: []),
                FunctionType(parameters: [], results: [Int32.self]),
                FunctionType(parameters: [Int32.self], results: [Int32.self]),
                FunctionType(parameters: [Int32.self], results: [Int32.self]),

                FunctionType(parameters: [Float32.self, Float64.self], results: []),

                FunctionType(parameters: [Float32.self, Float64.self], results: []),
                FunctionType(parameters: [Float32.self, Float64.self], results: []),
                FunctionType(parameters: [Float32.self, Float64.self], results: []),
                FunctionType(parameters: [Float32.self, Float64.self], results: []),

                FunctionType(parameters: [Float32.self, Float64.self, Int32.self, Float64.self, Int32.self, Int32.self],
                             results: []),

                FunctionType(parameters: [Float32.self, Float64.self, Int32.self], results: []),
        ]))
    }
}
