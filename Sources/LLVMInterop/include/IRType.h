#ifndef IRType_h
#define IRType_h

#include <llvm/IR/Type.h>

using namespace llvm;

class IRType {
public:
  Type *_t;
  IRType(Type *t) : _t(t) {}
};

using IRTypeVector = std::vector<Type *>;

#endif /* IRType_h */
