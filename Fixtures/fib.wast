(module
 (table 0 anyfunc)
 (memory $0 2)
 (data (i32.const 4) "\10\00\01\00")
 (export "memory" (memory $0))
 (export "fib" (func $fib))
 (func $fib (; 0 ;) (param $0 i32) (result i32)
  (local $1 i32)
  (i32.store offset=4
   (i32.const 0)
   (tee_local $1
    (i32.sub
     (i32.load offset=4
      (i32.const 0)
     )
     (i32.const 16)
    )
   )
  )
  (i32.store offset=8
   (get_local $1)
   (get_local $0)
  )
  (block $label$0
   (block $label$1
    (br_if $label$1
     (i32.gt_s
      (get_local $0)
      (i32.const 1)
     )
    )
    (i32.store offset=12
     (get_local $1)
     (i32.const 1)
    )
    (br $label$0)
   )
   (i32.store offset=12
    (get_local $1)
    (i32.add
     (call $fib
      (i32.add
       (i32.load offset=8
        (get_local $1)
       )
       (i32.const -1)
      )
     )
     (call $fib
      (i32.add
       (i32.load offset=8
        (get_local $1)
       )
       (i32.const -2)
      )
     )
    )
   )
  )
  (set_local $0
   (i32.load offset=12
    (get_local $1)
   )
  )
  (i32.store offset=4
   (i32.const 0)
   (i32.add
    (get_local $1)
    (i32.const 16)
   )
  )
  (get_local $0)
 )
)
