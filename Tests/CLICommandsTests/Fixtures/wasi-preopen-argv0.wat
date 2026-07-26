(module
  (import "wasi_snapshot_preview1" "args_sizes_get"
    (func $args_sizes_get (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "args_get"
    (func $args_get (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_prestat_get"
    (func $fd_prestat_get (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_prestat_dir_name"
    (func $fd_prestat_dir_name (param i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "path_open"
    (func $path_open (param i32 i32 i32 i32 i32 i64 i64 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_read"
    (func $fd_read (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "proc_exit"
    (func $proc_exit (param i32)))
  (memory (export "memory") 2)

  ;; Expectations arrive as guest arguments: argv[1] expected argv[0], argv[2] expected preopen name
  ;; of fd 3, argv[3] path to open under fd 3, argv[4] expected contents of that path.
  ;; Exit codes: 1 args_sizes_get, 2 wrong argc, 3 args_get, 4 argv[0] mismatch, 5 fd_prestat_get,
  ;; 6 fd_prestat_dir_name, 7 preopen name mismatch, 8 path_open, 9 fd_read, 10 contents mismatch,
  ;; 11 preopen name too long for its buffer.
  ;; Memory map: 0 iovec, 8 bytes read, 16 argc, 20 argv buffer size, 24 opened fd, 32 prestat,
  ;; 64 argv pointers, 1024 preopen name, 2048 file contents, 4096 argv buffer.

  (func $strlen (param $p i32) (result i32)
    (local $n i32)
    (block $done
      (loop $next
        (br_if $done (i32.eqz (i32.load8_u (i32.add (local.get $p) (local.get $n)))))
        (local.set $n (i32.add (local.get $n) (i32.const 1)))
        (br $next)))
    (local.get $n))

  (func $streq (param $a i32) (param $b i32) (result i32)
    (local $ca i32) (local $cb i32)
    (block $done
      (loop $next
        (local.set $ca (i32.load8_u (local.get $a)))
        (local.set $cb (i32.load8_u (local.get $b)))
        (br_if $done (i32.ne (local.get $ca) (local.get $cb)))
        (if (i32.eqz (local.get $ca)) (then (return (i32.const 1))))
        (local.set $a (i32.add (local.get $a) (i32.const 1)))
        (local.set $b (i32.add (local.get $b) (i32.const 1)))
        (br $next)))
    (i32.const 0))

  (func $argv (param $i i32) (result i32)
    (i32.load (i32.add (i32.const 64) (i32.mul (local.get $i) (i32.const 4)))))

  (func $fail (param $code i32)
    (call $proc_exit (local.get $code))
    (unreachable))

  (func (export "_start")
    (local $len i32) (local $fd i32) (local $nread i32)
    (if (call $args_sizes_get (i32.const 16) (i32.const 20))
      (then (call $fail (i32.const 1))))
    (if (i32.ne (i32.load (i32.const 16)) (i32.const 5))
      (then (call $fail (i32.const 2))))
    (if (call $args_get (i32.const 64) (i32.const 4096))
      (then (call $fail (i32.const 3))))
    (if (i32.eqz (call $streq (call $argv (i32.const 0)) (call $argv (i32.const 1))))
      (then (call $fail (i32.const 4))))
    (if (call $fd_prestat_get (i32.const 3) (i32.const 32))
      (then (call $fail (i32.const 5))))
    (local.set $len (i32.load (i32.const 36)))
    (if (i32.gt_u (local.get $len) (i32.const 1023))
      (then (call $fail (i32.const 11))))
    (if (call $fd_prestat_dir_name (i32.const 3) (i32.const 1024) (local.get $len))
      (then (call $fail (i32.const 6))))
    (i32.store8 (i32.add (i32.const 1024) (local.get $len)) (i32.const 0))
    (if (i32.eqz (call $streq (i32.const 1024) (call $argv (i32.const 2))))
      (then (call $fail (i32.const 7))))
    (if (call $path_open
          (i32.const 3) (i32.const 1)
          (call $argv (i32.const 3)) (call $strlen (call $argv (i32.const 3)))
          (i32.const 0) (i64.const 2) (i64.const 0) (i32.const 0)
          (i32.const 24))
      (then (call $fail (i32.const 8))))
    (local.set $fd (i32.load (i32.const 24)))
    (i32.store (i32.const 0) (i32.const 2048))
    (i32.store (i32.const 4) (i32.const 1023))
    (if (call $fd_read (local.get $fd) (i32.const 0) (i32.const 1) (i32.const 8))
      (then (call $fail (i32.const 9))))
    (local.set $nread (i32.load (i32.const 8)))
    (i32.store8 (i32.add (i32.const 2048) (local.get $nread)) (i32.const 0))
    (if (i32.eqz (call $streq (i32.const 2048) (call $argv (i32.const 4))))
      (then (call $fail (i32.const 10)))))
)
