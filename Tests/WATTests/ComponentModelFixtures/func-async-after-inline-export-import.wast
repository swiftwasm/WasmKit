;; `async` can follow a component function's inline export or import.
(component
  (core module $m (func (export "f") (result i32) unreachable))
  (core instance $i (instantiate $m))
  (alias core export $i "f" (core func $f))
  (func $g (export "g") async (result u32) (canon lift (core func $f)))
  (func $h (import "h") async (result u32))
  (export "h2" (func $h)))
