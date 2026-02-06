#pragma once

#include <llvm/IR/Instructions.h>

class IRValue;
class IRBlock;

using namespace llvm;

class IRPHINode {
public:
  PHINode *_n;

  IRPHINode(PHINode *n) : _n(n) {}

  void addIncoming(IRValue v, IRBlock b);
};
