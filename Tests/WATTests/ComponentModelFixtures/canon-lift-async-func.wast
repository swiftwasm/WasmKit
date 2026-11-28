;; A top-level `canon lift` can give its function an async type.
(component
  (core module $m (func (export "f") (result i32) unreachable))
  (core instance $i (instantiate $m))
  (alias core export $i "f" (core func $f))
  (canon lift (core func $f) (func $g async (result u32)))
  (export "g" (func $g)))
