#ifndef IRBlock_h
#define IRBlock_h

#include <istream>
#include <llvm/IR/BasicBlock.h>

using namespace llvm;

class IRBlock {
public:
  BasicBlock *_b;

  IRBlock(BasicBlock *b) : _b(b) {}

  bool isEmpty() { return _b->empty(); }
  void eraseFromParent() { _b->eraseFromParent(); }
};

#endif /* IRBlock_h */
