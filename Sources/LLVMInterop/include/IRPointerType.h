#include <llvm/IR/LLVMContext.h>

using namespace llvm;
using namespace std;

class IRPointerType {
public:
  PointerType *_pt;

  IRPointerType(PointerType *pt): _pt(pt) {}
};
