#include "IRContext.h"

#include <llvm/IR/LegacyPassManager.h>

#include <llvm/MC/TargetRegistry.h>

#include <llvm/Support/FileSystem.h>
#include <llvm/Support/TargetSelect.h>

#include <llvm/Target/TargetMachine.h>
#include <llvm/Target/TargetOptions.h>

#include <llvm/TargetParser/Host.h>
#include <llvm/TargetParser/Triple.h>

IRContext::IRContext()
    : _context(make_shared<LLVMContext>()),
      _module(make_shared<Module>("codegen", *_context)),
      _builder(make_shared<IRBuilder<>>(*_context)),
      _fpm(make_shared<FunctionPassManager>()),
      _lam(make_shared<LoopAnalysisManager>()),
      _fam(make_shared<FunctionAnalysisManager>()),
      _cgam(make_shared<CGSCCAnalysisManager>()),
      _mam(make_shared<ModuleAnalysisManager>()),
      _pic(make_shared<PassInstrumentationCallbacks>()),
      _si(make_shared<StandardInstrumentations>(*_context, true)) {
  _si->registerCallbacks(*_pic, _mam.get());

  _fpm->addPass(PromotePass());
  _fpm->addPass(InstCombinePass());
  _fpm->addPass(ReassociatePass());
  _fpm->addPass(GVNPass());
  _fpm->addPass(SimplifyCFGPass());

  // Register analysis passes used in these transform passes.
  PassBuilder pb;
  pb.registerModuleAnalyses(*_mam);
  pb.registerFunctionAnalyses(*_fam);
  pb.crossRegisterProxies(*_lam, *_fam, *_cgam, *_mam);

#if __aarch64__
  LLVMInitializeAArch64TargetInfo();
  LLVMInitializeAArch64Target();
  LLVMInitializeAArch64TargetMC();
  LLVMInitializeAArch64AsmParser();
  LLVMInitializeAArch64AsmPrinter();
#elif __x86_64__
  LLVMInitializeX86TargetInfo();
  LLVMInitializeX86Target();
  LLVMInitializeX86TargetMC();
  LLVMInitializeX86AsmParser();
  LLVMInitializeX86AsmPrinter();
#endif
}

bool IRContext::emitObjectFile(StringRef path) const {
  auto targetTriple = sys::getDefaultTargetTriple();
  Triple triple(targetTriple);
  _module->setTargetTriple(triple);

  std::string error;
  auto target = TargetRegistry::lookupTarget(targetTriple, error);

  // Print an error and exit if we couldn't find the requested target.
  // This generally occurs if we've forgotten to initialise the
  // TargetRegistry or we have a bogus target triple.
  if (!target) {
    errs() << error;
    return false;
  }

  auto cpu = "generic";
  auto features = "";

  TargetOptions opt;
  auto targetMachine = target->createTargetMachine(triple, cpu, features,
                                                   opt, Reloc::PIC_);

  _module->setDataLayout(targetMachine->createDataLayout());

  std::error_code ec;
  raw_fd_ostream dest(path, ec, sys::fs::OpenFlags::OF_None);

  if (ec) {
    errs() << "Could not open file: " << ec.message();
    return false;
  }

  auto fileType = CodeGenFileType::ObjectFile;

  legacy::PassManager pass;
  targetMachine->addPassesToEmitFile(pass, dest, nullptr, fileType);
  pass.run(*_module);
  dest.flush();

  outs() << "Wrote " << path << "\n";

  return true;
}

std::string IRContext::printModule() const {
  std::string string = "";
  raw_string_ostream stream(string);

  this->_module->print(stream, nullptr);
  return string;
}

IRValue IRContext::createImportedFunction(StringRef name, IRPointerType type) {
  GlobalVariable *result =
      new GlobalVariable(*this->_module, type._pt, false,
                         llvm::GlobalValue::ExternalLinkage, nullptr, name);

  return result;
}

std::optional<IRFunction> IRContext::getFunction(StringRef name) const {
  Function *f = _module->getFunction(name);
  if (f) {
    return IRFunction(f);
  } else {
    return std::nullopt;
  }
}

IRValue IRContext::createLocal(IRType type) const {
  return _builder->CreateAlloca(type._t);
}

IRValue IRContext::getLocal(IRType type, IRValue address) const {
  return _builder->CreateLoad(type._t, address._v);
}

