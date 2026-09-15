;; GENERATED FILE, DO NOT EDIT. Regenerate with:
;;   python3 Tests/WasmKitTests/ExtraSuite/select_forms.gen.py > Tests/WasmKitTests/ExtraSuite/select_forms.wast

(module
  (memory 1)
  (data (i32.const 0) "\00\00\00\00\01\00\00\00\ff\ff\ff\ff\05\00\00\00\ff\ff\ff\7f\00\00\00\80\00\01\00\00")
  (global $g (mut i32) (i32.const 0))
  (func $lt_s.i32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (i32.lt_s (local.get $x) (local.get $y)))))
  (func $lt_s.i32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $lt_s.i32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (i32.lt_s (local.get $x) (local.get $y)))))
  (func $lt_s.i32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $lt_s.set_local (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (i32.lt_s (local.get $x) (local.get $y)))) (i64.extend_i32_u (local.get $x)))
  (func $lt_s.set_local.ref (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g))))) (drop (global.get $g)) (i64.extend_i32_u (local.get $x)))
  (func $lt_s.i64.plain (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.lt_s (local.get $x) (local.get $y))))
  (func $lt_s.i64.plain.ref (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g)))))
  (func $lt_s.i64.typed (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.lt_s (local.get $x) (local.get $y))))
  (func $lt_s.i64.typed.ref (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g)))))
  (func $lt_s.f64.plain (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.lt_s (local.get $x) (local.get $y)))))
  (func $lt_s.f64.plain.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $lt_s.f64.typed (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.lt_s (local.get $x) (local.get $y)))))
  (func $lt_s.f64.typed.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $lt_s.f32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.lt_s (local.get $x) (local.get $y))))))
  (func $lt_s.f32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g)))))))
  (func $lt_s.f32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.lt_s (local.get $x) (local.get $y))))))
  (func $lt_s.f32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.lt_s (local.get $x) (local.get $y)) (drop (global.get $g)))))))
  (func $eq.i32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (i32.eq (local.get $x) (local.get $y)))))
  (func $eq.i32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $eq.i32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (i32.eq (local.get $x) (local.get $y)))))
  (func $eq.i32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $eq.set_local (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (i32.eq (local.get $x) (local.get $y)))) (i64.extend_i32_u (local.get $x)))
  (func $eq.set_local.ref (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g))))) (drop (global.get $g)) (i64.extend_i32_u (local.get $x)))
  (func $eq.i64.plain (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.eq (local.get $x) (local.get $y))))
  (func $eq.i64.plain.ref (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g)))))
  (func $eq.i64.typed (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.eq (local.get $x) (local.get $y))))
  (func $eq.i64.typed.ref (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g)))))
  (func $eq.f64.plain (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.eq (local.get $x) (local.get $y)))))
  (func $eq.f64.plain.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $eq.f64.typed (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.eq (local.get $x) (local.get $y)))))
  (func $eq.f64.typed.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $eq.f32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.eq (local.get $x) (local.get $y))))))
  (func $eq.f32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g)))))))
  (func $eq.f32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.eq (local.get $x) (local.get $y))))))
  (func $eq.f32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.eq (local.get $x) (local.get $y)) (drop (global.get $g)))))))
  (func $and.i32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (i32.and (local.get $x) (local.get $y)))))
  (func $and.i32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $and.i32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (i32.and (local.get $x) (local.get $y)))))
  (func $and.i32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $and.set_local (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (i32.and (local.get $x) (local.get $y)))) (i64.extend_i32_u (local.get $x)))
  (func $and.set_local.ref (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g))))) (drop (global.get $g)) (i64.extend_i32_u (local.get $x)))
  (func $and.i64.plain (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.and (local.get $x) (local.get $y))))
  (func $and.i64.plain.ref (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g)))))
  (func $and.i64.typed (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.and (local.get $x) (local.get $y))))
  (func $and.i64.typed.ref (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g)))))
  (func $and.f64.plain (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.and (local.get $x) (local.get $y)))))
  (func $and.f64.plain.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $and.f64.typed (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.and (local.get $x) (local.get $y)))))
  (func $and.f64.typed.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g))))))
  (func $and.f32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.and (local.get $x) (local.get $y))))))
  (func $and.f32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g)))))))
  (func $and.f32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.and (local.get $x) (local.get $y))))))
  (func $and.f32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.and (local.get $x) (local.get $y)) (drop (global.get $g)))))))
  (func $addimm.i32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (i32.add (local.get $x) (i32.const 1)))))
  (func $addimm.i32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g))))))
  (func $addimm.i32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (i32.add (local.get $x) (i32.const 1)))))
  (func $addimm.i32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g))))))
  (func $addimm.set_local (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (i32.add (local.get $x) (i32.const 1)))) (i64.extend_i32_u (local.get $x)))
  (func $addimm.set_local.ref (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g))))) (drop (global.get $g)) (i64.extend_i32_u (local.get $x)))
  (func $addimm.i64.plain (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.add (local.get $x) (i32.const 1))))
  (func $addimm.i64.plain.ref (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g)))))
  (func $addimm.i64.typed (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.add (local.get $x) (i32.const 1))))
  (func $addimm.i64.typed.ref (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g)))))
  (func $addimm.f64.plain (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.add (local.get $x) (i32.const 1)))))
  (func $addimm.f64.plain.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g))))))
  (func $addimm.f64.typed (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.add (local.get $x) (i32.const 1)))))
  (func $addimm.f64.typed.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g))))))
  (func $addimm.f32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.add (local.get $x) (i32.const 1))))))
  (func $addimm.f32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g)))))))
  (func $addimm.f32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.add (local.get $x) (i32.const 1))))))
  (func $addimm.f32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.add (local.get $x) (i32.const 1)) (drop (global.get $g)))))))
  (func $load.i32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (i32.load8_u (i32.and (local.get $x) (i32.const 15))))))
  (func $load.i32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g))))))
  (func $load.i32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (i32.load8_u (i32.and (local.get $x) (i32.const 15))))))
  (func $load.i32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g))))))
  (func $load.set_local (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (i32.load8_u (i32.and (local.get $x) (i32.const 15))))) (i64.extend_i32_u (local.get $x)))
  (func $load.set_local.ref (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g))))) (drop (global.get $g)) (i64.extend_i32_u (local.get $x)))
  (func $load.i64.plain (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.load8_u (i32.and (local.get $x) (i32.const 15)))))
  (func $load.i64.plain.ref (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g)))))
  (func $load.i64.typed (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.load8_u (i32.and (local.get $x) (i32.const 15)))))
  (func $load.i64.typed.ref (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g)))))
  (func $load.f64.plain (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.load8_u (i32.and (local.get $x) (i32.const 15))))))
  (func $load.f64.plain.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g))))))
  (func $load.f64.typed (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.load8_u (i32.and (local.get $x) (i32.const 15))))))
  (func $load.f64.typed.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g))))))
  (func $load.f32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.load8_u (i32.and (local.get $x) (i32.const 15)))))))
  (func $load.f32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g)))))))
  (func $load.f32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.load8_u (i32.and (local.get $x) (i32.const 15)))))))
  (func $load.f32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.load8_u (i32.and (local.get $x) (i32.const 15))) (drop (global.get $g)))))))
  (func $eqz.i32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (i32.eqz (local.get $x)))))
  (func $eqz.i32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (local.get $x) (local.get $y) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g))))))
  (func $eqz.i32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (i32.eqz (local.get $x)))))
  (func $eqz.i32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (select (result i32) (local.get $x) (local.get $y) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g))))))
  (func $eqz.set_local (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (i32.eqz (local.get $x)))) (i64.extend_i32_u (local.get $x)))
  (func $eqz.set_local.ref (param $x i32) (param $y i32) (result i64) (local.set $x (select (local.get $x) (local.get $y) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g))))) (drop (global.get $g)) (i64.extend_i32_u (local.get $x)))
  (func $eqz.i64.plain (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.eqz (local.get $x))))
  (func $eqz.i64.plain.ref (param $x i32) (param $y i32) (result i64) (select (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g)))))
  (func $eqz.i64.typed (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (i32.eqz (local.get $x))))
  (func $eqz.i64.typed.ref (param $x i32) (param $y i32) (result i64) (select (result i64) (i64.extend_i32_s (local.get $x)) (i64.const 77) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g)))))
  (func $eqz.f64.plain (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.eqz (local.get $x)))))
  (func $eqz.f64.plain.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g))))))
  (func $eqz.f64.typed (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (i32.eqz (local.get $x)))))
  (func $eqz.f64.typed.ref (param $x i32) (param $y i32) (result i64) (i64.reinterpret_f64 (select (result f64) (f64.convert_i32_s (local.get $y)) (f64.const 2.5) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g))))))
  (func $eqz.f32.plain (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.eqz (local.get $x))))))
  (func $eqz.f32.plain.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g)))))))
  (func $eqz.f32.typed (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (i32.eqz (local.get $x))))))
  (func $eqz.f32.typed.ref (param $x i32) (param $y i32) (result i64) (i64.extend_i32_u (i32.reinterpret_f32 (select (result f32) (f32.const 1.5) (f32.convert_i32_u (local.get $x)) (block (result i32) (i32.eqz (local.get $x)) (drop (global.get $g)))))))
  (type $f (func (param $x i32) (param $y i32) (result i64)))
  (table funcref (elem $lt_s.i32.plain $lt_s.i32.plain.ref $lt_s.i32.typed $lt_s.i32.typed.ref $lt_s.set_local $lt_s.set_local.ref $lt_s.i64.plain $lt_s.i64.plain.ref $lt_s.i64.typed $lt_s.i64.typed.ref $lt_s.f64.plain $lt_s.f64.plain.ref $lt_s.f64.typed $lt_s.f64.typed.ref $lt_s.f32.plain $lt_s.f32.plain.ref $lt_s.f32.typed $lt_s.f32.typed.ref $eq.i32.plain $eq.i32.plain.ref $eq.i32.typed $eq.i32.typed.ref $eq.set_local $eq.set_local.ref $eq.i64.plain $eq.i64.plain.ref $eq.i64.typed $eq.i64.typed.ref $eq.f64.plain $eq.f64.plain.ref $eq.f64.typed $eq.f64.typed.ref $eq.f32.plain $eq.f32.plain.ref $eq.f32.typed $eq.f32.typed.ref $and.i32.plain $and.i32.plain.ref $and.i32.typed $and.i32.typed.ref $and.set_local $and.set_local.ref $and.i64.plain $and.i64.plain.ref $and.i64.typed $and.i64.typed.ref $and.f64.plain $and.f64.plain.ref $and.f64.typed $and.f64.typed.ref $and.f32.plain $and.f32.plain.ref $and.f32.typed $and.f32.typed.ref $addimm.i32.plain $addimm.i32.plain.ref $addimm.i32.typed $addimm.i32.typed.ref $addimm.set_local $addimm.set_local.ref $addimm.i64.plain $addimm.i64.plain.ref $addimm.i64.typed $addimm.i64.typed.ref $addimm.f64.plain $addimm.f64.plain.ref $addimm.f64.typed $addimm.f64.typed.ref $addimm.f32.plain $addimm.f32.plain.ref $addimm.f32.typed $addimm.f32.typed.ref $load.i32.plain $load.i32.plain.ref $load.i32.typed $load.i32.typed.ref $load.set_local $load.set_local.ref $load.i64.plain $load.i64.plain.ref $load.i64.typed $load.i64.typed.ref $load.f64.plain $load.f64.plain.ref $load.f64.typed $load.f64.typed.ref $load.f32.plain $load.f32.plain.ref $load.f32.typed $load.f32.typed.ref $eqz.i32.plain $eqz.i32.plain.ref $eqz.i32.typed $eqz.i32.typed.ref $eqz.set_local $eqz.set_local.ref $eqz.i64.plain $eqz.i64.plain.ref $eqz.i64.typed $eqz.i64.typed.ref $eqz.f64.plain $eqz.f64.plain.ref $eqz.f64.typed $eqz.f64.typed.ref $eqz.f32.plain $eqz.f32.plain.ref $eqz.f32.typed $eqz.f32.typed.ref))
  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $j i32) (local $n i32) (local $f i32) (local $x i32) (local $y i32)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $li
      (local.set $x (i32.load (i32.mul (local.get $i) (i32.const 4))))
      (local.set $j (i32.const 0))
      (loop $lj
        (local.set $y (i32.load (i32.mul (local.get $j) (i32.const 4))))
        (if (i64.ne (call_indirect (type $f) (local.get $x) (local.get $y) (local.get $f))
                    (call_indirect (type $f) (local.get $x) (local.get $y) (i32.add (local.get $f) (i32.const 1))))
          (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
        (br_if $lj (i32.lt_u (local.tee $j (i32.add (local.get $j) (i32.const 1))) (i32.const 7))))
      (br_if $li (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 7))))
    (local.get $n))
)
(assert_return (invoke "check" (i32.const 0)) (i32.const 0)) ;; lt_s.i32.plain
(assert_return (invoke "check" (i32.const 1)) (i32.const 0)) ;; lt_s.i32.typed
(assert_return (invoke "check" (i32.const 2)) (i32.const 0)) ;; lt_s.set_local
(assert_return (invoke "check" (i32.const 3)) (i32.const 0)) ;; lt_s.i64.plain
(assert_return (invoke "check" (i32.const 4)) (i32.const 0)) ;; lt_s.i64.typed
(assert_return (invoke "check" (i32.const 5)) (i32.const 0)) ;; lt_s.f64.plain
(assert_return (invoke "check" (i32.const 6)) (i32.const 0)) ;; lt_s.f64.typed
(assert_return (invoke "check" (i32.const 7)) (i32.const 0)) ;; lt_s.f32.plain
(assert_return (invoke "check" (i32.const 8)) (i32.const 0)) ;; lt_s.f32.typed
(assert_return (invoke "check" (i32.const 9)) (i32.const 0)) ;; eq.i32.plain
(assert_return (invoke "check" (i32.const 10)) (i32.const 0)) ;; eq.i32.typed
(assert_return (invoke "check" (i32.const 11)) (i32.const 0)) ;; eq.set_local
(assert_return (invoke "check" (i32.const 12)) (i32.const 0)) ;; eq.i64.plain
(assert_return (invoke "check" (i32.const 13)) (i32.const 0)) ;; eq.i64.typed
(assert_return (invoke "check" (i32.const 14)) (i32.const 0)) ;; eq.f64.plain
(assert_return (invoke "check" (i32.const 15)) (i32.const 0)) ;; eq.f64.typed
(assert_return (invoke "check" (i32.const 16)) (i32.const 0)) ;; eq.f32.plain
(assert_return (invoke "check" (i32.const 17)) (i32.const 0)) ;; eq.f32.typed
(assert_return (invoke "check" (i32.const 18)) (i32.const 0)) ;; and.i32.plain
(assert_return (invoke "check" (i32.const 19)) (i32.const 0)) ;; and.i32.typed
(assert_return (invoke "check" (i32.const 20)) (i32.const 0)) ;; and.set_local
(assert_return (invoke "check" (i32.const 21)) (i32.const 0)) ;; and.i64.plain
(assert_return (invoke "check" (i32.const 22)) (i32.const 0)) ;; and.i64.typed
(assert_return (invoke "check" (i32.const 23)) (i32.const 0)) ;; and.f64.plain
(assert_return (invoke "check" (i32.const 24)) (i32.const 0)) ;; and.f64.typed
(assert_return (invoke "check" (i32.const 25)) (i32.const 0)) ;; and.f32.plain
(assert_return (invoke "check" (i32.const 26)) (i32.const 0)) ;; and.f32.typed
(assert_return (invoke "check" (i32.const 27)) (i32.const 0)) ;; addimm.i32.plain
(assert_return (invoke "check" (i32.const 28)) (i32.const 0)) ;; addimm.i32.typed
(assert_return (invoke "check" (i32.const 29)) (i32.const 0)) ;; addimm.set_local
(assert_return (invoke "check" (i32.const 30)) (i32.const 0)) ;; addimm.i64.plain
(assert_return (invoke "check" (i32.const 31)) (i32.const 0)) ;; addimm.i64.typed
(assert_return (invoke "check" (i32.const 32)) (i32.const 0)) ;; addimm.f64.plain
(assert_return (invoke "check" (i32.const 33)) (i32.const 0)) ;; addimm.f64.typed
(assert_return (invoke "check" (i32.const 34)) (i32.const 0)) ;; addimm.f32.plain
(assert_return (invoke "check" (i32.const 35)) (i32.const 0)) ;; addimm.f32.typed
(assert_return (invoke "check" (i32.const 36)) (i32.const 0)) ;; load.i32.plain
(assert_return (invoke "check" (i32.const 37)) (i32.const 0)) ;; load.i32.typed
(assert_return (invoke "check" (i32.const 38)) (i32.const 0)) ;; load.set_local
(assert_return (invoke "check" (i32.const 39)) (i32.const 0)) ;; load.i64.plain
(assert_return (invoke "check" (i32.const 40)) (i32.const 0)) ;; load.i64.typed
(assert_return (invoke "check" (i32.const 41)) (i32.const 0)) ;; load.f64.plain
(assert_return (invoke "check" (i32.const 42)) (i32.const 0)) ;; load.f64.typed
(assert_return (invoke "check" (i32.const 43)) (i32.const 0)) ;; load.f32.plain
(assert_return (invoke "check" (i32.const 44)) (i32.const 0)) ;; load.f32.typed
(assert_return (invoke "check" (i32.const 45)) (i32.const 0)) ;; eqz.i32.plain
(assert_return (invoke "check" (i32.const 46)) (i32.const 0)) ;; eqz.i32.typed
(assert_return (invoke "check" (i32.const 47)) (i32.const 0)) ;; eqz.set_local
(assert_return (invoke "check" (i32.const 48)) (i32.const 0)) ;; eqz.i64.plain
(assert_return (invoke "check" (i32.const 49)) (i32.const 0)) ;; eqz.i64.typed
(assert_return (invoke "check" (i32.const 50)) (i32.const 0)) ;; eqz.f64.plain
(assert_return (invoke "check" (i32.const 51)) (i32.const 0)) ;; eqz.f64.typed
(assert_return (invoke "check" (i32.const 52)) (i32.const 0)) ;; eqz.f32.plain
(assert_return (invoke "check" (i32.const 53)) (i32.const 0)) ;; eqz.f32.typed
