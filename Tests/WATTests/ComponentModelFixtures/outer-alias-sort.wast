;; `alias outer` resolves its target name in the index space of the alias's sort.
;; Each `$x` below sits at index 1 of its own space, except the type `$x`, at index 0.
(component $C
  (core module $pad)
  (core module $x)
  (core type $pad (func))
  (core type $x (func))
  (component $pad)
  (component $x)
  (type $x (func))
  (component
    (alias outer $C $x (core type))
    (alias outer $C $x (core module))
    (alias outer $C $x (component))))
