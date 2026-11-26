;; `alias outer` inside a core module type accepts a numeric outer count.
(component
  (core type $f (func))
  (core type (module
    (alias outer 1 0 (type))
    (alias outer 1 $f (type))))
  (component
    (core type (module
      (alias outer 2 0 (type))
      (alias outer 2 $f (type))))))
