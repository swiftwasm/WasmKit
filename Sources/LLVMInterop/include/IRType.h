#ifndef IRType_h
#define IRType_h

#include <llvm/IR/Type.h>

using namespace llvm;

class IRType {
public:
  Type *_t;
  IRType(Type *t) : _t(t) {}

  std::string print() const {
    string string = "";
    raw_string_ostream stream(string);

    this->_t->print(stream);
    return string;
  }
};

using IRTypeVector = std::vector<Type *>;

#endif /* IRType_h */
