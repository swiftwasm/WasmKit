#include <llvm/IR/DerivedTypes.h>

using namespace llvm;
using namespace std;


class IRFunctionType {
public:
  FunctionType *_ft;

  IRFunctionType(FunctionType *ft) : _ft(ft) {}

  string print() const;
};
