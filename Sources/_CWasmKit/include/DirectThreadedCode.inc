SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyStack(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyStack(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyStack(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyR0ToStackI32(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyR0ToStackI32(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyR0ToStackI32(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyR0ToStackI64(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyR0ToStackI64(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyR0ToStackI64(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyR0ToStackF32(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyR0ToStackF32(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyR0ToStackF32(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_copyR0ToStackF64(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_copyR0ToStackF64(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_copyR0ToStackF64(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_globalGet(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_globalGet(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_globalGet(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_globalSet(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_globalSet(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_globalSet(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_call(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_call(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_call(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_compilingCall(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_compilingCall(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_compilingCall(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_internalCall(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_internalCall(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_internalCall(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_callIndirect(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_callIndirect(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_callIndirect(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_unreachable(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_unreachable(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_unreachable(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_nop(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_nop(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_nop(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_br(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_br(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_br(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_brIf(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_brIf(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_brIf(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_brIfNot(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_brIfNot(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_brIfNot(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_brTable(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_brTable(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_brTable(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc__return(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute__return(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute__return(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_endOfExecution(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_endOfExecution(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_endOfExecution(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Load(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Load(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Load(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Load(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Load(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Load(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load8S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load8S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load8S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load8U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load8U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load8U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load16S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load16S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load16S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Load16U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Load16U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Load16U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load8S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load8S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load8S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load8U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load8U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load8U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load16S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load16S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load16S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load16U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load16U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load16U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load32S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Load32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Load32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Load32U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Store(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Store(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Store(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Store(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Store(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Store(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Store(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Store(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Store(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Store8(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Store8(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Store8(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Store16(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Store16(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Store16(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store8(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store8(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store8(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store16(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store16(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store16(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Store32(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Store32(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Store32(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memorySize(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memorySize(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memorySize(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryGrow(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryGrow(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryGrow(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryInit(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryInit(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryInit(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryDataDrop(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryDataDrop(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryDataDrop(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryCopy(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryCopy(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryCopy(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_memoryFill(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_memoryFill(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_memoryFill(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_const32(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_const32(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_const32(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_const64(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_const64(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_const64(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32AddSS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32AddSS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32AddSS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32AddSR(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32AddSR(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32AddSR(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64AddSS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64AddSS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64AddSS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64AddSR(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64AddSR(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64AddSR(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Sub(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Sub(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Sub(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Sub(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Sub(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Sub(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Mul(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Mul(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Mul(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Mul(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Mul(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Mul(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32And(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32And(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32And(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64And(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64And(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64And(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Or(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Or(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Or(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Or(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Or(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Or(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Xor(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Xor(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Xor(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Xor(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Xor(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Xor(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Shl(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Shl(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Shl(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Shl(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Shl(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Shl(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ShrU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ShrU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ShrU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ShrU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ShrU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ShrU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Rotl(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Rotl(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Rotl(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Rotl(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Rotl(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Rotl(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Rotr(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Rotr(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Rotr(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Rotr(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Rotr(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Rotr(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32DivS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32DivS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32DivS(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64DivS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64DivS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64DivS(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32DivU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32DivU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32DivU(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64DivU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64DivU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64DivU(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RemS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RemS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RemS(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RemS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RemS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RemS(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32RemU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32RemU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32RemU(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64RemU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64RemU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64RemU(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Eq(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Eq(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Eq(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Eq(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Eq(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Eq(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Ne(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Ne(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Ne(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Ne(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Ne(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Ne(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LtS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LtS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LtS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LtS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LtS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LtS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LtU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LtU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LtU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LtU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LtU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LtU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GtS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GtS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GtS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GtS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GtS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GtS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GtU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GtU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GtU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GtU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GtU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GtU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LeS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LeS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LeS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LeS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LeS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LeS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32LeU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32LeU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32LeU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64LeU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64LeU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64LeU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GeS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GeS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GeS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GeS(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GeS(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GeS(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32GeU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32GeU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32GeU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64GeU(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64GeU(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64GeU(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Clz(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Clz(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Clz(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Clz(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Clz(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Clz(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Ctz(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Ctz(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Ctz(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Ctz(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Ctz(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Ctz(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Popcnt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Popcnt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Popcnt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Popcnt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Popcnt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Popcnt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Eqz(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Eqz(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Eqz(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Eqz(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Eqz(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Eqz(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32WrapI64(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32WrapI64(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32WrapI64(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ExtendI32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ExtendI32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ExtendI32S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ExtendI32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ExtendI32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ExtendI32U(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Extend8S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Extend8S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Extend8S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Extend8S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Extend8S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Extend8S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Extend16S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32Extend16S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32Extend16S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Extend16S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Extend16S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Extend16S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64Extend32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64Extend32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64Extend32S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF32S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF32U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF32S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF32U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF64S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF64S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF64S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncF64U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncF64U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncF64U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF64S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF64S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF64S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32TruncSatF64U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32TruncSatF64U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32TruncSatF64U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF32S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF32U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF32S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF32U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF64S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF64S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF64S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncF64U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncF64U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncF64U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF64S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF64S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF64S(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64TruncSatF64U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64TruncSatF64U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64TruncSatF64U(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI32S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI32U(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI64S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI64S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI64S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ConvertI64U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ConvertI64U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ConvertI64U(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI32S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI32S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI32S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI32U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI32U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI32U(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI64S(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI64S(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI64S(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ConvertI64U(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ConvertI64U(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ConvertI64U(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32ReinterpretI32(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32ReinterpretI32(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32ReinterpretI32(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64ReinterpretI64(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64ReinterpretI64(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64ReinterpretI64(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32ReinterpretF32(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i32ReinterpretF32(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i32ReinterpretF32(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_i64ReinterpretF64(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_i64ReinterpretF64(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_i64ReinterpretF64(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Add(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Add(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Add(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Add(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Add(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Add(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Sub(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Sub(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Sub(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Sub(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Sub(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Sub(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Mul(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Mul(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Mul(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Mul(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Mul(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Mul(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Div(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Div(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Div(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Div(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Div(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Div(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Min(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Min(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Min(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Min(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Min(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Min(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Max(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Max(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Max(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Max(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Max(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Max(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32CopySign(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32CopySign(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32CopySign(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64CopySign(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64CopySign(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64CopySign(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Eq(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Eq(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Eq(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Eq(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Eq(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Eq(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Ne(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Ne(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Ne(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Ne(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Ne(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Ne(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Lt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Lt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Lt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Lt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Lt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Lt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Gt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Gt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Gt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Gt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Gt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Gt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Le(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Le(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Le(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Le(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Le(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Le(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Ge(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Ge(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Ge(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Ge(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Ge(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Ge(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Abs(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Abs(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Abs(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Abs(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Abs(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Abs(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Neg(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Neg(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Neg(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Neg(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Neg(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Neg(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Ceil(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Ceil(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Ceil(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Ceil(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Ceil(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Ceil(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Floor(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Floor(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Floor(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Floor(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Floor(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Floor(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Trunc(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Trunc(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Trunc(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Trunc(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Trunc(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Trunc(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Nearest(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Nearest(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Nearest(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Nearest(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Nearest(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Nearest(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32Sqrt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32Sqrt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32Sqrt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64Sqrt(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64Sqrt(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64Sqrt(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f64PromoteF32(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f64PromoteF32(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f64PromoteF32(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_f32DemoteF64(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_f32DemoteF64(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_f32DemoteF64(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_select(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_select(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_select(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_refNull(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_refNull(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_refNull(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_refIsNull(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_refIsNull(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_refIsNull(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_refFunc(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_refFunc(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_refFunc(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableGet(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableGet(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableGet(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableSet(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableSet(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableSet(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableSize(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableSize(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableSize(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableGrow(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableGrow(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableGrow(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableFill(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableFill(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableFill(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableCopy(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableCopy(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableCopy(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableInit(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableInit(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableInit(&sp, &r0, &pc, &md, &ms, state, &error);
    if (error) return wasmkit_execution_state_set_error(error, state);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_tableElementDrop(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_tableElementDrop(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_tableElementDrop(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_onEnter(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_onEnter(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_onEnter(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
SWIFT_CC(swiftasync) static inline void wasmkit_tc_onExit(Sp sp, R0 r0, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) void wasmkit_execute_onExit(Sp *sp, R0 *r0, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    pc += sizeof(uint64_t);
    void * _Nullable error = NULL;
    INLINE_CALL wasmkit_execute_onExit(&sp, &r0, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)(*(void **)pc))(sp, r0, pc, md, ms, state);
}
static const uint64_t wasmkit_tc_exec_handlers[] = {
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyStack),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyR0ToStackI32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyR0ToStackI64),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyR0ToStackF32),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_copyR0ToStackF64),
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
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Sub),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Sub),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Mul),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Mul),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32And),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64And),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Or),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Or),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Xor),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Xor),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Shl),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Shl),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrS),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32ShrU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64ShrU),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Rotl),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Rotl),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i32Rotr),
    (uint64_t)((wasmkit_tc_exec)&wasmkit_tc_i64Rotr),
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
