;; The binary-trees benchmark from the Computer Language Benchmarks Game, with
;; GC structs. `run` builds a long-lived tree of depth `max`, then for each
;; depth d from 4 to `max` in steps of 2 builds and walks 2^(max - d + 4)
;; short-lived trees of depth d, and returns the total number of nodes walked.
(module
  (type $node (struct (field $left (ref null $node)) (field $right (ref null $node))))

  (func $make (param $depth i32) (result (ref $node))
    (if (result (ref $node)) (i32.eqz (local.get $depth))
      (then (struct.new $node (ref.null $node) (ref.null $node)))
      (else
        (struct.new $node
          (call $make (i32.sub (local.get $depth) (i32.const 1)))
          (call $make (i32.sub (local.get $depth) (i32.const 1)))
        )
      )
    )
  )

  (func $check (param $tree (ref null $node)) (result i32)
    (if (result i32) (ref.is_null (struct.get $node $left (local.get $tree)))
      (then (i32.const 1))
      (else
        (i32.add
          (i32.const 1)
          (i32.add
            (call $check (struct.get $node $left (local.get $tree)))
            (call $check (struct.get $node $right (local.get $tree)))
          )
        )
      )
    )
  )

  (func (export "run") (param $max i32) (result i32)
    (local $longLived (ref null $node))
    (local $depth i32)
    (local $iterations i32)
    (local $i i32)
    (local $total i32)
    (local.set $longLived (call $make (local.get $max)))
    (local.set $depth (i32.const 4))
    (block $doneDepths
      (loop $depths
        (br_if $doneDepths (i32.gt_u (local.get $depth) (local.get $max)))
        (local.set $iterations
          (i32.shl (i32.const 1) (i32.add (i32.sub (local.get $max) (local.get $depth)) (i32.const 4))))
        (local.set $i (i32.const 0))
        (block $doneTrees
          (loop $trees
            (br_if $doneTrees (i32.ge_u (local.get $i) (local.get $iterations)))
            (local.set $total (i32.add (local.get $total) (call $check (call $make (local.get $depth)))))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $trees)
          )
        )
        (local.set $depth (i32.add (local.get $depth) (i32.const 2)))
        (br $depths)
      )
    )
    (i32.add (local.get $total) (call $check (local.get $longLived)))
  )
)
