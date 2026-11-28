;; `stream` and `future` types can be declared inside instance and component types.
(component
  (type (instance
    (type $s (stream u8))
    (type (future u32))
    (type (stream))
    (export "s" (type (eq $s)))))
  (type (component
    (type (future))
    (export "f" (type (eq 0))))))
