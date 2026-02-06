#include "IRPHINode.h"
#include "IRBlock.h"
#include "IRValue.h"

void IRPHINode::addIncoming(IRValue v, IRBlock b) {
  this->_n->addIncoming(v._v, b._b);
}
