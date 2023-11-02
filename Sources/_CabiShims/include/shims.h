/// FIXME: This is a hack to reference a C function from Swift with C calling convention.
///       It is needed because swiftc does not support `@_cdecl` without a body.
///       This declaration should be removed after rdar://115802180 will be implemented.
void __wasm_call_ctors(void);
