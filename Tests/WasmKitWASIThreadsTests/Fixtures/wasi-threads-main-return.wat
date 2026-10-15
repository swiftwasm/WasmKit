(module
  (import "env" "memory" (memory 1 1 shared))
  (export "memory" (memory 0))
  (import "wasi" "thread-spawn" (func $spawn (param i32) (result i32)))
  (func (export "wasi_thread_start") (param i32 i32)
    (loop br 0))
  (func (export "_start")
    (drop (call $spawn (i32.const 0))))
)
