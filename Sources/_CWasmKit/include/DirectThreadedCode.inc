SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyStack(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyStack(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyStack(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyX0ToStackI32(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyX0ToStackI32(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyX0ToStackI32(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyX0ToStackI64(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyX0ToStackI64(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyX0ToStackI64(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyD0ToStackF32(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyD0ToStackF32(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyD0ToStackF32(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyD0ToStackF64(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyD0ToStackF64(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyD0ToStackF64(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_globalGet(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_globalGet(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_globalGet(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_globalSet(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_globalSet(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_globalSet(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_call(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_call(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_call(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_compilingCall(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_compilingCall(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_compilingCall(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_internalCall(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_internalCall(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_internalCall(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_callIndirect(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_callIndirect(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_callIndirect(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_unreachable(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_unreachable(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_unreachable(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_nop(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_nop(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_nop(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_br(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_br(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_br(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_brIf(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_brIf(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_brIf(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_brIfNot(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_brIfNot(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_brIfNot(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_brTable(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_brTable(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_brTable(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc__return(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute__return(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute__return(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_endOfExecution(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_endOfExecution(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_endOfExecution(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Load(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Load(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Load(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Load(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Load(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Load(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load8S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load8S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load8S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load8U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load8U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load8U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load16S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load16S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load16S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load16U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load16U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load16U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load8S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load8S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load8S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load8U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load8U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load8U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load16S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load16S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load16S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load16U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load16U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load16U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Store(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Store(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Store(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Store(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Store(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Store(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Store(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Store(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Store(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Store8(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Store8(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Store8(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Store16(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Store16(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Store16(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store8(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store8(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store8(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store16(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store16(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store16(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store32(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store32(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store32(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memorySize(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memorySize(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memorySize(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryGrow(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryGrow(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryGrow(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryInit(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryInit(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryInit(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryDataDrop(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryDataDrop(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryDataDrop(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryCopy(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryCopy(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryCopy(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryFill(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryFill(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryFill(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_const32(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_const32(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_const32(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_const64(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_const64(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_const64(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32AddSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32AddSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32AddSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32AddSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32AddSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32AddSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64AddSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64AddSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64AddSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64AddSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64AddSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64AddSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32MulSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32MulSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32MulSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32MulSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32MulSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32MulSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64MulSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64MulSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64MulSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64MulSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64MulSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64MulSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32AndSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32AndSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32AndSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32AndSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32AndSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32AndSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64AndSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64AndSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64AndSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64AndSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64AndSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64AndSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32OrSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32OrSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32OrSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32OrSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32OrSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32OrSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64OrSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64OrSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64OrSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64OrSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64OrSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64OrSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32XorSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32XorSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32XorSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32XorSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32XorSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32XorSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64XorSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64XorSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64XorSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64XorSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64XorSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64XorSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32SubSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32SubSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32SubSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32SubSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32SubSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32SubSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32SubRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32SubRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32SubRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64SubSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64SubSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64SubSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64SubSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64SubSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64SubSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64SubRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64SubRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64SubRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShlSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShlSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShlSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShlSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShlSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShlSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShlRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShlRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShlRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShlSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShlSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShlSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShlSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShlSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShlSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShlRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShlRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShlRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrSSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrSSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrSSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrSSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrSSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrSSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrSRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrSRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrSRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrSSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrSSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrSSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrSSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrSSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrSSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrSRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrSRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrSRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrUSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrUSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrUSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrUSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrUSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrUSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrURS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrURS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrURS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrUSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrUSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrUSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrUSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrUSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrUSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrURS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrURS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrURS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RotlSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RotlSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RotlSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RotlSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RotlSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RotlSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RotlRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RotlRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RotlRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RotlSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RotlSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RotlSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RotlSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RotlSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RotlSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RotlRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RotlRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RotlRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RotrSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RotrSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RotrSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RotrSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RotrSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RotrSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RotrRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RotrRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RotrRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RotrSS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RotrSS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RotrSS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RotrSR(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RotrSR(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RotrSR(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RotrRS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RotrRS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RotrRS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32DivS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32DivS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32DivS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64DivS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64DivS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64DivS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32DivU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32DivU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32DivU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64DivU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64DivU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64DivU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RemS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RemS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RemS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RemS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RemS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RemS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RemU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RemU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RemU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RemU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RemU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RemU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Eq(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Eq(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Eq(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Eq(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Eq(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Eq(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Ne(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Ne(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Ne(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Ne(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Ne(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Ne(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LtS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LtS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LtS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LtS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LtS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LtS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LtU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LtU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LtU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LtU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LtU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LtU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GtS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GtS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GtS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GtS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GtS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GtS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GtU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GtU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GtU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GtU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GtU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GtU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LeS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LeS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LeS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LeS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LeS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LeS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LeU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LeU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LeU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LeU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LeU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LeU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GeS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GeS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GeS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GeS(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GeS(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GeS(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GeU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GeU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GeU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GeU(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GeU(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GeU(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Clz(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Clz(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Clz(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Clz(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Clz(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Clz(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Ctz(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Ctz(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Ctz(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Ctz(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Ctz(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Ctz(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Popcnt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Popcnt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Popcnt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Popcnt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Popcnt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Popcnt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Eqz(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Eqz(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Eqz(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Eqz(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Eqz(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Eqz(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32WrapI64(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32WrapI64(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32WrapI64(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ExtendI32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ExtendI32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ExtendI32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ExtendI32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ExtendI32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ExtendI32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Extend8S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Extend8S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Extend8S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Extend8S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Extend8S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Extend8S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Extend16S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Extend16S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Extend16S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Extend16S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Extend16S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Extend16S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Extend32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Extend32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Extend32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF64S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF64S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF64S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF64U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF64U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF64U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF64S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF64S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF64S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF64U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF64U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF64U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF64S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF64S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF64S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF64U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF64U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF64U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF64S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF64S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF64S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF64U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF64U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF64U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI64S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI64S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI64S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI64U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI64U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI64U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI32S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI32S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI32S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI32U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI32U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI32U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI64S(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI64S(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI64S(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI64U(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI64U(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI64U(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ReinterpretI32(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ReinterpretI32(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ReinterpretI32(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ReinterpretI64(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ReinterpretI64(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ReinterpretI64(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ReinterpretF32(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ReinterpretF32(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ReinterpretF32(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ReinterpretF64(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ReinterpretF64(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ReinterpretF64(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Add(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Add(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Add(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Add(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Add(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Add(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Sub(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Sub(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Sub(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Sub(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Sub(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Sub(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Mul(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Mul(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Mul(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Mul(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Mul(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Mul(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Div(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Div(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Div(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Div(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Div(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Div(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Min(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Min(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Min(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Min(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Min(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Min(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Max(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Max(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Max(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Max(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Max(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Max(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32CopySign(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32CopySign(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32CopySign(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64CopySign(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64CopySign(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64CopySign(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Eq(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Eq(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Eq(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Eq(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Eq(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Eq(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Ne(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Ne(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Ne(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Ne(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Ne(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Ne(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Lt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Lt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Lt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Lt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Lt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Lt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Gt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Gt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Gt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Gt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Gt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Gt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Le(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Le(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Le(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Le(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Le(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Le(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Ge(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Ge(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Ge(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Ge(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Ge(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Ge(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Abs(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Abs(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Abs(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Abs(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Abs(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Abs(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Neg(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Neg(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Neg(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Neg(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Neg(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Neg(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Ceil(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Ceil(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Ceil(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Ceil(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Ceil(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Ceil(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Floor(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Floor(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Floor(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Floor(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Floor(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Floor(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Trunc(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Trunc(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Trunc(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Trunc(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Trunc(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Trunc(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Nearest(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Nearest(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Nearest(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Nearest(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Nearest(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Nearest(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Sqrt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Sqrt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Sqrt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Sqrt(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Sqrt(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Sqrt(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64PromoteF32(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64PromoteF32(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64PromoteF32(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32DemoteF64(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32DemoteF64(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32DemoteF64(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_select(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_select(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_select(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_refNull(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_refNull(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_refNull(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_refIsNull(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_refIsNull(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_refIsNull(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_refFunc(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_refFunc(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_refFunc(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableGet(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableGet(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableGet(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableSet(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableSet(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableSet(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableSize(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableSize(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableSize(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableGrow(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableGrow(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableGrow(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableFill(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableFill(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableFill(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableCopy(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableCopy(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableCopy(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableInit(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableInit(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableInit(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableElementDrop(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableElementDrop(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableElementDrop(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_onEnter(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_onEnter(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_onEnter(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_onExit(Sp sp, X0 x0, D0 d0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_onExit(Sp *sp, X0 *x0, D0 *d0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_onExit(&sp, &x0, &d0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, x0, d0, pc, md, ms, state);
}
static const uint64_t wasmkit_tc_exec_handlers[] = {
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyStack),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyX0ToStackI32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyX0ToStackI64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyD0ToStackF32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyD0ToStackF64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_globalGet),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_globalSet),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_call),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_compilingCall),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_internalCall),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_callIndirect),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_unreachable),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_nop),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_br),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_brIf),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_brIfNot),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_brTable),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc__return),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_endOfExecution),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Load),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Load),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Load),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Load),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Load8S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Load8U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Load16S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Load16U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Load8S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Load8U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Load16S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Load16U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Load32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Load32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Store),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Store),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Store),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Store),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Store8),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Store16),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Store8),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Store16),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Store32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_memorySize),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_memoryGrow),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_memoryInit),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_memoryDataDrop),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_memoryCopy),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_memoryFill),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_const32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_const64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32AddSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32AddSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64AddSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64AddSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32MulSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32MulSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64MulSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64MulSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32AndSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32AndSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64AndSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64AndSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32OrSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32OrSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64OrSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64OrSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32XorSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32XorSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64XorSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64XorSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32SubSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32SubSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32SubRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64SubSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64SubSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64SubRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShlSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShlSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShlRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShlSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShlSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShlRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrSSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrSSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrSRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrSSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrSSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrSRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrUSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrUSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrURS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrUSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrUSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrURS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RotlSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RotlSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RotlRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RotlSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RotlSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RotlRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RotrSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RotrSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RotrRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RotrSS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RotrSR),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RotrRS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32DivS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64DivS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32DivU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64DivU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RemS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RemS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32RemU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64RemU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Eq),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Eq),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Ne),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Ne),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32LtS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64LtS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32LtU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64LtU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32GtS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64GtS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32GtU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64GtU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32LeS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64LeS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32LeU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64LeU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32GeS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64GeS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32GeU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64GeU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Clz),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Clz),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Ctz),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Ctz),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Popcnt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Popcnt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Eqz),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Eqz),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32WrapI64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ExtendI32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ExtendI32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Extend8S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Extend8S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Extend16S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Extend16S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Extend32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncF32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncF32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncSatF32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncSatF32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncF64S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncF64U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncSatF64S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32TruncSatF64U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncF32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncF32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncSatF32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncSatF32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncF64S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncF64U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncSatF64S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64TruncSatF64U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32ConvertI32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32ConvertI32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32ConvertI64S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32ConvertI64U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64ConvertI32S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64ConvertI32U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64ConvertI64S),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64ConvertI64U),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32ReinterpretI32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64ReinterpretI64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ReinterpretF32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ReinterpretF64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Add),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Add),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Sub),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Sub),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Mul),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Mul),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Div),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Div),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Min),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Min),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Max),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Max),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32CopySign),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64CopySign),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Eq),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Eq),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Ne),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Ne),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Lt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Lt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Gt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Gt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Le),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Le),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Ge),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Ge),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Abs),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Abs),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Neg),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Neg),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Ceil),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Ceil),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Floor),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Floor),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Trunc),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Trunc),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Nearest),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Nearest),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32Sqrt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64Sqrt),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f64PromoteF32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_f32DemoteF64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_select),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_refNull),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_refIsNull),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_refFunc),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableGet),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableSet),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableSize),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableGrow),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableFill),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableCopy),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableInit),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_tableElementDrop),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_onEnter),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_onExit),
};