void IRContext::setLocal(IRValue address, IRValue value) const {
  _builder->CreateStore(value._v, address._v);
}

void IRContext::br(IRBlock successor) const {
  _builder->CreateBr(successor._b);
}

IRValue IRContext::condBr(IRValue condition, IRBlock trueBlock) const {

  return _builder->CreateCondBr(condition._v, trueBlock._b, nullptr);
}

IRValue IRContext::condBr(IRValue condition, IRBlock trueBlock,
                          IRBlock falseBlock) const {

  return _builder->CreateCondBr(condition._v, trueBlock._b, falseBlock._b);
}

IRValue IRContext::unreachable() const {
  return _builder->CreateIntrinsic(Intrinsic::trap, {});
}

IRValue IRContext::bEq(IRValue lhs, IRValue rhs) const {
  return _builder->CreateICmpEQ(lhs._v, rhs._v);
}

IRValue IRContext::iAdd(IRValue lhs, IRValue rhs) const {
  return _builder->CreateAdd(lhs._v, rhs._v);
}

IRValue IRContext::fAdd(IRValue lhs, IRValue rhs) const {
  return _builder->CreateFAdd(lhs._v, rhs._v);
}

IRValue IRContext::iSub(IRValue lhs, IRValue rhs) const {
  return _builder->CreateSub(lhs._v, rhs._v);
}

IRValue IRContext::fSub(IRValue lhs, IRValue rhs) const {
  return _builder->CreateFSub(lhs._v, rhs._v);
}

IRValue IRContext::iMul(IRValue lhs, IRValue rhs) const {
  return _builder->CreateMul(lhs._v, rhs._v);
}

IRValue IRContext::fMul(IRValue lhs, IRValue rhs) const {
  return _builder->CreateFMul(lhs._v, rhs._v);
}

IRValue IRContext::iEq(IRValue lhs, IRValue rhs) const {
  auto i32 = Type::getInt32Ty(*_context);
  auto eqResult = _builder->CreateICmpEQ(lhs._v, rhs._v);
  return _builder->CreateZExt(eqResult, i32);
}

IRValue IRContext::fEq(IRValue lhs, IRValue rhs) const {
  auto i32 = Type::getInt32Ty(*_context);
  auto eqResult = _builder->CreateFCmpUEQ(lhs._v, rhs._v);
  return _builder->CreateZExt(eqResult, i32);
}

IRValue IRContext::iNe(IRValue lhs, IRValue rhs) const {
  auto i32 = Type::getInt32Ty(*_context);
  auto eqResult = _builder->CreateICmpEQ(lhs._v, rhs._v);
  auto neResult = _builder->CreateNot(eqResult);
  return _builder->CreateZExt(neResult, i32);
}

IRValue IRContext::fNe(IRValue lhs, IRValue rhs) const {
  auto i32 = Type::getInt32Ty(*_context);
  auto eqResult = _builder->CreateFCmpUEQ(lhs._v, rhs._v);
  auto neResult = _builder->CreateNot(eqResult);
  return _builder->CreateZExt(neResult, i32);
}

IRValue IRContext::wrap(IRValue value) const {
  auto i32 = Type::getInt32Ty(*_context);
  return _builder->CreateTrunc(value._v, i32);
}

IRValue IRContext::extendUnsigned(IRValue value) const {
  auto i64 = Type::getInt64Ty(*_context);
  return _builder->CreateZExt(value._v, i64);
}

IRValue IRContext::extendSigned(IRValue value) const {
  auto i64 = Type::getInt64Ty(*_context);
  return _builder->CreateSExt(value._v, i64);
}

IRFunctionType IRContext::functionType(IRTypeVector parameters,
                                       IRType result) const {
  return FunctionType::get(result._t, parameters, false);
}

IRPointerType IRContext::pointerType() const {
  return PointerType::getUnqual(*_context);
}

IRValue IRContext::call(IRFunction callee, IRValueVector args) {
  return _builder->CreateCall(callee._f, args);
}

IRPHINode IRContext::phi(IRType type, unsigned int incomingCount) const {
  return _builder->CreatePHI(type._t, incomingCount);
}

std::string IRFunctionType::print() const {
  std::string string = "";
  raw_string_ostream stream(string);

  this->_ft->print(stream);
  return string;
}
