import XCTest
@testable import WasmKit


final class EngineTests: XCTestCase {
    func testInstructionSize() {
        func checkSize<T>(_: T.Type) {
            print("sizeof(\(T.self)) = \(MemoryLayout<T>.size)")
            print("alignof(\(T.self)) = \(MemoryLayout<T>.alignment)")
        }

        checkSize(Instruction.self)
        checkSize(Instruction.BinaryOperand.self)
        checkSize(Instruction.UnaryOperand.self)
        checkSize(Instruction.ConstOperand.self)
        checkSize(Instruction.LoadOperand.self)
        checkSize(Instruction.StoreOperand.self)
        checkSize(Instruction.MemorySizeOperand.self)
        checkSize(Instruction.MemoryGrowOperand.self)
        checkSize(Instruction.MemoryInitOperand.self)
        checkSize(Instruction.MemoryCopyOperand.self)
        checkSize(Instruction.MemoryFillOperand.self)
        checkSize(Instruction.SelectOperand.self)
        checkSize(Instruction.RefNullOperand.self)
        checkSize(Instruction.RefIsNullOperand.self)
        checkSize(Instruction.RefFuncOperand.self)
        checkSize(Instruction.TableGetOperand.self)
        checkSize(Instruction.TableSetOperand.self)
        checkSize(Instruction.TableSizeOperand.self)
        checkSize(Instruction.TableGrowOperand.self)
        checkSize(Instruction.TableFillOperand.self)
        checkSize(Instruction.TableCopyOperand.self)
        checkSize(Instruction.TableInitOperand.self)
        checkSize(Instruction.GlobalGetOperand.self)
        checkSize(Instruction.GlobalSetOperand.self)
        checkSize(Instruction.CopyStackOperand.self)
        checkSize(Instruction.IfOperand.self)
        checkSize(Instruction.BrIfOperand.self)
        checkSize(Instruction.BrTableOperand.self)
        checkSize(Instruction.CallLikeOperand.self)
        checkSize(Instruction.CallOperand.self)
        checkSize(Instruction.InternalCallOperand.self)
        checkSize(Instruction.CallIndirectOperand.self)
        checkSize(Instruction.BrTable.self)

    }
}
