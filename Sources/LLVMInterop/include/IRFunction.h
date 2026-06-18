#ifndef IRFunction_h
#define IRFunction_h


#include <llvm/IR/Function.h>
#include <llvm/IR/Verifier.h>

#include "IRValue.h"

using namespace llvm;
using namespace std;

class IRFunction {
public:
  Function *_f;

  bool _isValid;

  IRFunction() : _f(nullptr), _isValid(false) {}
  IRFunction(Function *f) : _f(f), _isValid(true) {}

  IRValue getArgument(uint32_t i) const { return _f->getArg(i); }

  optional<string> print() const;
  optional<string> verify() const;
};

#endif /* IRFunction_h */
