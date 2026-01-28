#ifndef IRContext_h
#define IRContext_h

#include <llvm/Analysis/AliasAnalysis.h>
#include <llvm/ADT/APFloat.h>

#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>

#include <llvm/Passes/PassBuilder.h>
#include <llvm/Passes/StandardInstrumentations.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Target/TargetMachine.h>
#include <llvm/Transforms/InstCombine/InstCombine.h>
#include <llvm/Transforms/Scalar.h>
#include <llvm/Transforms/Scalar/GVN.h>
#include <llvm/Transforms/Scalar/Reassociate.h>
#include <llvm/Transforms/Scalar/SimplifyCFG.h>
#include <llvm/Transforms/Utils/Mem2Reg.h>

#include "IRBlock.h"
#include "IRFunctionType.h"
#include "IRPointerType.h"
#include "IRFunction.h"
#include "IRPHINode.h"
#include "IRType.h"
#include "IRValue.h"

using namespace llvm;
using namespace std;

class IRContext {
  shared_ptr<LLVMContext> _context;
  shared_ptr<Module> _module;
  shared_ptr<IRBuilder<>> _builder;

  shared_ptr<FunctionPassManager> _fpm;
  shared_ptr<LoopAnalysisManager> _lam;
  shared_ptr<FunctionAnalysisManager> _fam;
  shared_ptr<CGSCCAnalysisManager> _cgam;
  shared_ptr<ModuleAnalysisManager> _mam;
  shared_ptr<PassInstrumentationCallbacks> _pic;
  shared_ptr<StandardInstrumentations> _si;

public:
  IRContext();

  bool emitObjectFile(StringRef path) const;

  void optimize(IRFunction f) { _fpm->run(*f._f, *_fam); }

  string printModule() const;

  optional<IRFunction> getFunction(StringRef name) const;

  IRValue createImportedFunction(StringRef name, IRPointerType type);

  IRValue f32Value(float f32) const {
    return ConstantFP::get(*_context, APFloat(f32));
  }

  IRValue f64Value(double f64) const {
    return ConstantFP::get(*_context, APFloat(f64));
  }

  IRValue i64Value(uint64_t i64) const {
    return ConstantInt::get(*_context, APInt(64, i64));
  }

  IRValue i32Value(uint32_t i32) const {
    return ConstantInt::get(*_context, APInt(32, i32));
  }

  IRValue createLocal(IRType type) const;
  IRValue getLocal(IRType type, IRValue local) const;
  void setLocal(IRValue local, IRValue value) const;

  IRValue call(IRFunction callee, IRValueVector args);

  void br(IRBlock successor) const;
  IRValue condBr(IRValue condition, IRBlock trueBlock) const;
  IRValue condBr(IRValue condition, IRBlock trueBlock,
                 IRBlock falseBlock) const;
  IRPHINode phi(IRType type, unsigned int incomingCount) const;

  IRValue unreachable() const;

  IRValue bEq(IRValue lhs, IRValue rhs) const;

  IRValue iAdd(IRValue lhs, IRValue rhs) const;
  IRValue fAdd(IRValue lhs, IRValue rhs) const;
  IRValue iSub(IRValue lhs, IRValue rhs) const;
  IRValue fSub(IRValue lhs, IRValue rhs) const;
  IRValue iMul(IRValue lhs, IRValue rhs) const;
  IRValue fMul(IRValue lhs, IRValue rhs) const;
  IRValue iEq(IRValue lhs, IRValue rhs) const;
  IRValue fEq(IRValue lhs, IRValue rhs) const;
  IRValue iNe(IRValue lhs, IRValue rhs) const;
  IRValue fNe(IRValue lhs, IRValue rhs) const;

  IRValue wrap(IRValue value) const;
  IRValue extendUnsigned(IRValue value) const;
  IRValue extendSigned(IRValue value) const;

  IRFunctionType functionType(IRTypeVector parameters, IRType result) const;
  IRPointerType pointerType() const;

  IRType i32Type() const { return Type::getInt32Ty(*_context); }
  IRType i64Type() const { return Type::getInt64Ty(*_context); }
  IRType f32Type() const { return Type::getFloatTy(*_context); }
  IRType f64Type() const { return Type::getDoubleTy(*_context); }

  IRType voidType() const { return Type::getVoidTy(*_context); }

  IRType structType(IRTypeVector types) const {
    return StructType::create(types);
  }

  IRBlock block(IRFunction function, StringRef name) const {
    return BasicBlock::Create(*_context, name, function._f);
  }

  void setInsertPoint(IRBlock block) { _builder->SetInsertPoint(block._b); }

  void createRet(IRValue value) { _builder->CreateRet(value._v); }

  IRFunction function(IRFunctionType type, StringRef name) const {
    return Function::Create(type._ft, Function::ExternalLinkage, name,
                            _module.get());
  }
};

#endif /* IRContext_h */
