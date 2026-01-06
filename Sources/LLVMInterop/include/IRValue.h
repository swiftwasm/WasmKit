#pragma once

#include "IRPHINode.h"
#include <llvm/IR/Value.h>

using namespace llvm;

using IRValueVector = std::vector<Value *>;

class IRValue {
public:
  Value *_v;

  IRValue(Value *v) : _v(v) {}
  IRValue(IRPHINode phi) : _v(phi._n) {}

  std::string print() const {
    std::string string = "";
    raw_string_ostream stream(string);

    this->_v->print(stream);
    return string;
  }
};
