#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>

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
  imm rhs;
  reg lhs;
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

typedef uint64_t OpStorage;

struct Inst {
  intptr_t ty;
  OpStorage op;
};


extern void * _Nonnull labelTable[numberOfInstTypes];

typedef const struct Inst * _Nonnull (inst_exec)(const struct Inst * _Nonnull , int * _Nonnull regs);

const struct Inst * _Nonnull handle_randomGet(const struct Inst * _Nonnull , int * _Nonnull regs);
const struct Inst * _Nonnull handle_brIf(const struct Inst * _Nonnull , int * _Nonnull regs);
const struct Inst * _Nonnull handle_i32Ltu(const struct Inst * _Nonnull , int * _Nonnull regs);
const struct Inst * _Nonnull handle_i32AddImm(const struct Inst * _Nonnull , int * _Nonnull regs);


static inline intptr_t Inst_op_offset(void) { return offsetof(struct Inst, op); }
static inline intptr_t BrIfOp_cond_offset(void) { return offsetof(struct BrIfOp, cond); }
static inline intptr_t BrIfOp_offset_offset(void) { return offsetof(struct BrIfOp, offset); }

__attribute__((always_inline))
static inline void enter(const struct Inst * _Nullable iseq,
                         int * _Nullable regs) {
  if (!iseq) {
    labelTable[randomGet] = &&do_randomGet;
    labelTable[brIf] = &&do_brIf;
    labelTable[i32AddImm] = &&do_i32AddImm;
    labelTable[i32Ltu] = &&do_i32Ltu;
    labelTable[endOfFunction] = &&do_endOfFunction;
    return;
  }
  const struct Inst *pc = iseq;
  #define NEXT do { \
    goto *(void *)((++pc)->ty); \
  } while (0)

  goto *(void *)((pc)->ty);

  do_randomGet: {
    pc = handle_randomGet(pc, regs);
    NEXT;
  }
  do_brIf: {
    pc = handle_brIf(pc, regs);
    NEXT;
  }
  do_i32AddImm: {
    pc = handle_i32AddImm(pc, regs);
    NEXT;
  }
  do_i32Ltu: {
    pc = handle_i32Ltu(pc, regs);
    NEXT;
  }
  do_endOfFunction: {
    return;
  }
}
