/* Token threaded code by C */

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

typedef uint16_t reg;
typedef uint32_t imm;

struct BrIfOp {
  reg cond;
  int32_t offset;
};

struct I32AddImmOp {
  imm lhs;
  reg rhs;
  reg result;
};

struct I32LtuOp {
  reg lhs;
  imm rhs;
  reg result;
};

union Op {
  reg randomGet;
  struct BrIfOp brIf;
  struct I32AddImmOp i32AddImm;
  struct I32LtuOp i32Ltu;
};

enum InstTy {
  randomGet,
  brIf,
  i32AddImm,
  i32Ltu,
  endOfFunction,

  numberOfInstTypes,
};

struct Inst {
  intptr_t ty;
  union Op op;
};

void enter(const struct Inst *iseq, int *regs) {
  void *labelTable[numberOfInstTypes] = {
    [randomGet] = &&do_randomGet,
    [brIf] = &&do_brIf,
    [i32AddImm] = &&do_i32AddImm,
    [i32Ltu] = &&do_i32Ltu,
    [endOfFunction] = &&do_endOfFunction,
  };

  const struct Inst *pc = iseq;
  
  goto head;

next:
  pc++;
head:
  goto *(void *)labelTable[pc->ty];
  
#define NEXT goto next;

  do_randomGet: {
    reg op = pc->op.randomGet;
    regs[op] = 42;
    NEXT;
  }
  do_brIf: {
    struct BrIfOp op = pc->op.brIf;
    if (regs[op.cond] != 0) {
      pc += op.offset;
    }
    NEXT;
  }
  do_i32AddImm: {
    struct I32AddImmOp op = pc->op.i32AddImm;
    regs[op.result] = op.lhs + regs[op.rhs];
    NEXT;
  }
  do_i32Ltu: {
    struct I32LtuOp op = pc->op.i32Ltu;
    regs[op.result] = regs[op.lhs] < op.rhs ? 1 : 0;
    NEXT;
  }
  do_endOfFunction: {
    return;
  }
}

int main(void) {
  reg xReg = 0;
  reg iReg = 1;
  reg condReg = 2;
  struct Inst iseq[] = {
    (struct Inst){ .ty = randomGet, .op = { .randomGet = xReg } },
    (struct Inst){ .ty = i32AddImm, .op = { .i32AddImm = { .lhs = 1, .rhs = iReg, .result = iReg } } },
    (struct Inst){ .ty = i32AddImm, .op = { .i32AddImm = { .lhs = 1, .rhs = xReg, .result = xReg } } },
    (struct Inst){ .ty = i32Ltu, .op = { .i32Ltu = { .lhs = iReg, .rhs = 10000000, .result = condReg } } },
    (struct Inst){ .ty = brIf, .op = { .brIf = { .cond = condReg, .offset = -4 } } },
    (struct Inst){ .ty = endOfFunction },
  };

  int regs[3] = { 0, 0, 0 };

  enter(iseq, regs);

  return 0;
}
