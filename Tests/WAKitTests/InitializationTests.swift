@testable import WAKit
import XCTest

final class InitializationTests: XCTestCase {
    func testModuleInitialization() throws {
        let module = Module(
            types: [
                FunctionType(
                    parameters: [.i32],
                    results: [.i32]
                ),
            ],
            functions: [
                Function(
                    type: 0,
                    locals: [.i32],
                    body: Expression(instructions: [
                        NumericInstruction.const(.i32(0)), NumericInstruction.const(.i32(0)),
                        MemoryInstruction.load(.i32, (2, 4)), NumericInstruction.const(.i32(16)),
                        NumericInstruction.sub(.i32), VariableInstruction.teeLocal(1),
                        MemoryInstruction.store(.i32, (2, 4)), VariableInstruction.getLocal(1),
                        VariableInstruction.getLocal(0), MemoryInstruction.store(.i32, (2, 8)),
                        ControlInstruction.block([], Expression(instructions: [
                            ControlInstruction.block([], Expression(instructions: [
                                VariableInstruction.getLocal(0), NumericInstruction.const(.i32(1)),
                                NumericInstruction.gtS(.i32), ControlInstruction.brIf(0),
                                VariableInstruction.getLocal(1), NumericInstruction.const(.i32(1)),
                                MemoryInstruction.store(.i32, (2, 12)), ControlInstruction.br(1),
                                PseudoInstruction.end,
                            ])),
                            VariableInstruction.getLocal(1), VariableInstruction.getLocal(1),
                            MemoryInstruction.load(.i32, (2, 8)), NumericInstruction.const(.i32(-1)),
                            NumericInstruction.add(.i32), ControlInstruction.call(0),
                            VariableInstruction.getLocal(1), MemoryInstruction.load(.i32, (2, 8)),
                            NumericInstruction.const(.i32(-2)), NumericInstruction.add(.i32),
                            ControlInstruction.call(0), NumericInstruction.add(.i32),
                            MemoryInstruction.store(.i32, (2, 12)), PseudoInstruction.end,
                        ])),
                        VariableInstruction.getLocal(1), MemoryInstruction.load(.i32, (2, 12)),
                        VariableInstruction.setLocal(0), NumericInstruction.const(.i32(0)),
                        VariableInstruction.getLocal(1), NumericInstruction.const(.i32(16)),
                        NumericInstruction.add(.i32), MemoryInstruction.store(.i32, (2, 4)),
                        VariableInstruction.getLocal(0), PseudoInstruction.end,
                ])),
                Function(
                    type: 0,
                    locals: [.i32, .i32, .i32],
                    body: Expression(instructions: [
                        NumericInstruction.const(.i32(0)), MemoryInstruction.load(.i32, (2, 4)),
                        NumericInstruction.const(.i32(32)), NumericInstruction.sub(.i32),
                        VariableInstruction.teeLocal(2), VariableInstruction.teeLocal(3),
                        VariableInstruction.getLocal(0), MemoryInstruction.store(.i32, (2, 24)),
                        ControlInstruction.block([], Expression(instructions: [
                            VariableInstruction.getLocal(0), NumericInstruction.const(.i32(1)),
                            NumericInstruction.gtS(.i32), ControlInstruction.brIf(0),
                            VariableInstruction.getLocal(3), NumericInstruction.const(.i32(1)),
                            MemoryInstruction.store(.i32, (2, 28)), VariableInstruction.getLocal(3),
                            MemoryInstruction.load(.i32, (2, 28)), ControlInstruction.return,
                            PseudoInstruction.end,
                        ])),
                        VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, (2, 24)),
                        VariableInstruction.setLocal(0), VariableInstruction.getLocal(3),
                        VariableInstruction.getLocal(2), MemoryInstruction.store(.i32, (2, 16)),
                        VariableInstruction.getLocal(2), VariableInstruction.getLocal(0),
                        NumericInstruction.const(.i32(2)), NumericInstruction.shl(.i32),
                        NumericInstruction.const(.i32(15)), NumericInstruction.add(.i32),
                        NumericInstruction.const(.i32(-16)), NumericInstruction.add(.i32),
                        NumericInstruction.sub(.i32), VariableInstruction.teeLocal(1),
                        ParametricInstruction.drop, VariableInstruction.getLocal(1),
                        NumericInstruction.const(.i64(4_294_967_297)), MemoryInstruction.store(.i64, (3, 0)),
                        VariableInstruction.getLocal(3), NumericInstruction.const(.i32(2)),
                        MemoryInstruction.store(.i32, (2, 12)),
                        ControlInstruction.block([], Expression(instructions: [
                            ControlInstruction.loop([], Expression(instructions: [
                                VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, (2, 12)),
                                VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, (2, 24)),
                                NumericInstruction.geS(.i32), ControlInstruction.brIf(1),
                                VariableInstruction.getLocal(1), VariableInstruction.getLocal(3),
                                MemoryInstruction.load(.i32, (2, 12)), VariableInstruction.teeLocal(2),
                                NumericInstruction.const(.i32(2)), NumericInstruction.shl(.i32),
                                NumericInstruction.add(.i32), VariableInstruction.teeLocal(0),
                                VariableInstruction.getLocal(0), NumericInstruction.const(.i32(-4)),
                                NumericInstruction.add(.i32), MemoryInstruction.load(.i32, (2, 0)),
                                VariableInstruction.getLocal(0), NumericInstruction.const(.i32(-8)),
                                NumericInstruction.add(.i32), MemoryInstruction.load(.i32, (2, 0)),
                                NumericInstruction.add(.i32), MemoryInstruction.store(.i32, (2, 0)),
                                VariableInstruction.getLocal(3), VariableInstruction.getLocal(2),
                                NumericInstruction.const(.i32(1)), NumericInstruction.add(.i32),
                                MemoryInstruction.store(.i32, (2, 12)), ControlInstruction.br(0),
                                PseudoInstruction.end,
                            ])),
                            ControlInstruction.unreachable, PseudoInstruction.end,
                        ])),
                        VariableInstruction.getLocal(3), VariableInstruction.getLocal(1),
                        VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, (2, 24)),
                        NumericInstruction.const(.i32(2)), NumericInstruction.shl(.i32),
                        NumericInstruction.add(.i32), MemoryInstruction.load(.i32, (2, 0)),
                        MemoryInstruction.store(.i32, (2, 28)), VariableInstruction.getLocal(3),
                        MemoryInstruction.load(.i32, (2, 16)), ParametricInstruction.drop,
                        VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, (2, 28)),
                        PseudoInstruction.end,
                ])),
            ],
            tables: [
                Table(
                    type: TableType(
                        elementType: FunctionType(parameters: nil, results: nil),
                        limits: Limits(min: 0, max: nil)
                    )
                ),
            ],
            memories: [
                Memory(type: Limits(min: 2, max: nil)),
            ],
            globals: [],
            elements: [],
            data: [
                Data(
                    data: 0,
                    offset: Expression(instructions: [
                        NumericInstruction.const(.i32(4)), PseudoInstruction.end,
                    ]),
                    initializer: [16, 0, 1, 0]
                ),
            ],
            start: nil,
            imports: [],
            exports: [
                Export(
                    name: "memory",
                    descriptor: ExportDescriptor.memory(0)
                ),
                Export(
                    name: "fib",
                    descriptor: ExportDescriptor.function(0)
                ),
                Export(
                    name: "fib_memo",
                    descriptor: ExportDescriptor.function(1)
                ),
            ]
        )
        let runtime = try Runtime(module: module, externalValues: [])
        var description = ""
        debugPrint(runtime, to: &description)
        XCTFail(description)
    }
}
