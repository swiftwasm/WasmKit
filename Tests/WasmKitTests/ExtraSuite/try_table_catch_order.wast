;; A try_table's catch clauses are tried in source order and the first match
;; wins. Once one clause catches, the try_table is gone, so its other clauses
;; must not catch later exceptions either.

(module
  (tag $t)
  (tag $u)

  ;; `catch $t` comes first, so it must win over the `catch_all` after it.
  (func (export "catch-before-catch-all") (result i32)
    (block $all
      (block $h
        (try_table (catch $t $h) (catch_all $all)
          (throw $t))
        (unreachable))
      (return (i32.const 1)))
    (i32.const 2))

  ;; Same as above with the `_ref` forms.
  (func (export "catch-ref-before-catch-all-ref") (result i32)
    (block $all (result exnref)
      (block $h (result exnref)
        (try_table (catch_ref $t $h) (catch_all_ref $all)
          (throw $t))
        (unreachable))
      (drop)
      (return (i32.const 1)))
    (drop)
    (i32.const 2))

  ;; Two clauses for the same tag: the first one wins.
  (func (export "duplicated-catches") (result i32)
    (block $second
      (block $first
        (try_table (catch $t $first) (catch $t $second)
          (throw $t))
        (unreachable))
      (return (i32.const 1)))
    (i32.const 2))

  ;; Clauses that don't match are skipped until one does.
  (func (export "skip-non-matching") (result i32)
    (block $all
      (block $h
        (block $miss
          (try_table (catch $u $miss) (catch $t $h) (catch_all $all)
            (throw $t))
          (unreachable))
        (return (i32.const 0)))
      (return (i32.const 1)))
    (i32.const 2))

  ;; After `catch $t` fires, the `catch_all` of the same try_table is out of
  ;; scope, so the second throw must escape the function.
  (func (export "sibling-clauses-removed")
    (block $all
      (block $h
        (try_table (catch $t $h) (catch_all $all)
          (throw $t))
        (unreachable))
      (throw $u))
    (unreachable))
)

(assert_return (invoke "catch-before-catch-all") (i32.const 1))
(assert_return (invoke "catch-ref-before-catch-all-ref") (i32.const 1))
(assert_return (invoke "duplicated-catches") (i32.const 1))
(assert_return (invoke "skip-non-matching") (i32.const 1))
(assert_exception (invoke "sibling-clauses-removed"))
