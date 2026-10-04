;; Objects that nothing refers to any more are collected. The scripts in this
;; directory run with a 16 MiB GC heap, and each function below allocates more
;; than that while keeping a little alive, in a local, on the value stack
;; across a call, in a global and in a table. The live objects move when the
;; heap is compacted, so each reference has to be found and updated.
(module
  (type $node (struct (field $value i32) (field $next (ref null $node))))
  (type $pair (struct (field (ref null $node)) (field (ref null $node))))
  (type $bytes (array (mut i8)))

  (global $saved (mut (ref null $node)) (ref.null $node))
  (table $nodes 1 (ref null $node))

  ;; Allocates `count` arrays of 64 KiB that are garbage right away.
  (func $churn (param $count i32)
    (block $done
      (loop $loop
        (br_if $done (i32.eqz (local.get $count)))
        (drop (array.new_default $bytes (i32.const 65536)))
        (local.set $count (i32.sub (local.get $count) (i32.const 1)))
        (br $loop)
      )
    )
  )

  ;; A list of `n` nodes holding n-1 down to 0, with 64 KiB of garbage per node.
  (func $build (param $n i32) (result (ref null $node))
    (local $list (ref null $node))
    (local $i i32)
    (block $done
      (loop $loop
        (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
        (call $churn (i32.const 1))
        (local.set $list (struct.new $node (local.get $i) (local.get $list)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)
      )
    )
    (local.get $list)
  )

  (func $sum (param $list (ref null $node)) (result i32)
    (local $total i32)
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $list)))
        (local.set $total (i32.add (local.get $total) (struct.get $node $value (local.get $list))))
        (local.set $list (struct.get $node $next (local.get $list)))
        (br $loop)
      )
    )
    (local.get $total)
  )

  ;; 1000 nodes and 64 MiB of garbage: the sum of 0 to 999.
  (func (export "list-in-local") (result i32)
    (call $sum (call $build (i32.const 1000)))
  )

  (func $make (param $value i32) (result (ref $node))
    (call $churn (i32.const 300))
    (struct.new $node (local.get $value) (ref.null $node))
  )
  ;; The first node stays on the value stack while the call collects.
  (func (export "stack-across-call") (result i32)
    (local $pair (ref null $pair))
    (local.set $pair
      (struct.new $pair (struct.new $node (i32.const 7) (ref.null $node)) (call $make (i32.const 35)))
    )
    (i32.add
      (struct.get $node $value (struct.get $pair 0 (local.get $pair)))
      (struct.get $node $value (struct.get $pair 1 (local.get $pair)))
    )
  )

  ;; The host gets a handle to the struct, which has to follow it as it moves.
  (func (export "struct-to-host") (result (ref $node))
    (call $make (i32.const 1))
  )

  (func (export "global-and-table") (result i32)
    (global.set $saved (struct.new $node (i32.const 20) (ref.null $node)))
    (table.set $nodes (i32.const 0) (struct.new $node (i32.const 22) (ref.null $node)))
    (call $churn (i32.const 300))
    (i32.add
      (struct.get $node $value (global.get $saved))
      (struct.get $node $value (table.get $nodes (i32.const 0)))
    )
  )
)

(assert_return (invoke "list-in-local") (i32.const 499500))
(assert_return (invoke "stack-across-call") (i32.const 42))
(assert_return (invoke "global-and-table") (i32.const 42))
(assert_return (invoke "struct-to-host") (ref.struct))
;; The global and the table still hold their objects after later collections.
(assert_return (invoke "list-in-local") (i32.const 499500))
(assert_return (invoke "global-and-table") (i32.const 42))
