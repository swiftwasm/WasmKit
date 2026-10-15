;; GENERATED FILE, DO NOT EDIT. Regenerate with:
;;   python3 Tests/WasmKitTests/ExtraSuite/immediate_operands.gen.py > Tests/WasmKitTests/ExtraSuite/immediate_operands.wast

(module
  (memory 1)
  (data (i32.const 0) "\00\00\00\00\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\80\1f\00\00\00\78\56\34\12")
  (global $c0 i32 (i32.const 0))
  (global $c1 i32 (i32.const -1))
  (global $c2 i32 (i32.const -2147483648))
  (global $c3 i32 (i32.const 33))
  (func $add.0.right (param $x i32) (result i32) (i32.add (local.get $x) (i32.const 0)))
  (func $add.0.right.ref (param $x i32) (result i32) (i32.add (local.get $x) (global.get $c0)))
  (func $add.0.left (param $x i32) (result i32) (i32.add (i32.const 0) (local.get $x)))
  (func $add.0.left.ref (param $x i32) (result i32) (i32.add (global.get $c0) (local.get $x)))
  (func $sub.0.right (param $x i32) (result i32) (i32.sub (local.get $x) (i32.const 0)))
  (func $sub.0.right.ref (param $x i32) (result i32) (i32.sub (local.get $x) (global.get $c0)))
  (func $sub.0.left (param $x i32) (result i32) (i32.sub (i32.const 0) (local.get $x)))
  (func $sub.0.left.ref (param $x i32) (result i32) (i32.sub (global.get $c0) (local.get $x)))
  (func $mul.0.right (param $x i32) (result i32) (i32.mul (local.get $x) (i32.const 0)))
  (func $mul.0.right.ref (param $x i32) (result i32) (i32.mul (local.get $x) (global.get $c0)))
  (func $mul.0.left (param $x i32) (result i32) (i32.mul (i32.const 0) (local.get $x)))
  (func $mul.0.left.ref (param $x i32) (result i32) (i32.mul (global.get $c0) (local.get $x)))
  (func $and.0.right (param $x i32) (result i32) (i32.and (local.get $x) (i32.const 0)))
  (func $and.0.right.ref (param $x i32) (result i32) (i32.and (local.get $x) (global.get $c0)))
  (func $and.0.left (param $x i32) (result i32) (i32.and (i32.const 0) (local.get $x)))
  (func $and.0.left.ref (param $x i32) (result i32) (i32.and (global.get $c0) (local.get $x)))
  (func $or.0.right (param $x i32) (result i32) (i32.or (local.get $x) (i32.const 0)))
  (func $or.0.right.ref (param $x i32) (result i32) (i32.or (local.get $x) (global.get $c0)))
  (func $or.0.left (param $x i32) (result i32) (i32.or (i32.const 0) (local.get $x)))
  (func $or.0.left.ref (param $x i32) (result i32) (i32.or (global.get $c0) (local.get $x)))
  (func $xor.0.right (param $x i32) (result i32) (i32.xor (local.get $x) (i32.const 0)))
  (func $xor.0.right.ref (param $x i32) (result i32) (i32.xor (local.get $x) (global.get $c0)))
  (func $xor.0.left (param $x i32) (result i32) (i32.xor (i32.const 0) (local.get $x)))
  (func $xor.0.left.ref (param $x i32) (result i32) (i32.xor (global.get $c0) (local.get $x)))
  (func $shl.0.right (param $x i32) (result i32) (i32.shl (local.get $x) (i32.const 0)))
  (func $shl.0.right.ref (param $x i32) (result i32) (i32.shl (local.get $x) (global.get $c0)))
  (func $shl.0.left (param $x i32) (result i32) (i32.shl (i32.const 0) (local.get $x)))
  (func $shl.0.left.ref (param $x i32) (result i32) (i32.shl (global.get $c0) (local.get $x)))
  (func $shr_s.0.right (param $x i32) (result i32) (i32.shr_s (local.get $x) (i32.const 0)))
  (func $shr_s.0.right.ref (param $x i32) (result i32) (i32.shr_s (local.get $x) (global.get $c0)))
  (func $shr_s.0.left (param $x i32) (result i32) (i32.shr_s (i32.const 0) (local.get $x)))
  (func $shr_s.0.left.ref (param $x i32) (result i32) (i32.shr_s (global.get $c0) (local.get $x)))
  (func $shr_u.0.right (param $x i32) (result i32) (i32.shr_u (local.get $x) (i32.const 0)))
  (func $shr_u.0.right.ref (param $x i32) (result i32) (i32.shr_u (local.get $x) (global.get $c0)))
  (func $shr_u.0.left (param $x i32) (result i32) (i32.shr_u (i32.const 0) (local.get $x)))
  (func $shr_u.0.left.ref (param $x i32) (result i32) (i32.shr_u (global.get $c0) (local.get $x)))
  (func $rotl.0.right (param $x i32) (result i32) (i32.rotl (local.get $x) (i32.const 0)))
  (func $rotl.0.right.ref (param $x i32) (result i32) (i32.rotl (local.get $x) (global.get $c0)))
  (func $rotl.0.left (param $x i32) (result i32) (i32.rotl (i32.const 0) (local.get $x)))
  (func $rotl.0.left.ref (param $x i32) (result i32) (i32.rotl (global.get $c0) (local.get $x)))
  (func $rotr.0.right (param $x i32) (result i32) (i32.rotr (local.get $x) (i32.const 0)))
  (func $rotr.0.right.ref (param $x i32) (result i32) (i32.rotr (local.get $x) (global.get $c0)))
  (func $rotr.0.left (param $x i32) (result i32) (i32.rotr (i32.const 0) (local.get $x)))
  (func $rotr.0.left.ref (param $x i32) (result i32) (i32.rotr (global.get $c0) (local.get $x)))
  (func $eq.0.right (param $x i32) (result i32) (i32.eq (local.get $x) (i32.const 0)))
  (func $eq.0.right.ref (param $x i32) (result i32) (i32.eq (local.get $x) (global.get $c0)))
  (func $eq.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.eq (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $eq.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.right.if (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.eq (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $eq.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left (param $x i32) (result i32) (i32.eq (i32.const 0) (local.get $x)))
  (func $eq.0.left.ref (param $x i32) (result i32) (i32.eq (global.get $c0) (local.get $x)))
  (func $eq.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.eq (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $eq.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left.if (param $x i32) (result i32) (if (result i32) (i32.eq (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.eq (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $eq.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.eq (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right (param $x i32) (result i32) (i32.ne (local.get $x) (i32.const 0)))
  (func $ne.0.right.ref (param $x i32) (result i32) (i32.ne (local.get $x) (global.get $c0)))
  (func $ne.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ne (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $ne.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right.if (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.ne (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ne.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left (param $x i32) (result i32) (i32.ne (i32.const 0) (local.get $x)))
  (func $ne.0.left.ref (param $x i32) (result i32) (i32.ne (global.get $c0) (local.get $x)))
  (func $ne.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ne (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $ne.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left.if (param $x i32) (result i32) (if (result i32) (i32.ne (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.ne (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ne.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.ne (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right (param $x i32) (result i32) (i32.lt_s (local.get $x) (i32.const 0)))
  (func $lt_s.0.right.ref (param $x i32) (result i32) (i32.lt_s (local.get $x) (global.get $c0)))
  (func $lt_s.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_s (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.lt_s (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_s.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left (param $x i32) (result i32) (i32.lt_s (i32.const 0) (local.get $x)))
  (func $lt_s.0.left.ref (param $x i32) (result i32) (i32.lt_s (global.get $c0) (local.get $x)))
  (func $lt_s.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_s (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left.if (param $x i32) (result i32) (if (result i32) (i32.lt_s (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.lt_s (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_s.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right (param $x i32) (result i32) (i32.lt_u (local.get $x) (i32.const 0)))
  (func $lt_u.0.right.ref (param $x i32) (result i32) (i32.lt_u (local.get $x) (global.get $c0)))
  (func $lt_u.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_u (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.lt_u (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_u.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left (param $x i32) (result i32) (i32.lt_u (i32.const 0) (local.get $x)))
  (func $lt_u.0.left.ref (param $x i32) (result i32) (i32.lt_u (global.get $c0) (local.get $x)))
  (func $lt_u.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_u (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left.if (param $x i32) (result i32) (if (result i32) (i32.lt_u (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.lt_u (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_u.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right (param $x i32) (result i32) (i32.gt_s (local.get $x) (i32.const 0)))
  (func $gt_s.0.right.ref (param $x i32) (result i32) (i32.gt_s (local.get $x) (global.get $c0)))
  (func $gt_s.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_s (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.gt_s (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_s.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left (param $x i32) (result i32) (i32.gt_s (i32.const 0) (local.get $x)))
  (func $gt_s.0.left.ref (param $x i32) (result i32) (i32.gt_s (global.get $c0) (local.get $x)))
  (func $gt_s.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_s (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left.if (param $x i32) (result i32) (if (result i32) (i32.gt_s (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.gt_s (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_s.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right (param $x i32) (result i32) (i32.gt_u (local.get $x) (i32.const 0)))
  (func $gt_u.0.right.ref (param $x i32) (result i32) (i32.gt_u (local.get $x) (global.get $c0)))
  (func $gt_u.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_u (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.gt_u (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_u.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left (param $x i32) (result i32) (i32.gt_u (i32.const 0) (local.get $x)))
  (func $gt_u.0.left.ref (param $x i32) (result i32) (i32.gt_u (global.get $c0) (local.get $x)))
  (func $gt_u.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_u (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left.if (param $x i32) (result i32) (if (result i32) (i32.gt_u (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.gt_u (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_u.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right (param $x i32) (result i32) (i32.le_s (local.get $x) (i32.const 0)))
  (func $le_s.0.right.ref (param $x i32) (result i32) (i32.le_s (local.get $x) (global.get $c0)))
  (func $le_s.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_s (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right.if (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.le_s (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_s.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left (param $x i32) (result i32) (i32.le_s (i32.const 0) (local.get $x)))
  (func $le_s.0.left.ref (param $x i32) (result i32) (i32.le_s (global.get $c0) (local.get $x)))
  (func $le_s.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_s (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left.if (param $x i32) (result i32) (if (result i32) (i32.le_s (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.le_s (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_s.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right (param $x i32) (result i32) (i32.le_u (local.get $x) (i32.const 0)))
  (func $le_u.0.right.ref (param $x i32) (result i32) (i32.le_u (local.get $x) (global.get $c0)))
  (func $le_u.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_u (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right.if (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.le_u (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_u.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left (param $x i32) (result i32) (i32.le_u (i32.const 0) (local.get $x)))
  (func $le_u.0.left.ref (param $x i32) (result i32) (i32.le_u (global.get $c0) (local.get $x)))
  (func $le_u.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_u (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left.if (param $x i32) (result i32) (if (result i32) (i32.le_u (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.le_u (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_u.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right (param $x i32) (result i32) (i32.ge_s (local.get $x) (i32.const 0)))
  (func $ge_s.0.right.ref (param $x i32) (result i32) (i32.ge_s (local.get $x) (global.get $c0)))
  (func $ge_s.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_s (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.ge_s (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_s.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left (param $x i32) (result i32) (i32.ge_s (i32.const 0) (local.get $x)))
  (func $ge_s.0.left.ref (param $x i32) (result i32) (i32.ge_s (global.get $c0) (local.get $x)))
  (func $ge_s.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_s (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left.if (param $x i32) (result i32) (if (result i32) (i32.ge_s (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.ge_s (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_s.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right (param $x i32) (result i32) (i32.ge_u (local.get $x) (i32.const 0)))
  (func $ge_u.0.right.ref (param $x i32) (result i32) (i32.ge_u (local.get $x) (global.get $c0)))
  (func $ge_u.0.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_u (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.0.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.ge_u (local.get $x) (i32.const 0))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_u.0.right.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left (param $x i32) (result i32) (i32.ge_u (i32.const 0) (local.get $x)))
  (func $ge_u.0.left.ref (param $x i32) (result i32) (i32.ge_u (global.get $c0) (local.get $x)))
  (func $ge_u.0.left.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_u (i32.const 0) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.0.left.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left.if (param $x i32) (result i32) (if (result i32) (i32.ge_u (i32.const 0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left.eqz (param $x i32) (result i32) (if (result i32) (i32.eqz (i32.ge_u (i32.const 0) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_u.0.left.eqz.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.0.br_if (param $x i32) (result i32) (block (br_if 0 (i32.and (local.get $x) (i32.const 0))) (return (i32.const 7))) (i32.const 9))
  (func $and.0.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c0)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.0.br_if_not (param $x i32) (result i32) (if (result i32) (i32.and (local.get $x) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.0.br_if_not.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c0)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.0 (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (i32.const 0)) (local.get $x)))
  (func $acc.0.ref (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (global.get $c0)) (local.get $x)))
  (func $super.0 (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (i32.const 0)) (local.get $x)))
  (func $super.0.ref (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (global.get $c0)) (local.get $x)))
  (func $super.sub.0 (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (i32.const 0)) (local.get $x)))
  (func $super.sub.0.ref (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (global.get $c0)) (local.get $x)))
  (func $add.1.right (param $x i32) (result i32) (i32.add (local.get $x) (i32.const -1)))
  (func $add.1.right.ref (param $x i32) (result i32) (i32.add (local.get $x) (global.get $c1)))
  (func $add.1.left (param $x i32) (result i32) (i32.add (i32.const -1) (local.get $x)))
  (func $add.1.left.ref (param $x i32) (result i32) (i32.add (global.get $c1) (local.get $x)))
  (func $sub.1.right (param $x i32) (result i32) (i32.sub (local.get $x) (i32.const -1)))
  (func $sub.1.right.ref (param $x i32) (result i32) (i32.sub (local.get $x) (global.get $c1)))
  (func $sub.1.left (param $x i32) (result i32) (i32.sub (i32.const -1) (local.get $x)))
  (func $sub.1.left.ref (param $x i32) (result i32) (i32.sub (global.get $c1) (local.get $x)))
  (func $mul.1.right (param $x i32) (result i32) (i32.mul (local.get $x) (i32.const -1)))
  (func $mul.1.right.ref (param $x i32) (result i32) (i32.mul (local.get $x) (global.get $c1)))
  (func $mul.1.left (param $x i32) (result i32) (i32.mul (i32.const -1) (local.get $x)))
  (func $mul.1.left.ref (param $x i32) (result i32) (i32.mul (global.get $c1) (local.get $x)))
  (func $and.1.right (param $x i32) (result i32) (i32.and (local.get $x) (i32.const -1)))
  (func $and.1.right.ref (param $x i32) (result i32) (i32.and (local.get $x) (global.get $c1)))
  (func $and.1.left (param $x i32) (result i32) (i32.and (i32.const -1) (local.get $x)))
  (func $and.1.left.ref (param $x i32) (result i32) (i32.and (global.get $c1) (local.get $x)))
  (func $or.1.right (param $x i32) (result i32) (i32.or (local.get $x) (i32.const -1)))
  (func $or.1.right.ref (param $x i32) (result i32) (i32.or (local.get $x) (global.get $c1)))
  (func $or.1.left (param $x i32) (result i32) (i32.or (i32.const -1) (local.get $x)))
  (func $or.1.left.ref (param $x i32) (result i32) (i32.or (global.get $c1) (local.get $x)))
  (func $xor.1.right (param $x i32) (result i32) (i32.xor (local.get $x) (i32.const -1)))
  (func $xor.1.right.ref (param $x i32) (result i32) (i32.xor (local.get $x) (global.get $c1)))
  (func $xor.1.left (param $x i32) (result i32) (i32.xor (i32.const -1) (local.get $x)))
  (func $xor.1.left.ref (param $x i32) (result i32) (i32.xor (global.get $c1) (local.get $x)))
  (func $shl.1.right (param $x i32) (result i32) (i32.shl (local.get $x) (i32.const -1)))
  (func $shl.1.right.ref (param $x i32) (result i32) (i32.shl (local.get $x) (global.get $c1)))
  (func $shl.1.left (param $x i32) (result i32) (i32.shl (i32.const -1) (local.get $x)))
  (func $shl.1.left.ref (param $x i32) (result i32) (i32.shl (global.get $c1) (local.get $x)))
  (func $shr_s.1.right (param $x i32) (result i32) (i32.shr_s (local.get $x) (i32.const -1)))
  (func $shr_s.1.right.ref (param $x i32) (result i32) (i32.shr_s (local.get $x) (global.get $c1)))
  (func $shr_s.1.left (param $x i32) (result i32) (i32.shr_s (i32.const -1) (local.get $x)))
  (func $shr_s.1.left.ref (param $x i32) (result i32) (i32.shr_s (global.get $c1) (local.get $x)))
  (func $shr_u.1.right (param $x i32) (result i32) (i32.shr_u (local.get $x) (i32.const -1)))
  (func $shr_u.1.right.ref (param $x i32) (result i32) (i32.shr_u (local.get $x) (global.get $c1)))
  (func $shr_u.1.left (param $x i32) (result i32) (i32.shr_u (i32.const -1) (local.get $x)))
  (func $shr_u.1.left.ref (param $x i32) (result i32) (i32.shr_u (global.get $c1) (local.get $x)))
  (func $rotl.1.right (param $x i32) (result i32) (i32.rotl (local.get $x) (i32.const -1)))
  (func $rotl.1.right.ref (param $x i32) (result i32) (i32.rotl (local.get $x) (global.get $c1)))
  (func $rotl.1.left (param $x i32) (result i32) (i32.rotl (i32.const -1) (local.get $x)))
  (func $rotl.1.left.ref (param $x i32) (result i32) (i32.rotl (global.get $c1) (local.get $x)))
  (func $rotr.1.right (param $x i32) (result i32) (i32.rotr (local.get $x) (i32.const -1)))
  (func $rotr.1.right.ref (param $x i32) (result i32) (i32.rotr (local.get $x) (global.get $c1)))
  (func $rotr.1.left (param $x i32) (result i32) (i32.rotr (i32.const -1) (local.get $x)))
  (func $rotr.1.left.ref (param $x i32) (result i32) (i32.rotr (global.get $c1) (local.get $x)))
  (func $eq.1.right (param $x i32) (result i32) (i32.eq (local.get $x) (i32.const -1)))
  (func $eq.1.right.ref (param $x i32) (result i32) (i32.eq (local.get $x) (global.get $c1)))
  (func $eq.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.eq (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $eq.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.1.right.if (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.1.right (param $x i32) (result i32) (i32.ne (local.get $x) (i32.const -1)))
  (func $ne.1.right.ref (param $x i32) (result i32) (i32.ne (local.get $x) (global.get $c1)))
  (func $ne.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ne (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $ne.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.1.right.if (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.1.right (param $x i32) (result i32) (i32.lt_s (local.get $x) (i32.const -1)))
  (func $lt_s.1.right.ref (param $x i32) (result i32) (i32.lt_s (local.get $x) (global.get $c1)))
  (func $lt_s.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_s (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.1.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.1.right (param $x i32) (result i32) (i32.lt_u (local.get $x) (i32.const -1)))
  (func $lt_u.1.right.ref (param $x i32) (result i32) (i32.lt_u (local.get $x) (global.get $c1)))
  (func $lt_u.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_u (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.1.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.1.right (param $x i32) (result i32) (i32.gt_s (local.get $x) (i32.const -1)))
  (func $gt_s.1.right.ref (param $x i32) (result i32) (i32.gt_s (local.get $x) (global.get $c1)))
  (func $gt_s.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_s (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.1.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.1.right (param $x i32) (result i32) (i32.gt_u (local.get $x) (i32.const -1)))
  (func $gt_u.1.right.ref (param $x i32) (result i32) (i32.gt_u (local.get $x) (global.get $c1)))
  (func $gt_u.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_u (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.1.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.1.right (param $x i32) (result i32) (i32.le_s (local.get $x) (i32.const -1)))
  (func $le_s.1.right.ref (param $x i32) (result i32) (i32.le_s (local.get $x) (global.get $c1)))
  (func $le_s.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_s (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.1.right.if (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.1.right (param $x i32) (result i32) (i32.le_u (local.get $x) (i32.const -1)))
  (func $le_u.1.right.ref (param $x i32) (result i32) (i32.le_u (local.get $x) (global.get $c1)))
  (func $le_u.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_u (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.1.right.if (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.1.right (param $x i32) (result i32) (i32.ge_s (local.get $x) (i32.const -1)))
  (func $ge_s.1.right.ref (param $x i32) (result i32) (i32.ge_s (local.get $x) (global.get $c1)))
  (func $ge_s.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_s (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.1.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.1.right (param $x i32) (result i32) (i32.ge_u (local.get $x) (i32.const -1)))
  (func $ge_u.1.right.ref (param $x i32) (result i32) (i32.ge_u (local.get $x) (global.get $c1)))
  (func $ge_u.1.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_u (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.1.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.1.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.1.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.1.br_if (param $x i32) (result i32) (block (br_if 0 (i32.and (local.get $x) (i32.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $and.1.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c1)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.1.br_if_not (param $x i32) (result i32) (if (result i32) (i32.and (local.get $x) (i32.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.1.br_if_not.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c1)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.1 (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (i32.const -1)) (local.get $x)))
  (func $acc.1.ref (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (global.get $c1)) (local.get $x)))
  (func $super.1 (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (i32.const -1)) (local.get $x)))
  (func $super.1.ref (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (global.get $c1)) (local.get $x)))
  (func $super.sub.1 (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (i32.const -1)) (local.get $x)))
  (func $super.sub.1.ref (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (global.get $c1)) (local.get $x)))
  (func $add.2.right (param $x i32) (result i32) (i32.add (local.get $x) (i32.const -2147483648)))
  (func $add.2.right.ref (param $x i32) (result i32) (i32.add (local.get $x) (global.get $c2)))
  (func $add.2.left (param $x i32) (result i32) (i32.add (i32.const -2147483648) (local.get $x)))
  (func $add.2.left.ref (param $x i32) (result i32) (i32.add (global.get $c2) (local.get $x)))
  (func $sub.2.right (param $x i32) (result i32) (i32.sub (local.get $x) (i32.const -2147483648)))
  (func $sub.2.right.ref (param $x i32) (result i32) (i32.sub (local.get $x) (global.get $c2)))
  (func $sub.2.left (param $x i32) (result i32) (i32.sub (i32.const -2147483648) (local.get $x)))
  (func $sub.2.left.ref (param $x i32) (result i32) (i32.sub (global.get $c2) (local.get $x)))
  (func $mul.2.right (param $x i32) (result i32) (i32.mul (local.get $x) (i32.const -2147483648)))
  (func $mul.2.right.ref (param $x i32) (result i32) (i32.mul (local.get $x) (global.get $c2)))
  (func $mul.2.left (param $x i32) (result i32) (i32.mul (i32.const -2147483648) (local.get $x)))
  (func $mul.2.left.ref (param $x i32) (result i32) (i32.mul (global.get $c2) (local.get $x)))
  (func $and.2.right (param $x i32) (result i32) (i32.and (local.get $x) (i32.const -2147483648)))
  (func $and.2.right.ref (param $x i32) (result i32) (i32.and (local.get $x) (global.get $c2)))
  (func $and.2.left (param $x i32) (result i32) (i32.and (i32.const -2147483648) (local.get $x)))
  (func $and.2.left.ref (param $x i32) (result i32) (i32.and (global.get $c2) (local.get $x)))
  (func $or.2.right (param $x i32) (result i32) (i32.or (local.get $x) (i32.const -2147483648)))
  (func $or.2.right.ref (param $x i32) (result i32) (i32.or (local.get $x) (global.get $c2)))
  (func $or.2.left (param $x i32) (result i32) (i32.or (i32.const -2147483648) (local.get $x)))
  (func $or.2.left.ref (param $x i32) (result i32) (i32.or (global.get $c2) (local.get $x)))
  (func $xor.2.right (param $x i32) (result i32) (i32.xor (local.get $x) (i32.const -2147483648)))
  (func $xor.2.right.ref (param $x i32) (result i32) (i32.xor (local.get $x) (global.get $c2)))
  (func $xor.2.left (param $x i32) (result i32) (i32.xor (i32.const -2147483648) (local.get $x)))
  (func $xor.2.left.ref (param $x i32) (result i32) (i32.xor (global.get $c2) (local.get $x)))
  (func $shl.2.right (param $x i32) (result i32) (i32.shl (local.get $x) (i32.const -2147483648)))
  (func $shl.2.right.ref (param $x i32) (result i32) (i32.shl (local.get $x) (global.get $c2)))
  (func $shl.2.left (param $x i32) (result i32) (i32.shl (i32.const -2147483648) (local.get $x)))
  (func $shl.2.left.ref (param $x i32) (result i32) (i32.shl (global.get $c2) (local.get $x)))
  (func $shr_s.2.right (param $x i32) (result i32) (i32.shr_s (local.get $x) (i32.const -2147483648)))
  (func $shr_s.2.right.ref (param $x i32) (result i32) (i32.shr_s (local.get $x) (global.get $c2)))
  (func $shr_s.2.left (param $x i32) (result i32) (i32.shr_s (i32.const -2147483648) (local.get $x)))
  (func $shr_s.2.left.ref (param $x i32) (result i32) (i32.shr_s (global.get $c2) (local.get $x)))
  (func $shr_u.2.right (param $x i32) (result i32) (i32.shr_u (local.get $x) (i32.const -2147483648)))
  (func $shr_u.2.right.ref (param $x i32) (result i32) (i32.shr_u (local.get $x) (global.get $c2)))
  (func $shr_u.2.left (param $x i32) (result i32) (i32.shr_u (i32.const -2147483648) (local.get $x)))
  (func $shr_u.2.left.ref (param $x i32) (result i32) (i32.shr_u (global.get $c2) (local.get $x)))
  (func $rotl.2.right (param $x i32) (result i32) (i32.rotl (local.get $x) (i32.const -2147483648)))
  (func $rotl.2.right.ref (param $x i32) (result i32) (i32.rotl (local.get $x) (global.get $c2)))
  (func $rotl.2.left (param $x i32) (result i32) (i32.rotl (i32.const -2147483648) (local.get $x)))
  (func $rotl.2.left.ref (param $x i32) (result i32) (i32.rotl (global.get $c2) (local.get $x)))
  (func $rotr.2.right (param $x i32) (result i32) (i32.rotr (local.get $x) (i32.const -2147483648)))
  (func $rotr.2.right.ref (param $x i32) (result i32) (i32.rotr (local.get $x) (global.get $c2)))
  (func $rotr.2.left (param $x i32) (result i32) (i32.rotr (i32.const -2147483648) (local.get $x)))
  (func $rotr.2.left.ref (param $x i32) (result i32) (i32.rotr (global.get $c2) (local.get $x)))
  (func $eq.2.right (param $x i32) (result i32) (i32.eq (local.get $x) (i32.const -2147483648)))
  (func $eq.2.right.ref (param $x i32) (result i32) (i32.eq (local.get $x) (global.get $c2)))
  (func $eq.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.eq (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $eq.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.2.right.if (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.2.right (param $x i32) (result i32) (i32.ne (local.get $x) (i32.const -2147483648)))
  (func $ne.2.right.ref (param $x i32) (result i32) (i32.ne (local.get $x) (global.get $c2)))
  (func $ne.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ne (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ne.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.2.right.if (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.2.right (param $x i32) (result i32) (i32.lt_s (local.get $x) (i32.const -2147483648)))
  (func $lt_s.2.right.ref (param $x i32) (result i32) (i32.lt_s (local.get $x) (global.get $c2)))
  (func $lt_s.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_s (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.2.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.2.right (param $x i32) (result i32) (i32.lt_u (local.get $x) (i32.const -2147483648)))
  (func $lt_u.2.right.ref (param $x i32) (result i32) (i32.lt_u (local.get $x) (global.get $c2)))
  (func $lt_u.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_u (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.2.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.2.right (param $x i32) (result i32) (i32.gt_s (local.get $x) (i32.const -2147483648)))
  (func $gt_s.2.right.ref (param $x i32) (result i32) (i32.gt_s (local.get $x) (global.get $c2)))
  (func $gt_s.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_s (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.2.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.2.right (param $x i32) (result i32) (i32.gt_u (local.get $x) (i32.const -2147483648)))
  (func $gt_u.2.right.ref (param $x i32) (result i32) (i32.gt_u (local.get $x) (global.get $c2)))
  (func $gt_u.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_u (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.2.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.2.right (param $x i32) (result i32) (i32.le_s (local.get $x) (i32.const -2147483648)))
  (func $le_s.2.right.ref (param $x i32) (result i32) (i32.le_s (local.get $x) (global.get $c2)))
  (func $le_s.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_s (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.2.right.if (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.2.right (param $x i32) (result i32) (i32.le_u (local.get $x) (i32.const -2147483648)))
  (func $le_u.2.right.ref (param $x i32) (result i32) (i32.le_u (local.get $x) (global.get $c2)))
  (func $le_u.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_u (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.2.right.if (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.2.right (param $x i32) (result i32) (i32.ge_s (local.get $x) (i32.const -2147483648)))
  (func $ge_s.2.right.ref (param $x i32) (result i32) (i32.ge_s (local.get $x) (global.get $c2)))
  (func $ge_s.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_s (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.2.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.2.right (param $x i32) (result i32) (i32.ge_u (local.get $x) (i32.const -2147483648)))
  (func $ge_u.2.right.ref (param $x i32) (result i32) (i32.ge_u (local.get $x) (global.get $c2)))
  (func $ge_u.2.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_u (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.2.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.2.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.2.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.2.br_if (param $x i32) (result i32) (block (br_if 0 (i32.and (local.get $x) (i32.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $and.2.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c2)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.2.br_if_not (param $x i32) (result i32) (if (result i32) (i32.and (local.get $x) (i32.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.2.br_if_not.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c2)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.2 (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (i32.const -2147483648)) (local.get $x)))
  (func $acc.2.ref (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (global.get $c2)) (local.get $x)))
  (func $super.2 (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (i32.const -2147483648)) (local.get $x)))
  (func $super.2.ref (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (global.get $c2)) (local.get $x)))
  (func $super.sub.2 (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (i32.const -2147483648)) (local.get $x)))
  (func $super.sub.2.ref (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (global.get $c2)) (local.get $x)))
  (func $add.3.right (param $x i32) (result i32) (i32.add (local.get $x) (i32.const 33)))
  (func $add.3.right.ref (param $x i32) (result i32) (i32.add (local.get $x) (global.get $c3)))
  (func $add.3.left (param $x i32) (result i32) (i32.add (i32.const 33) (local.get $x)))
  (func $add.3.left.ref (param $x i32) (result i32) (i32.add (global.get $c3) (local.get $x)))
  (func $sub.3.right (param $x i32) (result i32) (i32.sub (local.get $x) (i32.const 33)))
  (func $sub.3.right.ref (param $x i32) (result i32) (i32.sub (local.get $x) (global.get $c3)))
  (func $sub.3.left (param $x i32) (result i32) (i32.sub (i32.const 33) (local.get $x)))
  (func $sub.3.left.ref (param $x i32) (result i32) (i32.sub (global.get $c3) (local.get $x)))
  (func $mul.3.right (param $x i32) (result i32) (i32.mul (local.get $x) (i32.const 33)))
  (func $mul.3.right.ref (param $x i32) (result i32) (i32.mul (local.get $x) (global.get $c3)))
  (func $mul.3.left (param $x i32) (result i32) (i32.mul (i32.const 33) (local.get $x)))
  (func $mul.3.left.ref (param $x i32) (result i32) (i32.mul (global.get $c3) (local.get $x)))
  (func $and.3.right (param $x i32) (result i32) (i32.and (local.get $x) (i32.const 33)))
  (func $and.3.right.ref (param $x i32) (result i32) (i32.and (local.get $x) (global.get $c3)))
  (func $and.3.left (param $x i32) (result i32) (i32.and (i32.const 33) (local.get $x)))
  (func $and.3.left.ref (param $x i32) (result i32) (i32.and (global.get $c3) (local.get $x)))
  (func $or.3.right (param $x i32) (result i32) (i32.or (local.get $x) (i32.const 33)))
  (func $or.3.right.ref (param $x i32) (result i32) (i32.or (local.get $x) (global.get $c3)))
  (func $or.3.left (param $x i32) (result i32) (i32.or (i32.const 33) (local.get $x)))
  (func $or.3.left.ref (param $x i32) (result i32) (i32.or (global.get $c3) (local.get $x)))
  (func $xor.3.right (param $x i32) (result i32) (i32.xor (local.get $x) (i32.const 33)))
  (func $xor.3.right.ref (param $x i32) (result i32) (i32.xor (local.get $x) (global.get $c3)))
  (func $xor.3.left (param $x i32) (result i32) (i32.xor (i32.const 33) (local.get $x)))
  (func $xor.3.left.ref (param $x i32) (result i32) (i32.xor (global.get $c3) (local.get $x)))
  (func $shl.3.right (param $x i32) (result i32) (i32.shl (local.get $x) (i32.const 33)))
  (func $shl.3.right.ref (param $x i32) (result i32) (i32.shl (local.get $x) (global.get $c3)))
  (func $shl.3.left (param $x i32) (result i32) (i32.shl (i32.const 33) (local.get $x)))
  (func $shl.3.left.ref (param $x i32) (result i32) (i32.shl (global.get $c3) (local.get $x)))
  (func $shr_s.3.right (param $x i32) (result i32) (i32.shr_s (local.get $x) (i32.const 33)))
  (func $shr_s.3.right.ref (param $x i32) (result i32) (i32.shr_s (local.get $x) (global.get $c3)))
  (func $shr_s.3.left (param $x i32) (result i32) (i32.shr_s (i32.const 33) (local.get $x)))
  (func $shr_s.3.left.ref (param $x i32) (result i32) (i32.shr_s (global.get $c3) (local.get $x)))
  (func $shr_u.3.right (param $x i32) (result i32) (i32.shr_u (local.get $x) (i32.const 33)))
  (func $shr_u.3.right.ref (param $x i32) (result i32) (i32.shr_u (local.get $x) (global.get $c3)))
  (func $shr_u.3.left (param $x i32) (result i32) (i32.shr_u (i32.const 33) (local.get $x)))
  (func $shr_u.3.left.ref (param $x i32) (result i32) (i32.shr_u (global.get $c3) (local.get $x)))
  (func $rotl.3.right (param $x i32) (result i32) (i32.rotl (local.get $x) (i32.const 33)))
  (func $rotl.3.right.ref (param $x i32) (result i32) (i32.rotl (local.get $x) (global.get $c3)))
  (func $rotl.3.left (param $x i32) (result i32) (i32.rotl (i32.const 33) (local.get $x)))
  (func $rotl.3.left.ref (param $x i32) (result i32) (i32.rotl (global.get $c3) (local.get $x)))
  (func $rotr.3.right (param $x i32) (result i32) (i32.rotr (local.get $x) (i32.const 33)))
  (func $rotr.3.right.ref (param $x i32) (result i32) (i32.rotr (local.get $x) (global.get $c3)))
  (func $rotr.3.left (param $x i32) (result i32) (i32.rotr (i32.const 33) (local.get $x)))
  (func $rotr.3.left.ref (param $x i32) (result i32) (i32.rotr (global.get $c3) (local.get $x)))
  (func $eq.3.right (param $x i32) (result i32) (i32.eq (local.get $x) (i32.const 33)))
  (func $eq.3.right.ref (param $x i32) (result i32) (i32.eq (local.get $x) (global.get $c3)))
  (func $eq.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.eq (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $eq.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.3.right.if (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.eq (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.3.right (param $x i32) (result i32) (i32.ne (local.get $x) (i32.const 33)))
  (func $ne.3.right.ref (param $x i32) (result i32) (i32.ne (local.get $x) (global.get $c3)))
  (func $ne.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ne (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $ne.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.3.right.if (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.3.right (param $x i32) (result i32) (i32.lt_s (local.get $x) (i32.const 33)))
  (func $lt_s.3.right.ref (param $x i32) (result i32) (i32.lt_s (local.get $x) (global.get $c3)))
  (func $lt_s.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_s (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.3.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.3.right (param $x i32) (result i32) (i32.lt_u (local.get $x) (i32.const 33)))
  (func $lt_u.3.right.ref (param $x i32) (result i32) (i32.lt_u (local.get $x) (global.get $c3)))
  (func $lt_u.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.lt_u (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.3.right.if (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.lt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.3.right (param $x i32) (result i32) (i32.gt_s (local.get $x) (i32.const 33)))
  (func $gt_s.3.right.ref (param $x i32) (result i32) (i32.gt_s (local.get $x) (global.get $c3)))
  (func $gt_s.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_s (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.3.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.3.right (param $x i32) (result i32) (i32.gt_u (local.get $x) (i32.const 33)))
  (func $gt_u.3.right.ref (param $x i32) (result i32) (i32.gt_u (local.get $x) (global.get $c3)))
  (func $gt_u.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.gt_u (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.3.right.if (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.gt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.3.right (param $x i32) (result i32) (i32.le_s (local.get $x) (i32.const 33)))
  (func $le_s.3.right.ref (param $x i32) (result i32) (i32.le_s (local.get $x) (global.get $c3)))
  (func $le_s.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_s (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.3.right.if (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.3.right (param $x i32) (result i32) (i32.le_u (local.get $x) (i32.const 33)))
  (func $le_u.3.right.ref (param $x i32) (result i32) (i32.le_u (local.get $x) (global.get $c3)))
  (func $le_u.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.le_u (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.3.right.if (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.le_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.3.right (param $x i32) (result i32) (i32.ge_s (local.get $x) (i32.const 33)))
  (func $ge_s.3.right.ref (param $x i32) (result i32) (i32.ge_s (local.get $x) (global.get $c3)))
  (func $ge_s.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_s (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.3.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.3.right (param $x i32) (result i32) (i32.ge_u (local.get $x) (i32.const 33)))
  (func $ge_u.3.right.ref (param $x i32) (result i32) (i32.ge_u (local.get $x) (global.get $c3)))
  (func $ge_u.3.right.br_if (param $x i32) (result i32) (block (br_if 0 (i32.ge_u (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.3.right.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.3.right.if (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.3.right.if.ref (param $x i32) (result i32) (if (result i32) (i32.ge_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.3.br_if (param $x i32) (result i32) (block (br_if 0 (i32.and (local.get $x) (i32.const 33))) (return (i32.const 7))) (i32.const 9))
  (func $and.3.br_if.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c3)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.3.br_if_not (param $x i32) (result i32) (if (result i32) (i32.and (local.get $x) (i32.const 33)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.3.br_if_not.ref (param $x i32) (result i32) (if (result i32) (i32.ne (i32.and (local.get $x) (global.get $c3)) (i32.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.3 (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (i32.const 33)) (local.get $x)))
  (func $acc.3.ref (param $x i32) (result i32) (i32.rotr (i32.sub (local.get $x) (global.get $c3)) (local.get $x)))
  (func $super.3 (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (i32.const 33)) (local.get $x)))
  (func $super.3.ref (param $x i32) (result i32) (i32.add (i32.shl (local.get $x) (global.get $c3)) (local.get $x)))
  (func $super.sub.3 (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (i32.const 33)) (local.get $x)))
  (func $super.sub.3.ref (param $x i32) (result i32) (i32.and (i32.sub (local.get $x) (global.get $c3)) (local.get $x)))
  (type $fi32 (func (param $x i32) (result i32)))
  (table funcref (elem $add.0.right $add.0.right.ref $add.0.left $add.0.left.ref $sub.0.right $sub.0.right.ref $sub.0.left $sub.0.left.ref $mul.0.right $mul.0.right.ref $mul.0.left $mul.0.left.ref $and.0.right $and.0.right.ref $and.0.left $and.0.left.ref $or.0.right $or.0.right.ref $or.0.left $or.0.left.ref $xor.0.right $xor.0.right.ref $xor.0.left $xor.0.left.ref $shl.0.right $shl.0.right.ref $shl.0.left $shl.0.left.ref $shr_s.0.right $shr_s.0.right.ref $shr_s.0.left $shr_s.0.left.ref $shr_u.0.right $shr_u.0.right.ref $shr_u.0.left $shr_u.0.left.ref $rotl.0.right $rotl.0.right.ref $rotl.0.left $rotl.0.left.ref $rotr.0.right $rotr.0.right.ref $rotr.0.left $rotr.0.left.ref $eq.0.right $eq.0.right.ref $eq.0.right.br_if $eq.0.right.br_if.ref $eq.0.right.if $eq.0.right.if.ref $eq.0.right.eqz $eq.0.right.eqz.ref $eq.0.left $eq.0.left.ref $eq.0.left.br_if $eq.0.left.br_if.ref $eq.0.left.if $eq.0.left.if.ref $eq.0.left.eqz $eq.0.left.eqz.ref $ne.0.right $ne.0.right.ref $ne.0.right.br_if $ne.0.right.br_if.ref $ne.0.right.if $ne.0.right.if.ref $ne.0.right.eqz $ne.0.right.eqz.ref $ne.0.left $ne.0.left.ref $ne.0.left.br_if $ne.0.left.br_if.ref $ne.0.left.if $ne.0.left.if.ref $ne.0.left.eqz $ne.0.left.eqz.ref $lt_s.0.right $lt_s.0.right.ref $lt_s.0.right.br_if $lt_s.0.right.br_if.ref $lt_s.0.right.if $lt_s.0.right.if.ref $lt_s.0.right.eqz $lt_s.0.right.eqz.ref $lt_s.0.left $lt_s.0.left.ref $lt_s.0.left.br_if $lt_s.0.left.br_if.ref $lt_s.0.left.if $lt_s.0.left.if.ref $lt_s.0.left.eqz $lt_s.0.left.eqz.ref $lt_u.0.right $lt_u.0.right.ref $lt_u.0.right.br_if $lt_u.0.right.br_if.ref $lt_u.0.right.if $lt_u.0.right.if.ref $lt_u.0.right.eqz $lt_u.0.right.eqz.ref $lt_u.0.left $lt_u.0.left.ref $lt_u.0.left.br_if $lt_u.0.left.br_if.ref $lt_u.0.left.if $lt_u.0.left.if.ref $lt_u.0.left.eqz $lt_u.0.left.eqz.ref $gt_s.0.right $gt_s.0.right.ref $gt_s.0.right.br_if $gt_s.0.right.br_if.ref $gt_s.0.right.if $gt_s.0.right.if.ref $gt_s.0.right.eqz $gt_s.0.right.eqz.ref $gt_s.0.left $gt_s.0.left.ref $gt_s.0.left.br_if $gt_s.0.left.br_if.ref $gt_s.0.left.if $gt_s.0.left.if.ref $gt_s.0.left.eqz $gt_s.0.left.eqz.ref $gt_u.0.right $gt_u.0.right.ref $gt_u.0.right.br_if $gt_u.0.right.br_if.ref $gt_u.0.right.if $gt_u.0.right.if.ref $gt_u.0.right.eqz $gt_u.0.right.eqz.ref $gt_u.0.left $gt_u.0.left.ref $gt_u.0.left.br_if $gt_u.0.left.br_if.ref $gt_u.0.left.if $gt_u.0.left.if.ref $gt_u.0.left.eqz $gt_u.0.left.eqz.ref $le_s.0.right $le_s.0.right.ref $le_s.0.right.br_if $le_s.0.right.br_if.ref $le_s.0.right.if $le_s.0.right.if.ref $le_s.0.right.eqz $le_s.0.right.eqz.ref $le_s.0.left $le_s.0.left.ref $le_s.0.left.br_if $le_s.0.left.br_if.ref $le_s.0.left.if $le_s.0.left.if.ref $le_s.0.left.eqz $le_s.0.left.eqz.ref $le_u.0.right $le_u.0.right.ref $le_u.0.right.br_if $le_u.0.right.br_if.ref $le_u.0.right.if $le_u.0.right.if.ref $le_u.0.right.eqz $le_u.0.right.eqz.ref $le_u.0.left $le_u.0.left.ref $le_u.0.left.br_if $le_u.0.left.br_if.ref $le_u.0.left.if $le_u.0.left.if.ref $le_u.0.left.eqz $le_u.0.left.eqz.ref $ge_s.0.right $ge_s.0.right.ref $ge_s.0.right.br_if $ge_s.0.right.br_if.ref $ge_s.0.right.if $ge_s.0.right.if.ref $ge_s.0.right.eqz $ge_s.0.right.eqz.ref $ge_s.0.left $ge_s.0.left.ref $ge_s.0.left.br_if $ge_s.0.left.br_if.ref $ge_s.0.left.if $ge_s.0.left.if.ref $ge_s.0.left.eqz $ge_s.0.left.eqz.ref $ge_u.0.right $ge_u.0.right.ref $ge_u.0.right.br_if $ge_u.0.right.br_if.ref $ge_u.0.right.if $ge_u.0.right.if.ref $ge_u.0.right.eqz $ge_u.0.right.eqz.ref $ge_u.0.left $ge_u.0.left.ref $ge_u.0.left.br_if $ge_u.0.left.br_if.ref $ge_u.0.left.if $ge_u.0.left.if.ref $ge_u.0.left.eqz $ge_u.0.left.eqz.ref $and.0.br_if $and.0.br_if.ref $and.0.br_if_not $and.0.br_if_not.ref $acc.0 $acc.0.ref $super.0 $super.0.ref $super.sub.0 $super.sub.0.ref $add.1.right $add.1.right.ref $add.1.left $add.1.left.ref $sub.1.right $sub.1.right.ref $sub.1.left $sub.1.left.ref $mul.1.right $mul.1.right.ref $mul.1.left $mul.1.left.ref $and.1.right $and.1.right.ref $and.1.left $and.1.left.ref $or.1.right $or.1.right.ref $or.1.left $or.1.left.ref $xor.1.right $xor.1.right.ref $xor.1.left $xor.1.left.ref $shl.1.right $shl.1.right.ref $shl.1.left $shl.1.left.ref $shr_s.1.right $shr_s.1.right.ref $shr_s.1.left $shr_s.1.left.ref $shr_u.1.right $shr_u.1.right.ref $shr_u.1.left $shr_u.1.left.ref $rotl.1.right $rotl.1.right.ref $rotl.1.left $rotl.1.left.ref $rotr.1.right $rotr.1.right.ref $rotr.1.left $rotr.1.left.ref $eq.1.right $eq.1.right.ref $eq.1.right.br_if $eq.1.right.br_if.ref $eq.1.right.if $eq.1.right.if.ref $ne.1.right $ne.1.right.ref $ne.1.right.br_if $ne.1.right.br_if.ref $ne.1.right.if $ne.1.right.if.ref $lt_s.1.right $lt_s.1.right.ref $lt_s.1.right.br_if $lt_s.1.right.br_if.ref $lt_s.1.right.if $lt_s.1.right.if.ref $lt_u.1.right $lt_u.1.right.ref $lt_u.1.right.br_if $lt_u.1.right.br_if.ref $lt_u.1.right.if $lt_u.1.right.if.ref $gt_s.1.right $gt_s.1.right.ref $gt_s.1.right.br_if $gt_s.1.right.br_if.ref $gt_s.1.right.if $gt_s.1.right.if.ref $gt_u.1.right $gt_u.1.right.ref $gt_u.1.right.br_if $gt_u.1.right.br_if.ref $gt_u.1.right.if $gt_u.1.right.if.ref $le_s.1.right $le_s.1.right.ref $le_s.1.right.br_if $le_s.1.right.br_if.ref $le_s.1.right.if $le_s.1.right.if.ref $le_u.1.right $le_u.1.right.ref $le_u.1.right.br_if $le_u.1.right.br_if.ref $le_u.1.right.if $le_u.1.right.if.ref $ge_s.1.right $ge_s.1.right.ref $ge_s.1.right.br_if $ge_s.1.right.br_if.ref $ge_s.1.right.if $ge_s.1.right.if.ref $ge_u.1.right $ge_u.1.right.ref $ge_u.1.right.br_if $ge_u.1.right.br_if.ref $ge_u.1.right.if $ge_u.1.right.if.ref $and.1.br_if $and.1.br_if.ref $and.1.br_if_not $and.1.br_if_not.ref $acc.1 $acc.1.ref $super.1 $super.1.ref $super.sub.1 $super.sub.1.ref $add.2.right $add.2.right.ref $add.2.left $add.2.left.ref $sub.2.right $sub.2.right.ref $sub.2.left $sub.2.left.ref $mul.2.right $mul.2.right.ref $mul.2.left $mul.2.left.ref $and.2.right $and.2.right.ref $and.2.left $and.2.left.ref $or.2.right $or.2.right.ref $or.2.left $or.2.left.ref $xor.2.right $xor.2.right.ref $xor.2.left $xor.2.left.ref $shl.2.right $shl.2.right.ref $shl.2.left $shl.2.left.ref $shr_s.2.right $shr_s.2.right.ref $shr_s.2.left $shr_s.2.left.ref $shr_u.2.right $shr_u.2.right.ref $shr_u.2.left $shr_u.2.left.ref $rotl.2.right $rotl.2.right.ref $rotl.2.left $rotl.2.left.ref $rotr.2.right $rotr.2.right.ref $rotr.2.left $rotr.2.left.ref $eq.2.right $eq.2.right.ref $eq.2.right.br_if $eq.2.right.br_if.ref $eq.2.right.if $eq.2.right.if.ref $ne.2.right $ne.2.right.ref $ne.2.right.br_if $ne.2.right.br_if.ref $ne.2.right.if $ne.2.right.if.ref $lt_s.2.right $lt_s.2.right.ref $lt_s.2.right.br_if $lt_s.2.right.br_if.ref $lt_s.2.right.if $lt_s.2.right.if.ref $lt_u.2.right $lt_u.2.right.ref $lt_u.2.right.br_if $lt_u.2.right.br_if.ref $lt_u.2.right.if $lt_u.2.right.if.ref $gt_s.2.right $gt_s.2.right.ref $gt_s.2.right.br_if $gt_s.2.right.br_if.ref $gt_s.2.right.if $gt_s.2.right.if.ref $gt_u.2.right $gt_u.2.right.ref $gt_u.2.right.br_if $gt_u.2.right.br_if.ref $gt_u.2.right.if $gt_u.2.right.if.ref $le_s.2.right $le_s.2.right.ref $le_s.2.right.br_if $le_s.2.right.br_if.ref $le_s.2.right.if $le_s.2.right.if.ref $le_u.2.right $le_u.2.right.ref $le_u.2.right.br_if $le_u.2.right.br_if.ref $le_u.2.right.if $le_u.2.right.if.ref $ge_s.2.right $ge_s.2.right.ref $ge_s.2.right.br_if $ge_s.2.right.br_if.ref $ge_s.2.right.if $ge_s.2.right.if.ref $ge_u.2.right $ge_u.2.right.ref $ge_u.2.right.br_if $ge_u.2.right.br_if.ref $ge_u.2.right.if $ge_u.2.right.if.ref $and.2.br_if $and.2.br_if.ref $and.2.br_if_not $and.2.br_if_not.ref $acc.2 $acc.2.ref $super.2 $super.2.ref $super.sub.2 $super.sub.2.ref $add.3.right $add.3.right.ref $add.3.left $add.3.left.ref $sub.3.right $sub.3.right.ref $sub.3.left $sub.3.left.ref $mul.3.right $mul.3.right.ref $mul.3.left $mul.3.left.ref $and.3.right $and.3.right.ref $and.3.left $and.3.left.ref $or.3.right $or.3.right.ref $or.3.left $or.3.left.ref $xor.3.right $xor.3.right.ref $xor.3.left $xor.3.left.ref $shl.3.right $shl.3.right.ref $shl.3.left $shl.3.left.ref $shr_s.3.right $shr_s.3.right.ref $shr_s.3.left $shr_s.3.left.ref $shr_u.3.right $shr_u.3.right.ref $shr_u.3.left $shr_u.3.left.ref $rotl.3.right $rotl.3.right.ref $rotl.3.left $rotl.3.left.ref $rotr.3.right $rotr.3.right.ref $rotr.3.left $rotr.3.left.ref $eq.3.right $eq.3.right.ref $eq.3.right.br_if $eq.3.right.br_if.ref $eq.3.right.if $eq.3.right.if.ref $ne.3.right $ne.3.right.ref $ne.3.right.br_if $ne.3.right.br_if.ref $ne.3.right.if $ne.3.right.if.ref $lt_s.3.right $lt_s.3.right.ref $lt_s.3.right.br_if $lt_s.3.right.br_if.ref $lt_s.3.right.if $lt_s.3.right.if.ref $lt_u.3.right $lt_u.3.right.ref $lt_u.3.right.br_if $lt_u.3.right.br_if.ref $lt_u.3.right.if $lt_u.3.right.if.ref $gt_s.3.right $gt_s.3.right.ref $gt_s.3.right.br_if $gt_s.3.right.br_if.ref $gt_s.3.right.if $gt_s.3.right.if.ref $gt_u.3.right $gt_u.3.right.ref $gt_u.3.right.br_if $gt_u.3.right.br_if.ref $gt_u.3.right.if $gt_u.3.right.if.ref $le_s.3.right $le_s.3.right.ref $le_s.3.right.br_if $le_s.3.right.br_if.ref $le_s.3.right.if $le_s.3.right.if.ref $le_u.3.right $le_u.3.right.ref $le_u.3.right.br_if $le_u.3.right.br_if.ref $le_u.3.right.if $le_u.3.right.if.ref $ge_s.3.right $ge_s.3.right.ref $ge_s.3.right.br_if $ge_s.3.right.br_if.ref $ge_s.3.right.if $ge_s.3.right.if.ref $ge_u.3.right $ge_u.3.right.ref $ge_u.3.right.br_if $ge_u.3.right.br_if.ref $ge_u.3.right.if $ge_u.3.right.if.ref $and.3.br_if $and.3.br_if.ref $and.3.br_if_not $and.3.br_if_not.ref $acc.3 $acc.3.ref $super.3 $super.3.ref $super.sub.3 $super.sub.3.ref))
  (func (export "check.i32") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $f i32) (local $x i32)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $x (i32.load (i32.mul (local.get $i) (i32.const 4))))
      (if (i32.ne (call_indirect (type $fi32) (local.get $x) (local.get $f))
                  (call_indirect (type $fi32) (local.get $x) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 7))))
    (local.get $n))
)
(assert_return (invoke "check.i32" (i32.const 0)) (i32.const 0)) ;; i32 add.0.right
(assert_return (invoke "check.i32" (i32.const 1)) (i32.const 0)) ;; i32 add.0.left
(assert_return (invoke "check.i32" (i32.const 2)) (i32.const 0)) ;; i32 sub.0.right
(assert_return (invoke "check.i32" (i32.const 3)) (i32.const 0)) ;; i32 sub.0.left
(assert_return (invoke "check.i32" (i32.const 4)) (i32.const 0)) ;; i32 mul.0.right
(assert_return (invoke "check.i32" (i32.const 5)) (i32.const 0)) ;; i32 mul.0.left
(assert_return (invoke "check.i32" (i32.const 6)) (i32.const 0)) ;; i32 and.0.right
(assert_return (invoke "check.i32" (i32.const 7)) (i32.const 0)) ;; i32 and.0.left
(assert_return (invoke "check.i32" (i32.const 8)) (i32.const 0)) ;; i32 or.0.right
(assert_return (invoke "check.i32" (i32.const 9)) (i32.const 0)) ;; i32 or.0.left
(assert_return (invoke "check.i32" (i32.const 10)) (i32.const 0)) ;; i32 xor.0.right
(assert_return (invoke "check.i32" (i32.const 11)) (i32.const 0)) ;; i32 xor.0.left
(assert_return (invoke "check.i32" (i32.const 12)) (i32.const 0)) ;; i32 shl.0.right
(assert_return (invoke "check.i32" (i32.const 13)) (i32.const 0)) ;; i32 shl.0.left
(assert_return (invoke "check.i32" (i32.const 14)) (i32.const 0)) ;; i32 shr_s.0.right
(assert_return (invoke "check.i32" (i32.const 15)) (i32.const 0)) ;; i32 shr_s.0.left
(assert_return (invoke "check.i32" (i32.const 16)) (i32.const 0)) ;; i32 shr_u.0.right
(assert_return (invoke "check.i32" (i32.const 17)) (i32.const 0)) ;; i32 shr_u.0.left
(assert_return (invoke "check.i32" (i32.const 18)) (i32.const 0)) ;; i32 rotl.0.right
(assert_return (invoke "check.i32" (i32.const 19)) (i32.const 0)) ;; i32 rotl.0.left
(assert_return (invoke "check.i32" (i32.const 20)) (i32.const 0)) ;; i32 rotr.0.right
(assert_return (invoke "check.i32" (i32.const 21)) (i32.const 0)) ;; i32 rotr.0.left
(assert_return (invoke "check.i32" (i32.const 22)) (i32.const 0)) ;; i32 eq.0.right
(assert_return (invoke "check.i32" (i32.const 23)) (i32.const 0)) ;; i32 eq.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 24)) (i32.const 0)) ;; i32 eq.0.right.if
(assert_return (invoke "check.i32" (i32.const 25)) (i32.const 0)) ;; i32 eq.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 26)) (i32.const 0)) ;; i32 eq.0.left
(assert_return (invoke "check.i32" (i32.const 27)) (i32.const 0)) ;; i32 eq.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 28)) (i32.const 0)) ;; i32 eq.0.left.if
(assert_return (invoke "check.i32" (i32.const 29)) (i32.const 0)) ;; i32 eq.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 30)) (i32.const 0)) ;; i32 ne.0.right
(assert_return (invoke "check.i32" (i32.const 31)) (i32.const 0)) ;; i32 ne.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 32)) (i32.const 0)) ;; i32 ne.0.right.if
(assert_return (invoke "check.i32" (i32.const 33)) (i32.const 0)) ;; i32 ne.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 34)) (i32.const 0)) ;; i32 ne.0.left
(assert_return (invoke "check.i32" (i32.const 35)) (i32.const 0)) ;; i32 ne.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 36)) (i32.const 0)) ;; i32 ne.0.left.if
(assert_return (invoke "check.i32" (i32.const 37)) (i32.const 0)) ;; i32 ne.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 38)) (i32.const 0)) ;; i32 lt_s.0.right
(assert_return (invoke "check.i32" (i32.const 39)) (i32.const 0)) ;; i32 lt_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 40)) (i32.const 0)) ;; i32 lt_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 41)) (i32.const 0)) ;; i32 lt_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 42)) (i32.const 0)) ;; i32 lt_s.0.left
(assert_return (invoke "check.i32" (i32.const 43)) (i32.const 0)) ;; i32 lt_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 44)) (i32.const 0)) ;; i32 lt_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 45)) (i32.const 0)) ;; i32 lt_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 46)) (i32.const 0)) ;; i32 lt_u.0.right
(assert_return (invoke "check.i32" (i32.const 47)) (i32.const 0)) ;; i32 lt_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 48)) (i32.const 0)) ;; i32 lt_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 49)) (i32.const 0)) ;; i32 lt_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 50)) (i32.const 0)) ;; i32 lt_u.0.left
(assert_return (invoke "check.i32" (i32.const 51)) (i32.const 0)) ;; i32 lt_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 52)) (i32.const 0)) ;; i32 lt_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 53)) (i32.const 0)) ;; i32 lt_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 54)) (i32.const 0)) ;; i32 gt_s.0.right
(assert_return (invoke "check.i32" (i32.const 55)) (i32.const 0)) ;; i32 gt_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 56)) (i32.const 0)) ;; i32 gt_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 57)) (i32.const 0)) ;; i32 gt_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 58)) (i32.const 0)) ;; i32 gt_s.0.left
(assert_return (invoke "check.i32" (i32.const 59)) (i32.const 0)) ;; i32 gt_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 60)) (i32.const 0)) ;; i32 gt_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 61)) (i32.const 0)) ;; i32 gt_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 62)) (i32.const 0)) ;; i32 gt_u.0.right
(assert_return (invoke "check.i32" (i32.const 63)) (i32.const 0)) ;; i32 gt_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 64)) (i32.const 0)) ;; i32 gt_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 65)) (i32.const 0)) ;; i32 gt_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 66)) (i32.const 0)) ;; i32 gt_u.0.left
(assert_return (invoke "check.i32" (i32.const 67)) (i32.const 0)) ;; i32 gt_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 68)) (i32.const 0)) ;; i32 gt_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 69)) (i32.const 0)) ;; i32 gt_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 70)) (i32.const 0)) ;; i32 le_s.0.right
(assert_return (invoke "check.i32" (i32.const 71)) (i32.const 0)) ;; i32 le_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 72)) (i32.const 0)) ;; i32 le_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 73)) (i32.const 0)) ;; i32 le_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 74)) (i32.const 0)) ;; i32 le_s.0.left
(assert_return (invoke "check.i32" (i32.const 75)) (i32.const 0)) ;; i32 le_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 76)) (i32.const 0)) ;; i32 le_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 77)) (i32.const 0)) ;; i32 le_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 78)) (i32.const 0)) ;; i32 le_u.0.right
(assert_return (invoke "check.i32" (i32.const 79)) (i32.const 0)) ;; i32 le_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 80)) (i32.const 0)) ;; i32 le_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 81)) (i32.const 0)) ;; i32 le_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 82)) (i32.const 0)) ;; i32 le_u.0.left
(assert_return (invoke "check.i32" (i32.const 83)) (i32.const 0)) ;; i32 le_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 84)) (i32.const 0)) ;; i32 le_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 85)) (i32.const 0)) ;; i32 le_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 86)) (i32.const 0)) ;; i32 ge_s.0.right
(assert_return (invoke "check.i32" (i32.const 87)) (i32.const 0)) ;; i32 ge_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 88)) (i32.const 0)) ;; i32 ge_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 89)) (i32.const 0)) ;; i32 ge_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 90)) (i32.const 0)) ;; i32 ge_s.0.left
(assert_return (invoke "check.i32" (i32.const 91)) (i32.const 0)) ;; i32 ge_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 92)) (i32.const 0)) ;; i32 ge_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 93)) (i32.const 0)) ;; i32 ge_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 94)) (i32.const 0)) ;; i32 ge_u.0.right
(assert_return (invoke "check.i32" (i32.const 95)) (i32.const 0)) ;; i32 ge_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 96)) (i32.const 0)) ;; i32 ge_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 97)) (i32.const 0)) ;; i32 ge_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 98)) (i32.const 0)) ;; i32 ge_u.0.left
(assert_return (invoke "check.i32" (i32.const 99)) (i32.const 0)) ;; i32 ge_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 100)) (i32.const 0)) ;; i32 ge_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 101)) (i32.const 0)) ;; i32 ge_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 102)) (i32.const 0)) ;; i32 and.0.br_if
(assert_return (invoke "check.i32" (i32.const 103)) (i32.const 0)) ;; i32 and.0.br_if_not
(assert_return (invoke "check.i32" (i32.const 104)) (i32.const 0)) ;; i32 acc.0
(assert_return (invoke "check.i32" (i32.const 105)) (i32.const 0)) ;; i32 super.0
(assert_return (invoke "check.i32" (i32.const 106)) (i32.const 0)) ;; i32 super.sub.0
(assert_return (invoke "check.i32" (i32.const 107)) (i32.const 0)) ;; i32 add.1.right
(assert_return (invoke "check.i32" (i32.const 108)) (i32.const 0)) ;; i32 add.1.left
(assert_return (invoke "check.i32" (i32.const 109)) (i32.const 0)) ;; i32 sub.1.right
(assert_return (invoke "check.i32" (i32.const 110)) (i32.const 0)) ;; i32 sub.1.left
(assert_return (invoke "check.i32" (i32.const 111)) (i32.const 0)) ;; i32 mul.1.right
(assert_return (invoke "check.i32" (i32.const 112)) (i32.const 0)) ;; i32 mul.1.left
(assert_return (invoke "check.i32" (i32.const 113)) (i32.const 0)) ;; i32 and.1.right
(assert_return (invoke "check.i32" (i32.const 114)) (i32.const 0)) ;; i32 and.1.left
(assert_return (invoke "check.i32" (i32.const 115)) (i32.const 0)) ;; i32 or.1.right
(assert_return (invoke "check.i32" (i32.const 116)) (i32.const 0)) ;; i32 or.1.left
(assert_return (invoke "check.i32" (i32.const 117)) (i32.const 0)) ;; i32 xor.1.right
(assert_return (invoke "check.i32" (i32.const 118)) (i32.const 0)) ;; i32 xor.1.left
(assert_return (invoke "check.i32" (i32.const 119)) (i32.const 0)) ;; i32 shl.1.right
(assert_return (invoke "check.i32" (i32.const 120)) (i32.const 0)) ;; i32 shl.1.left
(assert_return (invoke "check.i32" (i32.const 121)) (i32.const 0)) ;; i32 shr_s.1.right
(assert_return (invoke "check.i32" (i32.const 122)) (i32.const 0)) ;; i32 shr_s.1.left
(assert_return (invoke "check.i32" (i32.const 123)) (i32.const 0)) ;; i32 shr_u.1.right
(assert_return (invoke "check.i32" (i32.const 124)) (i32.const 0)) ;; i32 shr_u.1.left
(assert_return (invoke "check.i32" (i32.const 125)) (i32.const 0)) ;; i32 rotl.1.right
(assert_return (invoke "check.i32" (i32.const 126)) (i32.const 0)) ;; i32 rotl.1.left
(assert_return (invoke "check.i32" (i32.const 127)) (i32.const 0)) ;; i32 rotr.1.right
(assert_return (invoke "check.i32" (i32.const 128)) (i32.const 0)) ;; i32 rotr.1.left
(assert_return (invoke "check.i32" (i32.const 129)) (i32.const 0)) ;; i32 eq.1.right
(assert_return (invoke "check.i32" (i32.const 130)) (i32.const 0)) ;; i32 eq.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 131)) (i32.const 0)) ;; i32 eq.1.right.if
(assert_return (invoke "check.i32" (i32.const 132)) (i32.const 0)) ;; i32 ne.1.right
(assert_return (invoke "check.i32" (i32.const 133)) (i32.const 0)) ;; i32 ne.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 134)) (i32.const 0)) ;; i32 ne.1.right.if
(assert_return (invoke "check.i32" (i32.const 135)) (i32.const 0)) ;; i32 lt_s.1.right
(assert_return (invoke "check.i32" (i32.const 136)) (i32.const 0)) ;; i32 lt_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 137)) (i32.const 0)) ;; i32 lt_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 138)) (i32.const 0)) ;; i32 lt_u.1.right
(assert_return (invoke "check.i32" (i32.const 139)) (i32.const 0)) ;; i32 lt_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 140)) (i32.const 0)) ;; i32 lt_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 141)) (i32.const 0)) ;; i32 gt_s.1.right
(assert_return (invoke "check.i32" (i32.const 142)) (i32.const 0)) ;; i32 gt_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 143)) (i32.const 0)) ;; i32 gt_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 144)) (i32.const 0)) ;; i32 gt_u.1.right
(assert_return (invoke "check.i32" (i32.const 145)) (i32.const 0)) ;; i32 gt_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 146)) (i32.const 0)) ;; i32 gt_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 147)) (i32.const 0)) ;; i32 le_s.1.right
(assert_return (invoke "check.i32" (i32.const 148)) (i32.const 0)) ;; i32 le_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 149)) (i32.const 0)) ;; i32 le_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 150)) (i32.const 0)) ;; i32 le_u.1.right
(assert_return (invoke "check.i32" (i32.const 151)) (i32.const 0)) ;; i32 le_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 152)) (i32.const 0)) ;; i32 le_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 153)) (i32.const 0)) ;; i32 ge_s.1.right
(assert_return (invoke "check.i32" (i32.const 154)) (i32.const 0)) ;; i32 ge_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 155)) (i32.const 0)) ;; i32 ge_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 156)) (i32.const 0)) ;; i32 ge_u.1.right
(assert_return (invoke "check.i32" (i32.const 157)) (i32.const 0)) ;; i32 ge_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 158)) (i32.const 0)) ;; i32 ge_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 159)) (i32.const 0)) ;; i32 and.1.br_if
(assert_return (invoke "check.i32" (i32.const 160)) (i32.const 0)) ;; i32 and.1.br_if_not
(assert_return (invoke "check.i32" (i32.const 161)) (i32.const 0)) ;; i32 acc.1
(assert_return (invoke "check.i32" (i32.const 162)) (i32.const 0)) ;; i32 super.1
(assert_return (invoke "check.i32" (i32.const 163)) (i32.const 0)) ;; i32 super.sub.1
(assert_return (invoke "check.i32" (i32.const 164)) (i32.const 0)) ;; i32 add.2.right
(assert_return (invoke "check.i32" (i32.const 165)) (i32.const 0)) ;; i32 add.2.left
(assert_return (invoke "check.i32" (i32.const 166)) (i32.const 0)) ;; i32 sub.2.right
(assert_return (invoke "check.i32" (i32.const 167)) (i32.const 0)) ;; i32 sub.2.left
(assert_return (invoke "check.i32" (i32.const 168)) (i32.const 0)) ;; i32 mul.2.right
(assert_return (invoke "check.i32" (i32.const 169)) (i32.const 0)) ;; i32 mul.2.left
(assert_return (invoke "check.i32" (i32.const 170)) (i32.const 0)) ;; i32 and.2.right
(assert_return (invoke "check.i32" (i32.const 171)) (i32.const 0)) ;; i32 and.2.left
(assert_return (invoke "check.i32" (i32.const 172)) (i32.const 0)) ;; i32 or.2.right
(assert_return (invoke "check.i32" (i32.const 173)) (i32.const 0)) ;; i32 or.2.left
(assert_return (invoke "check.i32" (i32.const 174)) (i32.const 0)) ;; i32 xor.2.right
(assert_return (invoke "check.i32" (i32.const 175)) (i32.const 0)) ;; i32 xor.2.left
(assert_return (invoke "check.i32" (i32.const 176)) (i32.const 0)) ;; i32 shl.2.right
(assert_return (invoke "check.i32" (i32.const 177)) (i32.const 0)) ;; i32 shl.2.left
(assert_return (invoke "check.i32" (i32.const 178)) (i32.const 0)) ;; i32 shr_s.2.right
(assert_return (invoke "check.i32" (i32.const 179)) (i32.const 0)) ;; i32 shr_s.2.left
(assert_return (invoke "check.i32" (i32.const 180)) (i32.const 0)) ;; i32 shr_u.2.right
(assert_return (invoke "check.i32" (i32.const 181)) (i32.const 0)) ;; i32 shr_u.2.left
(assert_return (invoke "check.i32" (i32.const 182)) (i32.const 0)) ;; i32 rotl.2.right
(assert_return (invoke "check.i32" (i32.const 183)) (i32.const 0)) ;; i32 rotl.2.left
(assert_return (invoke "check.i32" (i32.const 184)) (i32.const 0)) ;; i32 rotr.2.right
(assert_return (invoke "check.i32" (i32.const 185)) (i32.const 0)) ;; i32 rotr.2.left
(assert_return (invoke "check.i32" (i32.const 186)) (i32.const 0)) ;; i32 eq.2.right
(assert_return (invoke "check.i32" (i32.const 187)) (i32.const 0)) ;; i32 eq.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 188)) (i32.const 0)) ;; i32 eq.2.right.if
(assert_return (invoke "check.i32" (i32.const 189)) (i32.const 0)) ;; i32 ne.2.right
(assert_return (invoke "check.i32" (i32.const 190)) (i32.const 0)) ;; i32 ne.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 191)) (i32.const 0)) ;; i32 ne.2.right.if
(assert_return (invoke "check.i32" (i32.const 192)) (i32.const 0)) ;; i32 lt_s.2.right
(assert_return (invoke "check.i32" (i32.const 193)) (i32.const 0)) ;; i32 lt_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 194)) (i32.const 0)) ;; i32 lt_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 195)) (i32.const 0)) ;; i32 lt_u.2.right
(assert_return (invoke "check.i32" (i32.const 196)) (i32.const 0)) ;; i32 lt_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 197)) (i32.const 0)) ;; i32 lt_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 198)) (i32.const 0)) ;; i32 gt_s.2.right
(assert_return (invoke "check.i32" (i32.const 199)) (i32.const 0)) ;; i32 gt_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 200)) (i32.const 0)) ;; i32 gt_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 201)) (i32.const 0)) ;; i32 gt_u.2.right
(assert_return (invoke "check.i32" (i32.const 202)) (i32.const 0)) ;; i32 gt_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 203)) (i32.const 0)) ;; i32 gt_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 204)) (i32.const 0)) ;; i32 le_s.2.right
(assert_return (invoke "check.i32" (i32.const 205)) (i32.const 0)) ;; i32 le_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 206)) (i32.const 0)) ;; i32 le_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 207)) (i32.const 0)) ;; i32 le_u.2.right
(assert_return (invoke "check.i32" (i32.const 208)) (i32.const 0)) ;; i32 le_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 209)) (i32.const 0)) ;; i32 le_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 210)) (i32.const 0)) ;; i32 ge_s.2.right
(assert_return (invoke "check.i32" (i32.const 211)) (i32.const 0)) ;; i32 ge_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 212)) (i32.const 0)) ;; i32 ge_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 213)) (i32.const 0)) ;; i32 ge_u.2.right
(assert_return (invoke "check.i32" (i32.const 214)) (i32.const 0)) ;; i32 ge_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 215)) (i32.const 0)) ;; i32 ge_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 216)) (i32.const 0)) ;; i32 and.2.br_if
(assert_return (invoke "check.i32" (i32.const 217)) (i32.const 0)) ;; i32 and.2.br_if_not
(assert_return (invoke "check.i32" (i32.const 218)) (i32.const 0)) ;; i32 acc.2
(assert_return (invoke "check.i32" (i32.const 219)) (i32.const 0)) ;; i32 super.2
(assert_return (invoke "check.i32" (i32.const 220)) (i32.const 0)) ;; i32 super.sub.2
(assert_return (invoke "check.i32" (i32.const 221)) (i32.const 0)) ;; i32 add.3.right
(assert_return (invoke "check.i32" (i32.const 222)) (i32.const 0)) ;; i32 add.3.left
(assert_return (invoke "check.i32" (i32.const 223)) (i32.const 0)) ;; i32 sub.3.right
(assert_return (invoke "check.i32" (i32.const 224)) (i32.const 0)) ;; i32 sub.3.left
(assert_return (invoke "check.i32" (i32.const 225)) (i32.const 0)) ;; i32 mul.3.right
(assert_return (invoke "check.i32" (i32.const 226)) (i32.const 0)) ;; i32 mul.3.left
(assert_return (invoke "check.i32" (i32.const 227)) (i32.const 0)) ;; i32 and.3.right
(assert_return (invoke "check.i32" (i32.const 228)) (i32.const 0)) ;; i32 and.3.left
(assert_return (invoke "check.i32" (i32.const 229)) (i32.const 0)) ;; i32 or.3.right
(assert_return (invoke "check.i32" (i32.const 230)) (i32.const 0)) ;; i32 or.3.left
(assert_return (invoke "check.i32" (i32.const 231)) (i32.const 0)) ;; i32 xor.3.right
(assert_return (invoke "check.i32" (i32.const 232)) (i32.const 0)) ;; i32 xor.3.left
(assert_return (invoke "check.i32" (i32.const 233)) (i32.const 0)) ;; i32 shl.3.right
(assert_return (invoke "check.i32" (i32.const 234)) (i32.const 0)) ;; i32 shl.3.left
(assert_return (invoke "check.i32" (i32.const 235)) (i32.const 0)) ;; i32 shr_s.3.right
(assert_return (invoke "check.i32" (i32.const 236)) (i32.const 0)) ;; i32 shr_s.3.left
(assert_return (invoke "check.i32" (i32.const 237)) (i32.const 0)) ;; i32 shr_u.3.right
(assert_return (invoke "check.i32" (i32.const 238)) (i32.const 0)) ;; i32 shr_u.3.left
(assert_return (invoke "check.i32" (i32.const 239)) (i32.const 0)) ;; i32 rotl.3.right
(assert_return (invoke "check.i32" (i32.const 240)) (i32.const 0)) ;; i32 rotl.3.left
(assert_return (invoke "check.i32" (i32.const 241)) (i32.const 0)) ;; i32 rotr.3.right
(assert_return (invoke "check.i32" (i32.const 242)) (i32.const 0)) ;; i32 rotr.3.left
(assert_return (invoke "check.i32" (i32.const 243)) (i32.const 0)) ;; i32 eq.3.right
(assert_return (invoke "check.i32" (i32.const 244)) (i32.const 0)) ;; i32 eq.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 245)) (i32.const 0)) ;; i32 eq.3.right.if
(assert_return (invoke "check.i32" (i32.const 246)) (i32.const 0)) ;; i32 ne.3.right
(assert_return (invoke "check.i32" (i32.const 247)) (i32.const 0)) ;; i32 ne.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 248)) (i32.const 0)) ;; i32 ne.3.right.if
(assert_return (invoke "check.i32" (i32.const 249)) (i32.const 0)) ;; i32 lt_s.3.right
(assert_return (invoke "check.i32" (i32.const 250)) (i32.const 0)) ;; i32 lt_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 251)) (i32.const 0)) ;; i32 lt_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 252)) (i32.const 0)) ;; i32 lt_u.3.right
(assert_return (invoke "check.i32" (i32.const 253)) (i32.const 0)) ;; i32 lt_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 254)) (i32.const 0)) ;; i32 lt_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 255)) (i32.const 0)) ;; i32 gt_s.3.right
(assert_return (invoke "check.i32" (i32.const 256)) (i32.const 0)) ;; i32 gt_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 257)) (i32.const 0)) ;; i32 gt_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 258)) (i32.const 0)) ;; i32 gt_u.3.right
(assert_return (invoke "check.i32" (i32.const 259)) (i32.const 0)) ;; i32 gt_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 260)) (i32.const 0)) ;; i32 gt_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 261)) (i32.const 0)) ;; i32 le_s.3.right
(assert_return (invoke "check.i32" (i32.const 262)) (i32.const 0)) ;; i32 le_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 263)) (i32.const 0)) ;; i32 le_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 264)) (i32.const 0)) ;; i32 le_u.3.right
(assert_return (invoke "check.i32" (i32.const 265)) (i32.const 0)) ;; i32 le_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 266)) (i32.const 0)) ;; i32 le_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 267)) (i32.const 0)) ;; i32 ge_s.3.right
(assert_return (invoke "check.i32" (i32.const 268)) (i32.const 0)) ;; i32 ge_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 269)) (i32.const 0)) ;; i32 ge_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 270)) (i32.const 0)) ;; i32 ge_u.3.right
(assert_return (invoke "check.i32" (i32.const 271)) (i32.const 0)) ;; i32 ge_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 272)) (i32.const 0)) ;; i32 ge_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 273)) (i32.const 0)) ;; i32 and.3.br_if
(assert_return (invoke "check.i32" (i32.const 274)) (i32.const 0)) ;; i32 and.3.br_if_not
(assert_return (invoke "check.i32" (i32.const 275)) (i32.const 0)) ;; i32 acc.3
(assert_return (invoke "check.i32" (i32.const 276)) (i32.const 0)) ;; i32 super.3
(assert_return (invoke "check.i32" (i32.const 277)) (i32.const 0)) ;; i32 super.sub.3

(module
  (memory 1)
  (data (i32.const 0) "\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\3f\00\00\00\00\00\00\00\f0\de\bc\9a\78\56\34\12")
  (global $c0 i64 (i64.const -1))
  (global $c1 i64 (i64.const -2147483648))
  (global $c2 i64 (i64.const 2147483648))
  (global $c3 i64 (i64.const 4294967301))
  (func $add.0.right (param $x i64) (result i64) (i64.add (local.get $x) (i64.const -1)))
  (func $add.0.right.ref (param $x i64) (result i64) (i64.add (local.get $x) (global.get $c0)))
  (func $add.0.left (param $x i64) (result i64) (i64.add (i64.const -1) (local.get $x)))
  (func $add.0.left.ref (param $x i64) (result i64) (i64.add (global.get $c0) (local.get $x)))
  (func $sub.0.right (param $x i64) (result i64) (i64.sub (local.get $x) (i64.const -1)))
  (func $sub.0.right.ref (param $x i64) (result i64) (i64.sub (local.get $x) (global.get $c0)))
  (func $sub.0.left (param $x i64) (result i64) (i64.sub (i64.const -1) (local.get $x)))
  (func $sub.0.left.ref (param $x i64) (result i64) (i64.sub (global.get $c0) (local.get $x)))
  (func $mul.0.right (param $x i64) (result i64) (i64.mul (local.get $x) (i64.const -1)))
  (func $mul.0.right.ref (param $x i64) (result i64) (i64.mul (local.get $x) (global.get $c0)))
  (func $mul.0.left (param $x i64) (result i64) (i64.mul (i64.const -1) (local.get $x)))
  (func $mul.0.left.ref (param $x i64) (result i64) (i64.mul (global.get $c0) (local.get $x)))
  (func $and.0.right (param $x i64) (result i64) (i64.and (local.get $x) (i64.const -1)))
  (func $and.0.right.ref (param $x i64) (result i64) (i64.and (local.get $x) (global.get $c0)))
  (func $and.0.left (param $x i64) (result i64) (i64.and (i64.const -1) (local.get $x)))
  (func $and.0.left.ref (param $x i64) (result i64) (i64.and (global.get $c0) (local.get $x)))
  (func $or.0.right (param $x i64) (result i64) (i64.or (local.get $x) (i64.const -1)))
  (func $or.0.right.ref (param $x i64) (result i64) (i64.or (local.get $x) (global.get $c0)))
  (func $or.0.left (param $x i64) (result i64) (i64.or (i64.const -1) (local.get $x)))
  (func $or.0.left.ref (param $x i64) (result i64) (i64.or (global.get $c0) (local.get $x)))
  (func $xor.0.right (param $x i64) (result i64) (i64.xor (local.get $x) (i64.const -1)))
  (func $xor.0.right.ref (param $x i64) (result i64) (i64.xor (local.get $x) (global.get $c0)))
  (func $xor.0.left (param $x i64) (result i64) (i64.xor (i64.const -1) (local.get $x)))
  (func $xor.0.left.ref (param $x i64) (result i64) (i64.xor (global.get $c0) (local.get $x)))
  (func $shl.0.right (param $x i64) (result i64) (i64.shl (local.get $x) (i64.const -1)))
  (func $shl.0.right.ref (param $x i64) (result i64) (i64.shl (local.get $x) (global.get $c0)))
  (func $shl.0.left (param $x i64) (result i64) (i64.shl (i64.const -1) (local.get $x)))
  (func $shl.0.left.ref (param $x i64) (result i64) (i64.shl (global.get $c0) (local.get $x)))
  (func $shr_s.0.right (param $x i64) (result i64) (i64.shr_s (local.get $x) (i64.const -1)))
  (func $shr_s.0.right.ref (param $x i64) (result i64) (i64.shr_s (local.get $x) (global.get $c0)))
  (func $shr_s.0.left (param $x i64) (result i64) (i64.shr_s (i64.const -1) (local.get $x)))
  (func $shr_s.0.left.ref (param $x i64) (result i64) (i64.shr_s (global.get $c0) (local.get $x)))
  (func $shr_u.0.right (param $x i64) (result i64) (i64.shr_u (local.get $x) (i64.const -1)))
  (func $shr_u.0.right.ref (param $x i64) (result i64) (i64.shr_u (local.get $x) (global.get $c0)))
  (func $shr_u.0.left (param $x i64) (result i64) (i64.shr_u (i64.const -1) (local.get $x)))
  (func $shr_u.0.left.ref (param $x i64) (result i64) (i64.shr_u (global.get $c0) (local.get $x)))
  (func $rotl.0.right (param $x i64) (result i64) (i64.rotl (local.get $x) (i64.const -1)))
  (func $rotl.0.right.ref (param $x i64) (result i64) (i64.rotl (local.get $x) (global.get $c0)))
  (func $rotl.0.left (param $x i64) (result i64) (i64.rotl (i64.const -1) (local.get $x)))
  (func $rotl.0.left.ref (param $x i64) (result i64) (i64.rotl (global.get $c0) (local.get $x)))
  (func $rotr.0.right (param $x i64) (result i64) (i64.rotr (local.get $x) (i64.const -1)))
  (func $rotr.0.right.ref (param $x i64) (result i64) (i64.rotr (local.get $x) (global.get $c0)))
  (func $rotr.0.left (param $x i64) (result i64) (i64.rotr (i64.const -1) (local.get $x)))
  (func $rotr.0.left.ref (param $x i64) (result i64) (i64.rotr (global.get $c0) (local.get $x)))
  (func $eq.0.right (param $x i64) (result i32) (i64.eq (local.get $x) (i64.const -1)))
  (func $eq.0.right.ref (param $x i64) (result i32) (i64.eq (local.get $x) (global.get $c0)))
  (func $eq.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.eq (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $eq.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.right.if (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.eq (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $eq.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left (param $x i64) (result i32) (i64.eq (i64.const -1) (local.get $x)))
  (func $eq.0.left.ref (param $x i64) (result i32) (i64.eq (global.get $c0) (local.get $x)))
  (func $eq.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.eq (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $eq.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left.if (param $x i64) (result i32) (if (result i32) (i64.eq (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.eq (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $eq.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.eq (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right (param $x i64) (result i32) (i64.ne (local.get $x) (i64.const -1)))
  (func $ne.0.right.ref (param $x i64) (result i32) (i64.ne (local.get $x) (global.get $c0)))
  (func $ne.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ne (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $ne.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right.if (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.ne (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ne.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left (param $x i64) (result i32) (i64.ne (i64.const -1) (local.get $x)))
  (func $ne.0.left.ref (param $x i64) (result i32) (i64.ne (global.get $c0) (local.get $x)))
  (func $ne.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ne (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $ne.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left.if (param $x i64) (result i32) (if (result i32) (i64.ne (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.ne (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ne.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.ne (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right (param $x i64) (result i32) (i64.lt_s (local.get $x) (i64.const -1)))
  (func $lt_s.0.right.ref (param $x i64) (result i32) (i64.lt_s (local.get $x) (global.get $c0)))
  (func $lt_s.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_s (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.lt_s (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_s.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left (param $x i64) (result i32) (i64.lt_s (i64.const -1) (local.get $x)))
  (func $lt_s.0.left.ref (param $x i64) (result i32) (i64.lt_s (global.get $c0) (local.get $x)))
  (func $lt_s.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_s (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left.if (param $x i64) (result i32) (if (result i32) (i64.lt_s (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.lt_s (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_s.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right (param $x i64) (result i32) (i64.lt_u (local.get $x) (i64.const -1)))
  (func $lt_u.0.right.ref (param $x i64) (result i32) (i64.lt_u (local.get $x) (global.get $c0)))
  (func $lt_u.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_u (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.lt_u (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_u.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left (param $x i64) (result i32) (i64.lt_u (i64.const -1) (local.get $x)))
  (func $lt_u.0.left.ref (param $x i64) (result i32) (i64.lt_u (global.get $c0) (local.get $x)))
  (func $lt_u.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_u (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left.if (param $x i64) (result i32) (if (result i32) (i64.lt_u (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.lt_u (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $lt_u.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right (param $x i64) (result i32) (i64.gt_s (local.get $x) (i64.const -1)))
  (func $gt_s.0.right.ref (param $x i64) (result i32) (i64.gt_s (local.get $x) (global.get $c0)))
  (func $gt_s.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_s (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.gt_s (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_s.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left (param $x i64) (result i32) (i64.gt_s (i64.const -1) (local.get $x)))
  (func $gt_s.0.left.ref (param $x i64) (result i32) (i64.gt_s (global.get $c0) (local.get $x)))
  (func $gt_s.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_s (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left.if (param $x i64) (result i32) (if (result i32) (i64.gt_s (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.gt_s (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_s.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right (param $x i64) (result i32) (i64.gt_u (local.get $x) (i64.const -1)))
  (func $gt_u.0.right.ref (param $x i64) (result i32) (i64.gt_u (local.get $x) (global.get $c0)))
  (func $gt_u.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_u (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.gt_u (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_u.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left (param $x i64) (result i32) (i64.gt_u (i64.const -1) (local.get $x)))
  (func $gt_u.0.left.ref (param $x i64) (result i32) (i64.gt_u (global.get $c0) (local.get $x)))
  (func $gt_u.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_u (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left.if (param $x i64) (result i32) (if (result i32) (i64.gt_u (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.gt_u (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $gt_u.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right (param $x i64) (result i32) (i64.le_s (local.get $x) (i64.const -1)))
  (func $le_s.0.right.ref (param $x i64) (result i32) (i64.le_s (local.get $x) (global.get $c0)))
  (func $le_s.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_s (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right.if (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.le_s (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_s.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left (param $x i64) (result i32) (i64.le_s (i64.const -1) (local.get $x)))
  (func $le_s.0.left.ref (param $x i64) (result i32) (i64.le_s (global.get $c0) (local.get $x)))
  (func $le_s.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_s (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left.if (param $x i64) (result i32) (if (result i32) (i64.le_s (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.le_s (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_s.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right (param $x i64) (result i32) (i64.le_u (local.get $x) (i64.const -1)))
  (func $le_u.0.right.ref (param $x i64) (result i32) (i64.le_u (local.get $x) (global.get $c0)))
  (func $le_u.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_u (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right.if (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.le_u (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_u.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left (param $x i64) (result i32) (i64.le_u (i64.const -1) (local.get $x)))
  (func $le_u.0.left.ref (param $x i64) (result i32) (i64.le_u (global.get $c0) (local.get $x)))
  (func $le_u.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_u (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left.if (param $x i64) (result i32) (if (result i32) (i64.le_u (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.le_u (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $le_u.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right (param $x i64) (result i32) (i64.ge_s (local.get $x) (i64.const -1)))
  (func $ge_s.0.right.ref (param $x i64) (result i32) (i64.ge_s (local.get $x) (global.get $c0)))
  (func $ge_s.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_s (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.ge_s (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_s.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left (param $x i64) (result i32) (i64.ge_s (i64.const -1) (local.get $x)))
  (func $ge_s.0.left.ref (param $x i64) (result i32) (i64.ge_s (global.get $c0) (local.get $x)))
  (func $ge_s.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_s (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left.if (param $x i64) (result i32) (if (result i32) (i64.ge_s (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.ge_s (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_s.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right (param $x i64) (result i32) (i64.ge_u (local.get $x) (i64.const -1)))
  (func $ge_u.0.right.ref (param $x i64) (result i32) (i64.ge_u (local.get $x) (global.get $c0)))
  (func $ge_u.0.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_u (local.get $x) (i64.const -1))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.0.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (i64.const -1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.right.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.ge_u (local.get $x) (i64.const -1))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_u.0.right.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left (param $x i64) (result i32) (i64.ge_u (i64.const -1) (local.get $x)))
  (func $ge_u.0.left.ref (param $x i64) (result i32) (i64.ge_u (global.get $c0) (local.get $x)))
  (func $ge_u.0.left.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_u (i64.const -1) (local.get $x))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.0.left.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left.if (param $x i64) (result i32) (if (result i32) (i64.ge_u (i64.const -1) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.0.left.eqz (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.ge_u (i64.const -1) (local.get $x))) (then (i32.const 7)) (else (i32.const 9))))
  (func $ge_u.0.left.eqz.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (global.get $c0) (local.get $x)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.0.br_if (param $x i64) (result i32) (block (br_if 0 (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const -1))))) (return (i32.const 7))) (i32.const 9))
  (func $and.0.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c0)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.0.br_if_not (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const -1)))) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.0.br_if_not.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c0)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.0 (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (i64.const -1)) (local.get $x)))
  (func $acc.0.ref (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (global.get $c0)) (local.get $x)))
  (func $super.0 (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (i64.const -1)) (local.get $x)))
  (func $super.0.ref (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (global.get $c0)) (local.get $x)))
  (func $super.sub.0 (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (i64.const -1)) (local.get $x)))
  (func $super.sub.0.ref (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (global.get $c0)) (local.get $x)))
  (func $add.1.right (param $x i64) (result i64) (i64.add (local.get $x) (i64.const -2147483648)))
  (func $add.1.right.ref (param $x i64) (result i64) (i64.add (local.get $x) (global.get $c1)))
  (func $add.1.left (param $x i64) (result i64) (i64.add (i64.const -2147483648) (local.get $x)))
  (func $add.1.left.ref (param $x i64) (result i64) (i64.add (global.get $c1) (local.get $x)))
  (func $sub.1.right (param $x i64) (result i64) (i64.sub (local.get $x) (i64.const -2147483648)))
  (func $sub.1.right.ref (param $x i64) (result i64) (i64.sub (local.get $x) (global.get $c1)))
  (func $sub.1.left (param $x i64) (result i64) (i64.sub (i64.const -2147483648) (local.get $x)))
  (func $sub.1.left.ref (param $x i64) (result i64) (i64.sub (global.get $c1) (local.get $x)))
  (func $mul.1.right (param $x i64) (result i64) (i64.mul (local.get $x) (i64.const -2147483648)))
  (func $mul.1.right.ref (param $x i64) (result i64) (i64.mul (local.get $x) (global.get $c1)))
  (func $mul.1.left (param $x i64) (result i64) (i64.mul (i64.const -2147483648) (local.get $x)))
  (func $mul.1.left.ref (param $x i64) (result i64) (i64.mul (global.get $c1) (local.get $x)))
  (func $and.1.right (param $x i64) (result i64) (i64.and (local.get $x) (i64.const -2147483648)))
  (func $and.1.right.ref (param $x i64) (result i64) (i64.and (local.get $x) (global.get $c1)))
  (func $and.1.left (param $x i64) (result i64) (i64.and (i64.const -2147483648) (local.get $x)))
  (func $and.1.left.ref (param $x i64) (result i64) (i64.and (global.get $c1) (local.get $x)))
  (func $or.1.right (param $x i64) (result i64) (i64.or (local.get $x) (i64.const -2147483648)))
  (func $or.1.right.ref (param $x i64) (result i64) (i64.or (local.get $x) (global.get $c1)))
  (func $or.1.left (param $x i64) (result i64) (i64.or (i64.const -2147483648) (local.get $x)))
  (func $or.1.left.ref (param $x i64) (result i64) (i64.or (global.get $c1) (local.get $x)))
  (func $xor.1.right (param $x i64) (result i64) (i64.xor (local.get $x) (i64.const -2147483648)))
  (func $xor.1.right.ref (param $x i64) (result i64) (i64.xor (local.get $x) (global.get $c1)))
  (func $xor.1.left (param $x i64) (result i64) (i64.xor (i64.const -2147483648) (local.get $x)))
  (func $xor.1.left.ref (param $x i64) (result i64) (i64.xor (global.get $c1) (local.get $x)))
  (func $shl.1.right (param $x i64) (result i64) (i64.shl (local.get $x) (i64.const -2147483648)))
  (func $shl.1.right.ref (param $x i64) (result i64) (i64.shl (local.get $x) (global.get $c1)))
  (func $shl.1.left (param $x i64) (result i64) (i64.shl (i64.const -2147483648) (local.get $x)))
  (func $shl.1.left.ref (param $x i64) (result i64) (i64.shl (global.get $c1) (local.get $x)))
  (func $shr_s.1.right (param $x i64) (result i64) (i64.shr_s (local.get $x) (i64.const -2147483648)))
  (func $shr_s.1.right.ref (param $x i64) (result i64) (i64.shr_s (local.get $x) (global.get $c1)))
  (func $shr_s.1.left (param $x i64) (result i64) (i64.shr_s (i64.const -2147483648) (local.get $x)))
  (func $shr_s.1.left.ref (param $x i64) (result i64) (i64.shr_s (global.get $c1) (local.get $x)))
  (func $shr_u.1.right (param $x i64) (result i64) (i64.shr_u (local.get $x) (i64.const -2147483648)))
  (func $shr_u.1.right.ref (param $x i64) (result i64) (i64.shr_u (local.get $x) (global.get $c1)))
  (func $shr_u.1.left (param $x i64) (result i64) (i64.shr_u (i64.const -2147483648) (local.get $x)))
  (func $shr_u.1.left.ref (param $x i64) (result i64) (i64.shr_u (global.get $c1) (local.get $x)))
  (func $rotl.1.right (param $x i64) (result i64) (i64.rotl (local.get $x) (i64.const -2147483648)))
  (func $rotl.1.right.ref (param $x i64) (result i64) (i64.rotl (local.get $x) (global.get $c1)))
  (func $rotl.1.left (param $x i64) (result i64) (i64.rotl (i64.const -2147483648) (local.get $x)))
  (func $rotl.1.left.ref (param $x i64) (result i64) (i64.rotl (global.get $c1) (local.get $x)))
  (func $rotr.1.right (param $x i64) (result i64) (i64.rotr (local.get $x) (i64.const -2147483648)))
  (func $rotr.1.right.ref (param $x i64) (result i64) (i64.rotr (local.get $x) (global.get $c1)))
  (func $rotr.1.left (param $x i64) (result i64) (i64.rotr (i64.const -2147483648) (local.get $x)))
  (func $rotr.1.left.ref (param $x i64) (result i64) (i64.rotr (global.get $c1) (local.get $x)))
  (func $eq.1.right (param $x i64) (result i32) (i64.eq (local.get $x) (i64.const -2147483648)))
  (func $eq.1.right.ref (param $x i64) (result i32) (i64.eq (local.get $x) (global.get $c1)))
  (func $eq.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.eq (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $eq.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.1.right.if (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.1.right (param $x i64) (result i32) (i64.ne (local.get $x) (i64.const -2147483648)))
  (func $ne.1.right.ref (param $x i64) (result i32) (i64.ne (local.get $x) (global.get $c1)))
  (func $ne.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ne (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ne.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.1.right.if (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.1.right (param $x i64) (result i32) (i64.lt_s (local.get $x) (i64.const -2147483648)))
  (func $lt_s.1.right.ref (param $x i64) (result i32) (i64.lt_s (local.get $x) (global.get $c1)))
  (func $lt_s.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_s (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.1.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.1.right (param $x i64) (result i32) (i64.lt_u (local.get $x) (i64.const -2147483648)))
  (func $lt_u.1.right.ref (param $x i64) (result i32) (i64.lt_u (local.get $x) (global.get $c1)))
  (func $lt_u.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_u (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.1.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.1.right (param $x i64) (result i32) (i64.gt_s (local.get $x) (i64.const -2147483648)))
  (func $gt_s.1.right.ref (param $x i64) (result i32) (i64.gt_s (local.get $x) (global.get $c1)))
  (func $gt_s.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_s (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.1.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.1.right (param $x i64) (result i32) (i64.gt_u (local.get $x) (i64.const -2147483648)))
  (func $gt_u.1.right.ref (param $x i64) (result i32) (i64.gt_u (local.get $x) (global.get $c1)))
  (func $gt_u.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_u (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.1.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.1.right (param $x i64) (result i32) (i64.le_s (local.get $x) (i64.const -2147483648)))
  (func $le_s.1.right.ref (param $x i64) (result i32) (i64.le_s (local.get $x) (global.get $c1)))
  (func $le_s.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_s (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.1.right.if (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.1.right (param $x i64) (result i32) (i64.le_u (local.get $x) (i64.const -2147483648)))
  (func $le_u.1.right.ref (param $x i64) (result i32) (i64.le_u (local.get $x) (global.get $c1)))
  (func $le_u.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_u (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.1.right.if (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.1.right (param $x i64) (result i32) (i64.ge_s (local.get $x) (i64.const -2147483648)))
  (func $ge_s.1.right.ref (param $x i64) (result i32) (i64.ge_s (local.get $x) (global.get $c1)))
  (func $ge_s.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_s (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.1.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.1.right (param $x i64) (result i32) (i64.ge_u (local.get $x) (i64.const -2147483648)))
  (func $ge_u.1.right.ref (param $x i64) (result i32) (i64.ge_u (local.get $x) (global.get $c1)))
  (func $ge_u.1.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_u (local.get $x) (i64.const -2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.1.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.1.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (i64.const -2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.1.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c1)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.1.br_if (param $x i64) (result i32) (block (br_if 0 (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const -2147483648))))) (return (i32.const 7))) (i32.const 9))
  (func $and.1.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c1)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.1.br_if_not (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const -2147483648)))) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.1.br_if_not.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c1)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.1 (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (i64.const -2147483648)) (local.get $x)))
  (func $acc.1.ref (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (global.get $c1)) (local.get $x)))
  (func $super.1 (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (i64.const -2147483648)) (local.get $x)))
  (func $super.1.ref (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (global.get $c1)) (local.get $x)))
  (func $super.sub.1 (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (i64.const -2147483648)) (local.get $x)))
  (func $super.sub.1.ref (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (global.get $c1)) (local.get $x)))
  (func $add.2.right (param $x i64) (result i64) (i64.add (local.get $x) (i64.const 2147483648)))
  (func $add.2.right.ref (param $x i64) (result i64) (i64.add (local.get $x) (global.get $c2)))
  (func $add.2.left (param $x i64) (result i64) (i64.add (i64.const 2147483648) (local.get $x)))
  (func $add.2.left.ref (param $x i64) (result i64) (i64.add (global.get $c2) (local.get $x)))
  (func $sub.2.right (param $x i64) (result i64) (i64.sub (local.get $x) (i64.const 2147483648)))
  (func $sub.2.right.ref (param $x i64) (result i64) (i64.sub (local.get $x) (global.get $c2)))
  (func $sub.2.left (param $x i64) (result i64) (i64.sub (i64.const 2147483648) (local.get $x)))
  (func $sub.2.left.ref (param $x i64) (result i64) (i64.sub (global.get $c2) (local.get $x)))
  (func $mul.2.right (param $x i64) (result i64) (i64.mul (local.get $x) (i64.const 2147483648)))
  (func $mul.2.right.ref (param $x i64) (result i64) (i64.mul (local.get $x) (global.get $c2)))
  (func $mul.2.left (param $x i64) (result i64) (i64.mul (i64.const 2147483648) (local.get $x)))
  (func $mul.2.left.ref (param $x i64) (result i64) (i64.mul (global.get $c2) (local.get $x)))
  (func $and.2.right (param $x i64) (result i64) (i64.and (local.get $x) (i64.const 2147483648)))
  (func $and.2.right.ref (param $x i64) (result i64) (i64.and (local.get $x) (global.get $c2)))
  (func $and.2.left (param $x i64) (result i64) (i64.and (i64.const 2147483648) (local.get $x)))
  (func $and.2.left.ref (param $x i64) (result i64) (i64.and (global.get $c2) (local.get $x)))
  (func $or.2.right (param $x i64) (result i64) (i64.or (local.get $x) (i64.const 2147483648)))
  (func $or.2.right.ref (param $x i64) (result i64) (i64.or (local.get $x) (global.get $c2)))
  (func $or.2.left (param $x i64) (result i64) (i64.or (i64.const 2147483648) (local.get $x)))
  (func $or.2.left.ref (param $x i64) (result i64) (i64.or (global.get $c2) (local.get $x)))
  (func $xor.2.right (param $x i64) (result i64) (i64.xor (local.get $x) (i64.const 2147483648)))
  (func $xor.2.right.ref (param $x i64) (result i64) (i64.xor (local.get $x) (global.get $c2)))
  (func $xor.2.left (param $x i64) (result i64) (i64.xor (i64.const 2147483648) (local.get $x)))
  (func $xor.2.left.ref (param $x i64) (result i64) (i64.xor (global.get $c2) (local.get $x)))
  (func $shl.2.right (param $x i64) (result i64) (i64.shl (local.get $x) (i64.const 2147483648)))
  (func $shl.2.right.ref (param $x i64) (result i64) (i64.shl (local.get $x) (global.get $c2)))
  (func $shl.2.left (param $x i64) (result i64) (i64.shl (i64.const 2147483648) (local.get $x)))
  (func $shl.2.left.ref (param $x i64) (result i64) (i64.shl (global.get $c2) (local.get $x)))
  (func $shr_s.2.right (param $x i64) (result i64) (i64.shr_s (local.get $x) (i64.const 2147483648)))
  (func $shr_s.2.right.ref (param $x i64) (result i64) (i64.shr_s (local.get $x) (global.get $c2)))
  (func $shr_s.2.left (param $x i64) (result i64) (i64.shr_s (i64.const 2147483648) (local.get $x)))
  (func $shr_s.2.left.ref (param $x i64) (result i64) (i64.shr_s (global.get $c2) (local.get $x)))
  (func $shr_u.2.right (param $x i64) (result i64) (i64.shr_u (local.get $x) (i64.const 2147483648)))
  (func $shr_u.2.right.ref (param $x i64) (result i64) (i64.shr_u (local.get $x) (global.get $c2)))
  (func $shr_u.2.left (param $x i64) (result i64) (i64.shr_u (i64.const 2147483648) (local.get $x)))
  (func $shr_u.2.left.ref (param $x i64) (result i64) (i64.shr_u (global.get $c2) (local.get $x)))
  (func $rotl.2.right (param $x i64) (result i64) (i64.rotl (local.get $x) (i64.const 2147483648)))
  (func $rotl.2.right.ref (param $x i64) (result i64) (i64.rotl (local.get $x) (global.get $c2)))
  (func $rotl.2.left (param $x i64) (result i64) (i64.rotl (i64.const 2147483648) (local.get $x)))
  (func $rotl.2.left.ref (param $x i64) (result i64) (i64.rotl (global.get $c2) (local.get $x)))
  (func $rotr.2.right (param $x i64) (result i64) (i64.rotr (local.get $x) (i64.const 2147483648)))
  (func $rotr.2.right.ref (param $x i64) (result i64) (i64.rotr (local.get $x) (global.get $c2)))
  (func $rotr.2.left (param $x i64) (result i64) (i64.rotr (i64.const 2147483648) (local.get $x)))
  (func $rotr.2.left.ref (param $x i64) (result i64) (i64.rotr (global.get $c2) (local.get $x)))
  (func $eq.2.right (param $x i64) (result i32) (i64.eq (local.get $x) (i64.const 2147483648)))
  (func $eq.2.right.ref (param $x i64) (result i32) (i64.eq (local.get $x) (global.get $c2)))
  (func $eq.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.eq (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $eq.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.2.right.if (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.2.right (param $x i64) (result i32) (i64.ne (local.get $x) (i64.const 2147483648)))
  (func $ne.2.right.ref (param $x i64) (result i32) (i64.ne (local.get $x) (global.get $c2)))
  (func $ne.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ne (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ne.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.2.right.if (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.2.right (param $x i64) (result i32) (i64.lt_s (local.get $x) (i64.const 2147483648)))
  (func $lt_s.2.right.ref (param $x i64) (result i32) (i64.lt_s (local.get $x) (global.get $c2)))
  (func $lt_s.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_s (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.2.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.2.right (param $x i64) (result i32) (i64.lt_u (local.get $x) (i64.const 2147483648)))
  (func $lt_u.2.right.ref (param $x i64) (result i32) (i64.lt_u (local.get $x) (global.get $c2)))
  (func $lt_u.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_u (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.2.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.2.right (param $x i64) (result i32) (i64.gt_s (local.get $x) (i64.const 2147483648)))
  (func $gt_s.2.right.ref (param $x i64) (result i32) (i64.gt_s (local.get $x) (global.get $c2)))
  (func $gt_s.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_s (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.2.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.2.right (param $x i64) (result i32) (i64.gt_u (local.get $x) (i64.const 2147483648)))
  (func $gt_u.2.right.ref (param $x i64) (result i32) (i64.gt_u (local.get $x) (global.get $c2)))
  (func $gt_u.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_u (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.2.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.2.right (param $x i64) (result i32) (i64.le_s (local.get $x) (i64.const 2147483648)))
  (func $le_s.2.right.ref (param $x i64) (result i32) (i64.le_s (local.get $x) (global.get $c2)))
  (func $le_s.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_s (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.2.right.if (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.2.right (param $x i64) (result i32) (i64.le_u (local.get $x) (i64.const 2147483648)))
  (func $le_u.2.right.ref (param $x i64) (result i32) (i64.le_u (local.get $x) (global.get $c2)))
  (func $le_u.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_u (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.2.right.if (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.2.right (param $x i64) (result i32) (i64.ge_s (local.get $x) (i64.const 2147483648)))
  (func $ge_s.2.right.ref (param $x i64) (result i32) (i64.ge_s (local.get $x) (global.get $c2)))
  (func $ge_s.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_s (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.2.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.2.right (param $x i64) (result i32) (i64.ge_u (local.get $x) (i64.const 2147483648)))
  (func $ge_u.2.right.ref (param $x i64) (result i32) (i64.ge_u (local.get $x) (global.get $c2)))
  (func $ge_u.2.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_u (local.get $x) (i64.const 2147483648))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.2.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.2.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (i64.const 2147483648)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.2.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c2)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.2.br_if (param $x i64) (result i32) (block (br_if 0 (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const 2147483648))))) (return (i32.const 7))) (i32.const 9))
  (func $and.2.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c2)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.2.br_if_not (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const 2147483648)))) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.2.br_if_not.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c2)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.2 (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (i64.const 2147483648)) (local.get $x)))
  (func $acc.2.ref (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (global.get $c2)) (local.get $x)))
  (func $super.2 (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (i64.const 2147483648)) (local.get $x)))
  (func $super.2.ref (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (global.get $c2)) (local.get $x)))
  (func $super.sub.2 (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (i64.const 2147483648)) (local.get $x)))
  (func $super.sub.2.ref (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (global.get $c2)) (local.get $x)))
  (func $add.3.right (param $x i64) (result i64) (i64.add (local.get $x) (i64.const 4294967301)))
  (func $add.3.right.ref (param $x i64) (result i64) (i64.add (local.get $x) (global.get $c3)))
  (func $add.3.left (param $x i64) (result i64) (i64.add (i64.const 4294967301) (local.get $x)))
  (func $add.3.left.ref (param $x i64) (result i64) (i64.add (global.get $c3) (local.get $x)))
  (func $sub.3.right (param $x i64) (result i64) (i64.sub (local.get $x) (i64.const 4294967301)))
  (func $sub.3.right.ref (param $x i64) (result i64) (i64.sub (local.get $x) (global.get $c3)))
  (func $sub.3.left (param $x i64) (result i64) (i64.sub (i64.const 4294967301) (local.get $x)))
  (func $sub.3.left.ref (param $x i64) (result i64) (i64.sub (global.get $c3) (local.get $x)))
  (func $mul.3.right (param $x i64) (result i64) (i64.mul (local.get $x) (i64.const 4294967301)))
  (func $mul.3.right.ref (param $x i64) (result i64) (i64.mul (local.get $x) (global.get $c3)))
  (func $mul.3.left (param $x i64) (result i64) (i64.mul (i64.const 4294967301) (local.get $x)))
  (func $mul.3.left.ref (param $x i64) (result i64) (i64.mul (global.get $c3) (local.get $x)))
  (func $and.3.right (param $x i64) (result i64) (i64.and (local.get $x) (i64.const 4294967301)))
  (func $and.3.right.ref (param $x i64) (result i64) (i64.and (local.get $x) (global.get $c3)))
  (func $and.3.left (param $x i64) (result i64) (i64.and (i64.const 4294967301) (local.get $x)))
  (func $and.3.left.ref (param $x i64) (result i64) (i64.and (global.get $c3) (local.get $x)))
  (func $or.3.right (param $x i64) (result i64) (i64.or (local.get $x) (i64.const 4294967301)))
  (func $or.3.right.ref (param $x i64) (result i64) (i64.or (local.get $x) (global.get $c3)))
  (func $or.3.left (param $x i64) (result i64) (i64.or (i64.const 4294967301) (local.get $x)))
  (func $or.3.left.ref (param $x i64) (result i64) (i64.or (global.get $c3) (local.get $x)))
  (func $xor.3.right (param $x i64) (result i64) (i64.xor (local.get $x) (i64.const 4294967301)))
  (func $xor.3.right.ref (param $x i64) (result i64) (i64.xor (local.get $x) (global.get $c3)))
  (func $xor.3.left (param $x i64) (result i64) (i64.xor (i64.const 4294967301) (local.get $x)))
  (func $xor.3.left.ref (param $x i64) (result i64) (i64.xor (global.get $c3) (local.get $x)))
  (func $shl.3.right (param $x i64) (result i64) (i64.shl (local.get $x) (i64.const 4294967301)))
  (func $shl.3.right.ref (param $x i64) (result i64) (i64.shl (local.get $x) (global.get $c3)))
  (func $shl.3.left (param $x i64) (result i64) (i64.shl (i64.const 4294967301) (local.get $x)))
  (func $shl.3.left.ref (param $x i64) (result i64) (i64.shl (global.get $c3) (local.get $x)))
  (func $shr_s.3.right (param $x i64) (result i64) (i64.shr_s (local.get $x) (i64.const 4294967301)))
  (func $shr_s.3.right.ref (param $x i64) (result i64) (i64.shr_s (local.get $x) (global.get $c3)))
  (func $shr_s.3.left (param $x i64) (result i64) (i64.shr_s (i64.const 4294967301) (local.get $x)))
  (func $shr_s.3.left.ref (param $x i64) (result i64) (i64.shr_s (global.get $c3) (local.get $x)))
  (func $shr_u.3.right (param $x i64) (result i64) (i64.shr_u (local.get $x) (i64.const 4294967301)))
  (func $shr_u.3.right.ref (param $x i64) (result i64) (i64.shr_u (local.get $x) (global.get $c3)))
  (func $shr_u.3.left (param $x i64) (result i64) (i64.shr_u (i64.const 4294967301) (local.get $x)))
  (func $shr_u.3.left.ref (param $x i64) (result i64) (i64.shr_u (global.get $c3) (local.get $x)))
  (func $rotl.3.right (param $x i64) (result i64) (i64.rotl (local.get $x) (i64.const 4294967301)))
  (func $rotl.3.right.ref (param $x i64) (result i64) (i64.rotl (local.get $x) (global.get $c3)))
  (func $rotl.3.left (param $x i64) (result i64) (i64.rotl (i64.const 4294967301) (local.get $x)))
  (func $rotl.3.left.ref (param $x i64) (result i64) (i64.rotl (global.get $c3) (local.get $x)))
  (func $rotr.3.right (param $x i64) (result i64) (i64.rotr (local.get $x) (i64.const 4294967301)))
  (func $rotr.3.right.ref (param $x i64) (result i64) (i64.rotr (local.get $x) (global.get $c3)))
  (func $rotr.3.left (param $x i64) (result i64) (i64.rotr (i64.const 4294967301) (local.get $x)))
  (func $rotr.3.left.ref (param $x i64) (result i64) (i64.rotr (global.get $c3) (local.get $x)))
  (func $eq.3.right (param $x i64) (result i32) (i64.eq (local.get $x) (i64.const 4294967301)))
  (func $eq.3.right.ref (param $x i64) (result i32) (i64.eq (local.get $x) (global.get $c3)))
  (func $eq.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.eq (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $eq.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.3.right.if (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $eq.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.eq (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.3.right (param $x i64) (result i32) (i64.ne (local.get $x) (i64.const 4294967301)))
  (func $ne.3.right.ref (param $x i64) (result i32) (i64.ne (local.get $x) (global.get $c3)))
  (func $ne.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ne (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $ne.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.3.right.if (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ne.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.3.right (param $x i64) (result i32) (i64.lt_s (local.get $x) (i64.const 4294967301)))
  (func $lt_s.3.right.ref (param $x i64) (result i32) (i64.lt_s (local.get $x) (global.get $c3)))
  (func $lt_s.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_s (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $lt_s.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.3.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_s.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.3.right (param $x i64) (result i32) (i64.lt_u (local.get $x) (i64.const 4294967301)))
  (func $lt_u.3.right.ref (param $x i64) (result i32) (i64.lt_u (local.get $x) (global.get $c3)))
  (func $lt_u.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.lt_u (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $lt_u.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.3.right.if (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $lt_u.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.lt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.3.right (param $x i64) (result i32) (i64.gt_s (local.get $x) (i64.const 4294967301)))
  (func $gt_s.3.right.ref (param $x i64) (result i32) (i64.gt_s (local.get $x) (global.get $c3)))
  (func $gt_s.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_s (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $gt_s.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.3.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_s.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.3.right (param $x i64) (result i32) (i64.gt_u (local.get $x) (i64.const 4294967301)))
  (func $gt_u.3.right.ref (param $x i64) (result i32) (i64.gt_u (local.get $x) (global.get $c3)))
  (func $gt_u.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.gt_u (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $gt_u.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.3.right.if (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $gt_u.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.gt_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.3.right (param $x i64) (result i32) (i64.le_s (local.get $x) (i64.const 4294967301)))
  (func $le_s.3.right.ref (param $x i64) (result i32) (i64.le_s (local.get $x) (global.get $c3)))
  (func $le_s.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_s (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $le_s.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.3.right.if (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_s.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.3.right (param $x i64) (result i32) (i64.le_u (local.get $x) (i64.const 4294967301)))
  (func $le_u.3.right.ref (param $x i64) (result i32) (i64.le_u (local.get $x) (global.get $c3)))
  (func $le_u.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.le_u (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $le_u.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.3.right.if (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $le_u.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.le_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.3.right (param $x i64) (result i32) (i64.ge_s (local.get $x) (i64.const 4294967301)))
  (func $ge_s.3.right.ref (param $x i64) (result i32) (i64.ge_s (local.get $x) (global.get $c3)))
  (func $ge_s.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_s (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $ge_s.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.3.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_s.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_s (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.3.right (param $x i64) (result i32) (i64.ge_u (local.get $x) (i64.const 4294967301)))
  (func $ge_u.3.right.ref (param $x i64) (result i32) (i64.ge_u (local.get $x) (global.get $c3)))
  (func $ge_u.3.right.br_if (param $x i64) (result i32) (block (br_if 0 (i64.ge_u (local.get $x) (i64.const 4294967301))) (return (i32.const 7))) (i32.const 9))
  (func $ge_u.3.right.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.3.right.if (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (i64.const 4294967301)) (then (i32.const 9)) (else (i32.const 7))))
  (func $ge_u.3.right.if.ref (param $x i64) (result i32) (if (result i32) (i64.ge_u (local.get $x) (global.get $c3)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.3.br_if (param $x i64) (result i32) (block (br_if 0 (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const 4294967301))))) (return (i32.const 7))) (i32.const 9))
  (func $and.3.br_if.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c3)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.3.br_if_not (param $x i64) (result i32) (if (result i32) (i32.eqz (i64.eqz (i64.and (local.get $x) (i64.const 4294967301)))) (then (i32.const 9)) (else (i32.const 7))))
  (func $and.3.br_if_not.ref (param $x i64) (result i32) (if (result i32) (i64.ne (i64.and (local.get $x) (global.get $c3)) (i64.const 0)) (then (i32.const 9)) (else (i32.const 7))))
  (func $acc.3 (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (i64.const 4294967301)) (local.get $x)))
  (func $acc.3.ref (param $x i64) (result i64) (i64.rotr (i64.sub (local.get $x) (global.get $c3)) (local.get $x)))
  (func $super.3 (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (i64.const 4294967301)) (local.get $x)))
  (func $super.3.ref (param $x i64) (result i64) (i64.add (i64.shl (local.get $x) (global.get $c3)) (local.get $x)))
  (func $super.sub.3 (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (i64.const 4294967301)) (local.get $x)))
  (func $super.sub.3.ref (param $x i64) (result i64) (i64.and (i64.sub (local.get $x) (global.get $c3)) (local.get $x)))
  (type $fi64 (func (param $x i64) (result i64)))
  (type $fi32 (func (param $x i64) (result i32)))
  (table funcref (elem $add.0.right $add.0.right.ref $add.0.left $add.0.left.ref $sub.0.right $sub.0.right.ref $sub.0.left $sub.0.left.ref $mul.0.right $mul.0.right.ref $mul.0.left $mul.0.left.ref $and.0.right $and.0.right.ref $and.0.left $and.0.left.ref $or.0.right $or.0.right.ref $or.0.left $or.0.left.ref $xor.0.right $xor.0.right.ref $xor.0.left $xor.0.left.ref $shl.0.right $shl.0.right.ref $shl.0.left $shl.0.left.ref $shr_s.0.right $shr_s.0.right.ref $shr_s.0.left $shr_s.0.left.ref $shr_u.0.right $shr_u.0.right.ref $shr_u.0.left $shr_u.0.left.ref $rotl.0.right $rotl.0.right.ref $rotl.0.left $rotl.0.left.ref $rotr.0.right $rotr.0.right.ref $rotr.0.left $rotr.0.left.ref $eq.0.right $eq.0.right.ref $eq.0.right.br_if $eq.0.right.br_if.ref $eq.0.right.if $eq.0.right.if.ref $eq.0.right.eqz $eq.0.right.eqz.ref $eq.0.left $eq.0.left.ref $eq.0.left.br_if $eq.0.left.br_if.ref $eq.0.left.if $eq.0.left.if.ref $eq.0.left.eqz $eq.0.left.eqz.ref $ne.0.right $ne.0.right.ref $ne.0.right.br_if $ne.0.right.br_if.ref $ne.0.right.if $ne.0.right.if.ref $ne.0.right.eqz $ne.0.right.eqz.ref $ne.0.left $ne.0.left.ref $ne.0.left.br_if $ne.0.left.br_if.ref $ne.0.left.if $ne.0.left.if.ref $ne.0.left.eqz $ne.0.left.eqz.ref $lt_s.0.right $lt_s.0.right.ref $lt_s.0.right.br_if $lt_s.0.right.br_if.ref $lt_s.0.right.if $lt_s.0.right.if.ref $lt_s.0.right.eqz $lt_s.0.right.eqz.ref $lt_s.0.left $lt_s.0.left.ref $lt_s.0.left.br_if $lt_s.0.left.br_if.ref $lt_s.0.left.if $lt_s.0.left.if.ref $lt_s.0.left.eqz $lt_s.0.left.eqz.ref $lt_u.0.right $lt_u.0.right.ref $lt_u.0.right.br_if $lt_u.0.right.br_if.ref $lt_u.0.right.if $lt_u.0.right.if.ref $lt_u.0.right.eqz $lt_u.0.right.eqz.ref $lt_u.0.left $lt_u.0.left.ref $lt_u.0.left.br_if $lt_u.0.left.br_if.ref $lt_u.0.left.if $lt_u.0.left.if.ref $lt_u.0.left.eqz $lt_u.0.left.eqz.ref $gt_s.0.right $gt_s.0.right.ref $gt_s.0.right.br_if $gt_s.0.right.br_if.ref $gt_s.0.right.if $gt_s.0.right.if.ref $gt_s.0.right.eqz $gt_s.0.right.eqz.ref $gt_s.0.left $gt_s.0.left.ref $gt_s.0.left.br_if $gt_s.0.left.br_if.ref $gt_s.0.left.if $gt_s.0.left.if.ref $gt_s.0.left.eqz $gt_s.0.left.eqz.ref $gt_u.0.right $gt_u.0.right.ref $gt_u.0.right.br_if $gt_u.0.right.br_if.ref $gt_u.0.right.if $gt_u.0.right.if.ref $gt_u.0.right.eqz $gt_u.0.right.eqz.ref $gt_u.0.left $gt_u.0.left.ref $gt_u.0.left.br_if $gt_u.0.left.br_if.ref $gt_u.0.left.if $gt_u.0.left.if.ref $gt_u.0.left.eqz $gt_u.0.left.eqz.ref $le_s.0.right $le_s.0.right.ref $le_s.0.right.br_if $le_s.0.right.br_if.ref $le_s.0.right.if $le_s.0.right.if.ref $le_s.0.right.eqz $le_s.0.right.eqz.ref $le_s.0.left $le_s.0.left.ref $le_s.0.left.br_if $le_s.0.left.br_if.ref $le_s.0.left.if $le_s.0.left.if.ref $le_s.0.left.eqz $le_s.0.left.eqz.ref $le_u.0.right $le_u.0.right.ref $le_u.0.right.br_if $le_u.0.right.br_if.ref $le_u.0.right.if $le_u.0.right.if.ref $le_u.0.right.eqz $le_u.0.right.eqz.ref $le_u.0.left $le_u.0.left.ref $le_u.0.left.br_if $le_u.0.left.br_if.ref $le_u.0.left.if $le_u.0.left.if.ref $le_u.0.left.eqz $le_u.0.left.eqz.ref $ge_s.0.right $ge_s.0.right.ref $ge_s.0.right.br_if $ge_s.0.right.br_if.ref $ge_s.0.right.if $ge_s.0.right.if.ref $ge_s.0.right.eqz $ge_s.0.right.eqz.ref $ge_s.0.left $ge_s.0.left.ref $ge_s.0.left.br_if $ge_s.0.left.br_if.ref $ge_s.0.left.if $ge_s.0.left.if.ref $ge_s.0.left.eqz $ge_s.0.left.eqz.ref $ge_u.0.right $ge_u.0.right.ref $ge_u.0.right.br_if $ge_u.0.right.br_if.ref $ge_u.0.right.if $ge_u.0.right.if.ref $ge_u.0.right.eqz $ge_u.0.right.eqz.ref $ge_u.0.left $ge_u.0.left.ref $ge_u.0.left.br_if $ge_u.0.left.br_if.ref $ge_u.0.left.if $ge_u.0.left.if.ref $ge_u.0.left.eqz $ge_u.0.left.eqz.ref $and.0.br_if $and.0.br_if.ref $and.0.br_if_not $and.0.br_if_not.ref $acc.0 $acc.0.ref $super.0 $super.0.ref $super.sub.0 $super.sub.0.ref $add.1.right $add.1.right.ref $add.1.left $add.1.left.ref $sub.1.right $sub.1.right.ref $sub.1.left $sub.1.left.ref $mul.1.right $mul.1.right.ref $mul.1.left $mul.1.left.ref $and.1.right $and.1.right.ref $and.1.left $and.1.left.ref $or.1.right $or.1.right.ref $or.1.left $or.1.left.ref $xor.1.right $xor.1.right.ref $xor.1.left $xor.1.left.ref $shl.1.right $shl.1.right.ref $shl.1.left $shl.1.left.ref $shr_s.1.right $shr_s.1.right.ref $shr_s.1.left $shr_s.1.left.ref $shr_u.1.right $shr_u.1.right.ref $shr_u.1.left $shr_u.1.left.ref $rotl.1.right $rotl.1.right.ref $rotl.1.left $rotl.1.left.ref $rotr.1.right $rotr.1.right.ref $rotr.1.left $rotr.1.left.ref $eq.1.right $eq.1.right.ref $eq.1.right.br_if $eq.1.right.br_if.ref $eq.1.right.if $eq.1.right.if.ref $ne.1.right $ne.1.right.ref $ne.1.right.br_if $ne.1.right.br_if.ref $ne.1.right.if $ne.1.right.if.ref $lt_s.1.right $lt_s.1.right.ref $lt_s.1.right.br_if $lt_s.1.right.br_if.ref $lt_s.1.right.if $lt_s.1.right.if.ref $lt_u.1.right $lt_u.1.right.ref $lt_u.1.right.br_if $lt_u.1.right.br_if.ref $lt_u.1.right.if $lt_u.1.right.if.ref $gt_s.1.right $gt_s.1.right.ref $gt_s.1.right.br_if $gt_s.1.right.br_if.ref $gt_s.1.right.if $gt_s.1.right.if.ref $gt_u.1.right $gt_u.1.right.ref $gt_u.1.right.br_if $gt_u.1.right.br_if.ref $gt_u.1.right.if $gt_u.1.right.if.ref $le_s.1.right $le_s.1.right.ref $le_s.1.right.br_if $le_s.1.right.br_if.ref $le_s.1.right.if $le_s.1.right.if.ref $le_u.1.right $le_u.1.right.ref $le_u.1.right.br_if $le_u.1.right.br_if.ref $le_u.1.right.if $le_u.1.right.if.ref $ge_s.1.right $ge_s.1.right.ref $ge_s.1.right.br_if $ge_s.1.right.br_if.ref $ge_s.1.right.if $ge_s.1.right.if.ref $ge_u.1.right $ge_u.1.right.ref $ge_u.1.right.br_if $ge_u.1.right.br_if.ref $ge_u.1.right.if $ge_u.1.right.if.ref $and.1.br_if $and.1.br_if.ref $and.1.br_if_not $and.1.br_if_not.ref $acc.1 $acc.1.ref $super.1 $super.1.ref $super.sub.1 $super.sub.1.ref $add.2.right $add.2.right.ref $add.2.left $add.2.left.ref $sub.2.right $sub.2.right.ref $sub.2.left $sub.2.left.ref $mul.2.right $mul.2.right.ref $mul.2.left $mul.2.left.ref $and.2.right $and.2.right.ref $and.2.left $and.2.left.ref $or.2.right $or.2.right.ref $or.2.left $or.2.left.ref $xor.2.right $xor.2.right.ref $xor.2.left $xor.2.left.ref $shl.2.right $shl.2.right.ref $shl.2.left $shl.2.left.ref $shr_s.2.right $shr_s.2.right.ref $shr_s.2.left $shr_s.2.left.ref $shr_u.2.right $shr_u.2.right.ref $shr_u.2.left $shr_u.2.left.ref $rotl.2.right $rotl.2.right.ref $rotl.2.left $rotl.2.left.ref $rotr.2.right $rotr.2.right.ref $rotr.2.left $rotr.2.left.ref $eq.2.right $eq.2.right.ref $eq.2.right.br_if $eq.2.right.br_if.ref $eq.2.right.if $eq.2.right.if.ref $ne.2.right $ne.2.right.ref $ne.2.right.br_if $ne.2.right.br_if.ref $ne.2.right.if $ne.2.right.if.ref $lt_s.2.right $lt_s.2.right.ref $lt_s.2.right.br_if $lt_s.2.right.br_if.ref $lt_s.2.right.if $lt_s.2.right.if.ref $lt_u.2.right $lt_u.2.right.ref $lt_u.2.right.br_if $lt_u.2.right.br_if.ref $lt_u.2.right.if $lt_u.2.right.if.ref $gt_s.2.right $gt_s.2.right.ref $gt_s.2.right.br_if $gt_s.2.right.br_if.ref $gt_s.2.right.if $gt_s.2.right.if.ref $gt_u.2.right $gt_u.2.right.ref $gt_u.2.right.br_if $gt_u.2.right.br_if.ref $gt_u.2.right.if $gt_u.2.right.if.ref $le_s.2.right $le_s.2.right.ref $le_s.2.right.br_if $le_s.2.right.br_if.ref $le_s.2.right.if $le_s.2.right.if.ref $le_u.2.right $le_u.2.right.ref $le_u.2.right.br_if $le_u.2.right.br_if.ref $le_u.2.right.if $le_u.2.right.if.ref $ge_s.2.right $ge_s.2.right.ref $ge_s.2.right.br_if $ge_s.2.right.br_if.ref $ge_s.2.right.if $ge_s.2.right.if.ref $ge_u.2.right $ge_u.2.right.ref $ge_u.2.right.br_if $ge_u.2.right.br_if.ref $ge_u.2.right.if $ge_u.2.right.if.ref $and.2.br_if $and.2.br_if.ref $and.2.br_if_not $and.2.br_if_not.ref $acc.2 $acc.2.ref $super.2 $super.2.ref $super.sub.2 $super.sub.2.ref $add.3.right $add.3.right.ref $add.3.left $add.3.left.ref $sub.3.right $sub.3.right.ref $sub.3.left $sub.3.left.ref $mul.3.right $mul.3.right.ref $mul.3.left $mul.3.left.ref $and.3.right $and.3.right.ref $and.3.left $and.3.left.ref $or.3.right $or.3.right.ref $or.3.left $or.3.left.ref $xor.3.right $xor.3.right.ref $xor.3.left $xor.3.left.ref $shl.3.right $shl.3.right.ref $shl.3.left $shl.3.left.ref $shr_s.3.right $shr_s.3.right.ref $shr_s.3.left $shr_s.3.left.ref $shr_u.3.right $shr_u.3.right.ref $shr_u.3.left $shr_u.3.left.ref $rotl.3.right $rotl.3.right.ref $rotl.3.left $rotl.3.left.ref $rotr.3.right $rotr.3.right.ref $rotr.3.left $rotr.3.left.ref $eq.3.right $eq.3.right.ref $eq.3.right.br_if $eq.3.right.br_if.ref $eq.3.right.if $eq.3.right.if.ref $ne.3.right $ne.3.right.ref $ne.3.right.br_if $ne.3.right.br_if.ref $ne.3.right.if $ne.3.right.if.ref $lt_s.3.right $lt_s.3.right.ref $lt_s.3.right.br_if $lt_s.3.right.br_if.ref $lt_s.3.right.if $lt_s.3.right.if.ref $lt_u.3.right $lt_u.3.right.ref $lt_u.3.right.br_if $lt_u.3.right.br_if.ref $lt_u.3.right.if $lt_u.3.right.if.ref $gt_s.3.right $gt_s.3.right.ref $gt_s.3.right.br_if $gt_s.3.right.br_if.ref $gt_s.3.right.if $gt_s.3.right.if.ref $gt_u.3.right $gt_u.3.right.ref $gt_u.3.right.br_if $gt_u.3.right.br_if.ref $gt_u.3.right.if $gt_u.3.right.if.ref $le_s.3.right $le_s.3.right.ref $le_s.3.right.br_if $le_s.3.right.br_if.ref $le_s.3.right.if $le_s.3.right.if.ref $le_u.3.right $le_u.3.right.ref $le_u.3.right.br_if $le_u.3.right.br_if.ref $le_u.3.right.if $le_u.3.right.if.ref $ge_s.3.right $ge_s.3.right.ref $ge_s.3.right.br_if $ge_s.3.right.br_if.ref $ge_s.3.right.if $ge_s.3.right.if.ref $ge_u.3.right $ge_u.3.right.ref $ge_u.3.right.br_if $ge_u.3.right.br_if.ref $ge_u.3.right.if $ge_u.3.right.if.ref $and.3.br_if $and.3.br_if.ref $and.3.br_if_not $and.3.br_if_not.ref $acc.3 $acc.3.ref $super.3 $super.3.ref $super.sub.3 $super.sub.3.ref))
  (func (export "check.i64") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $f i32) (local $x i64)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $x (i64.load (i32.mul (local.get $i) (i32.const 8))))
      (if (i64.ne (call_indirect (type $fi64) (local.get $x) (local.get $f))
                  (call_indirect (type $fi64) (local.get $x) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 7))))
    (local.get $n))
  (func (export "check.i32") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $f i32) (local $x i64)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $x (i64.load (i32.mul (local.get $i) (i32.const 8))))
      (if (i32.ne (call_indirect (type $fi32) (local.get $x) (local.get $f))
                  (call_indirect (type $fi32) (local.get $x) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 7))))
    (local.get $n))
)
(assert_return (invoke "check.i64" (i32.const 0)) (i32.const 0)) ;; i64 add.0.right
(assert_return (invoke "check.i64" (i32.const 1)) (i32.const 0)) ;; i64 add.0.left
(assert_return (invoke "check.i64" (i32.const 2)) (i32.const 0)) ;; i64 sub.0.right
(assert_return (invoke "check.i64" (i32.const 3)) (i32.const 0)) ;; i64 sub.0.left
(assert_return (invoke "check.i64" (i32.const 4)) (i32.const 0)) ;; i64 mul.0.right
(assert_return (invoke "check.i64" (i32.const 5)) (i32.const 0)) ;; i64 mul.0.left
(assert_return (invoke "check.i64" (i32.const 6)) (i32.const 0)) ;; i64 and.0.right
(assert_return (invoke "check.i64" (i32.const 7)) (i32.const 0)) ;; i64 and.0.left
(assert_return (invoke "check.i64" (i32.const 8)) (i32.const 0)) ;; i64 or.0.right
(assert_return (invoke "check.i64" (i32.const 9)) (i32.const 0)) ;; i64 or.0.left
(assert_return (invoke "check.i64" (i32.const 10)) (i32.const 0)) ;; i64 xor.0.right
(assert_return (invoke "check.i64" (i32.const 11)) (i32.const 0)) ;; i64 xor.0.left
(assert_return (invoke "check.i64" (i32.const 12)) (i32.const 0)) ;; i64 shl.0.right
(assert_return (invoke "check.i64" (i32.const 13)) (i32.const 0)) ;; i64 shl.0.left
(assert_return (invoke "check.i64" (i32.const 14)) (i32.const 0)) ;; i64 shr_s.0.right
(assert_return (invoke "check.i64" (i32.const 15)) (i32.const 0)) ;; i64 shr_s.0.left
(assert_return (invoke "check.i64" (i32.const 16)) (i32.const 0)) ;; i64 shr_u.0.right
(assert_return (invoke "check.i64" (i32.const 17)) (i32.const 0)) ;; i64 shr_u.0.left
(assert_return (invoke "check.i64" (i32.const 18)) (i32.const 0)) ;; i64 rotl.0.right
(assert_return (invoke "check.i64" (i32.const 19)) (i32.const 0)) ;; i64 rotl.0.left
(assert_return (invoke "check.i64" (i32.const 20)) (i32.const 0)) ;; i64 rotr.0.right
(assert_return (invoke "check.i64" (i32.const 21)) (i32.const 0)) ;; i64 rotr.0.left
(assert_return (invoke "check.i32" (i32.const 22)) (i32.const 0)) ;; i64 eq.0.right
(assert_return (invoke "check.i32" (i32.const 23)) (i32.const 0)) ;; i64 eq.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 24)) (i32.const 0)) ;; i64 eq.0.right.if
(assert_return (invoke "check.i32" (i32.const 25)) (i32.const 0)) ;; i64 eq.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 26)) (i32.const 0)) ;; i64 eq.0.left
(assert_return (invoke "check.i32" (i32.const 27)) (i32.const 0)) ;; i64 eq.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 28)) (i32.const 0)) ;; i64 eq.0.left.if
(assert_return (invoke "check.i32" (i32.const 29)) (i32.const 0)) ;; i64 eq.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 30)) (i32.const 0)) ;; i64 ne.0.right
(assert_return (invoke "check.i32" (i32.const 31)) (i32.const 0)) ;; i64 ne.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 32)) (i32.const 0)) ;; i64 ne.0.right.if
(assert_return (invoke "check.i32" (i32.const 33)) (i32.const 0)) ;; i64 ne.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 34)) (i32.const 0)) ;; i64 ne.0.left
(assert_return (invoke "check.i32" (i32.const 35)) (i32.const 0)) ;; i64 ne.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 36)) (i32.const 0)) ;; i64 ne.0.left.if
(assert_return (invoke "check.i32" (i32.const 37)) (i32.const 0)) ;; i64 ne.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 38)) (i32.const 0)) ;; i64 lt_s.0.right
(assert_return (invoke "check.i32" (i32.const 39)) (i32.const 0)) ;; i64 lt_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 40)) (i32.const 0)) ;; i64 lt_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 41)) (i32.const 0)) ;; i64 lt_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 42)) (i32.const 0)) ;; i64 lt_s.0.left
(assert_return (invoke "check.i32" (i32.const 43)) (i32.const 0)) ;; i64 lt_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 44)) (i32.const 0)) ;; i64 lt_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 45)) (i32.const 0)) ;; i64 lt_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 46)) (i32.const 0)) ;; i64 lt_u.0.right
(assert_return (invoke "check.i32" (i32.const 47)) (i32.const 0)) ;; i64 lt_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 48)) (i32.const 0)) ;; i64 lt_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 49)) (i32.const 0)) ;; i64 lt_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 50)) (i32.const 0)) ;; i64 lt_u.0.left
(assert_return (invoke "check.i32" (i32.const 51)) (i32.const 0)) ;; i64 lt_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 52)) (i32.const 0)) ;; i64 lt_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 53)) (i32.const 0)) ;; i64 lt_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 54)) (i32.const 0)) ;; i64 gt_s.0.right
(assert_return (invoke "check.i32" (i32.const 55)) (i32.const 0)) ;; i64 gt_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 56)) (i32.const 0)) ;; i64 gt_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 57)) (i32.const 0)) ;; i64 gt_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 58)) (i32.const 0)) ;; i64 gt_s.0.left
(assert_return (invoke "check.i32" (i32.const 59)) (i32.const 0)) ;; i64 gt_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 60)) (i32.const 0)) ;; i64 gt_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 61)) (i32.const 0)) ;; i64 gt_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 62)) (i32.const 0)) ;; i64 gt_u.0.right
(assert_return (invoke "check.i32" (i32.const 63)) (i32.const 0)) ;; i64 gt_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 64)) (i32.const 0)) ;; i64 gt_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 65)) (i32.const 0)) ;; i64 gt_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 66)) (i32.const 0)) ;; i64 gt_u.0.left
(assert_return (invoke "check.i32" (i32.const 67)) (i32.const 0)) ;; i64 gt_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 68)) (i32.const 0)) ;; i64 gt_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 69)) (i32.const 0)) ;; i64 gt_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 70)) (i32.const 0)) ;; i64 le_s.0.right
(assert_return (invoke "check.i32" (i32.const 71)) (i32.const 0)) ;; i64 le_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 72)) (i32.const 0)) ;; i64 le_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 73)) (i32.const 0)) ;; i64 le_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 74)) (i32.const 0)) ;; i64 le_s.0.left
(assert_return (invoke "check.i32" (i32.const 75)) (i32.const 0)) ;; i64 le_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 76)) (i32.const 0)) ;; i64 le_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 77)) (i32.const 0)) ;; i64 le_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 78)) (i32.const 0)) ;; i64 le_u.0.right
(assert_return (invoke "check.i32" (i32.const 79)) (i32.const 0)) ;; i64 le_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 80)) (i32.const 0)) ;; i64 le_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 81)) (i32.const 0)) ;; i64 le_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 82)) (i32.const 0)) ;; i64 le_u.0.left
(assert_return (invoke "check.i32" (i32.const 83)) (i32.const 0)) ;; i64 le_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 84)) (i32.const 0)) ;; i64 le_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 85)) (i32.const 0)) ;; i64 le_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 86)) (i32.const 0)) ;; i64 ge_s.0.right
(assert_return (invoke "check.i32" (i32.const 87)) (i32.const 0)) ;; i64 ge_s.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 88)) (i32.const 0)) ;; i64 ge_s.0.right.if
(assert_return (invoke "check.i32" (i32.const 89)) (i32.const 0)) ;; i64 ge_s.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 90)) (i32.const 0)) ;; i64 ge_s.0.left
(assert_return (invoke "check.i32" (i32.const 91)) (i32.const 0)) ;; i64 ge_s.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 92)) (i32.const 0)) ;; i64 ge_s.0.left.if
(assert_return (invoke "check.i32" (i32.const 93)) (i32.const 0)) ;; i64 ge_s.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 94)) (i32.const 0)) ;; i64 ge_u.0.right
(assert_return (invoke "check.i32" (i32.const 95)) (i32.const 0)) ;; i64 ge_u.0.right.br_if
(assert_return (invoke "check.i32" (i32.const 96)) (i32.const 0)) ;; i64 ge_u.0.right.if
(assert_return (invoke "check.i32" (i32.const 97)) (i32.const 0)) ;; i64 ge_u.0.right.eqz
(assert_return (invoke "check.i32" (i32.const 98)) (i32.const 0)) ;; i64 ge_u.0.left
(assert_return (invoke "check.i32" (i32.const 99)) (i32.const 0)) ;; i64 ge_u.0.left.br_if
(assert_return (invoke "check.i32" (i32.const 100)) (i32.const 0)) ;; i64 ge_u.0.left.if
(assert_return (invoke "check.i32" (i32.const 101)) (i32.const 0)) ;; i64 ge_u.0.left.eqz
(assert_return (invoke "check.i32" (i32.const 102)) (i32.const 0)) ;; i64 and.0.br_if
(assert_return (invoke "check.i32" (i32.const 103)) (i32.const 0)) ;; i64 and.0.br_if_not
(assert_return (invoke "check.i64" (i32.const 104)) (i32.const 0)) ;; i64 acc.0
(assert_return (invoke "check.i64" (i32.const 105)) (i32.const 0)) ;; i64 super.0
(assert_return (invoke "check.i64" (i32.const 106)) (i32.const 0)) ;; i64 super.sub.0
(assert_return (invoke "check.i64" (i32.const 107)) (i32.const 0)) ;; i64 add.1.right
(assert_return (invoke "check.i64" (i32.const 108)) (i32.const 0)) ;; i64 add.1.left
(assert_return (invoke "check.i64" (i32.const 109)) (i32.const 0)) ;; i64 sub.1.right
(assert_return (invoke "check.i64" (i32.const 110)) (i32.const 0)) ;; i64 sub.1.left
(assert_return (invoke "check.i64" (i32.const 111)) (i32.const 0)) ;; i64 mul.1.right
(assert_return (invoke "check.i64" (i32.const 112)) (i32.const 0)) ;; i64 mul.1.left
(assert_return (invoke "check.i64" (i32.const 113)) (i32.const 0)) ;; i64 and.1.right
(assert_return (invoke "check.i64" (i32.const 114)) (i32.const 0)) ;; i64 and.1.left
(assert_return (invoke "check.i64" (i32.const 115)) (i32.const 0)) ;; i64 or.1.right
(assert_return (invoke "check.i64" (i32.const 116)) (i32.const 0)) ;; i64 or.1.left
(assert_return (invoke "check.i64" (i32.const 117)) (i32.const 0)) ;; i64 xor.1.right
(assert_return (invoke "check.i64" (i32.const 118)) (i32.const 0)) ;; i64 xor.1.left
(assert_return (invoke "check.i64" (i32.const 119)) (i32.const 0)) ;; i64 shl.1.right
(assert_return (invoke "check.i64" (i32.const 120)) (i32.const 0)) ;; i64 shl.1.left
(assert_return (invoke "check.i64" (i32.const 121)) (i32.const 0)) ;; i64 shr_s.1.right
(assert_return (invoke "check.i64" (i32.const 122)) (i32.const 0)) ;; i64 shr_s.1.left
(assert_return (invoke "check.i64" (i32.const 123)) (i32.const 0)) ;; i64 shr_u.1.right
(assert_return (invoke "check.i64" (i32.const 124)) (i32.const 0)) ;; i64 shr_u.1.left
(assert_return (invoke "check.i64" (i32.const 125)) (i32.const 0)) ;; i64 rotl.1.right
(assert_return (invoke "check.i64" (i32.const 126)) (i32.const 0)) ;; i64 rotl.1.left
(assert_return (invoke "check.i64" (i32.const 127)) (i32.const 0)) ;; i64 rotr.1.right
(assert_return (invoke "check.i64" (i32.const 128)) (i32.const 0)) ;; i64 rotr.1.left
(assert_return (invoke "check.i32" (i32.const 129)) (i32.const 0)) ;; i64 eq.1.right
(assert_return (invoke "check.i32" (i32.const 130)) (i32.const 0)) ;; i64 eq.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 131)) (i32.const 0)) ;; i64 eq.1.right.if
(assert_return (invoke "check.i32" (i32.const 132)) (i32.const 0)) ;; i64 ne.1.right
(assert_return (invoke "check.i32" (i32.const 133)) (i32.const 0)) ;; i64 ne.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 134)) (i32.const 0)) ;; i64 ne.1.right.if
(assert_return (invoke "check.i32" (i32.const 135)) (i32.const 0)) ;; i64 lt_s.1.right
(assert_return (invoke "check.i32" (i32.const 136)) (i32.const 0)) ;; i64 lt_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 137)) (i32.const 0)) ;; i64 lt_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 138)) (i32.const 0)) ;; i64 lt_u.1.right
(assert_return (invoke "check.i32" (i32.const 139)) (i32.const 0)) ;; i64 lt_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 140)) (i32.const 0)) ;; i64 lt_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 141)) (i32.const 0)) ;; i64 gt_s.1.right
(assert_return (invoke "check.i32" (i32.const 142)) (i32.const 0)) ;; i64 gt_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 143)) (i32.const 0)) ;; i64 gt_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 144)) (i32.const 0)) ;; i64 gt_u.1.right
(assert_return (invoke "check.i32" (i32.const 145)) (i32.const 0)) ;; i64 gt_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 146)) (i32.const 0)) ;; i64 gt_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 147)) (i32.const 0)) ;; i64 le_s.1.right
(assert_return (invoke "check.i32" (i32.const 148)) (i32.const 0)) ;; i64 le_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 149)) (i32.const 0)) ;; i64 le_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 150)) (i32.const 0)) ;; i64 le_u.1.right
(assert_return (invoke "check.i32" (i32.const 151)) (i32.const 0)) ;; i64 le_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 152)) (i32.const 0)) ;; i64 le_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 153)) (i32.const 0)) ;; i64 ge_s.1.right
(assert_return (invoke "check.i32" (i32.const 154)) (i32.const 0)) ;; i64 ge_s.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 155)) (i32.const 0)) ;; i64 ge_s.1.right.if
(assert_return (invoke "check.i32" (i32.const 156)) (i32.const 0)) ;; i64 ge_u.1.right
(assert_return (invoke "check.i32" (i32.const 157)) (i32.const 0)) ;; i64 ge_u.1.right.br_if
(assert_return (invoke "check.i32" (i32.const 158)) (i32.const 0)) ;; i64 ge_u.1.right.if
(assert_return (invoke "check.i32" (i32.const 159)) (i32.const 0)) ;; i64 and.1.br_if
(assert_return (invoke "check.i32" (i32.const 160)) (i32.const 0)) ;; i64 and.1.br_if_not
(assert_return (invoke "check.i64" (i32.const 161)) (i32.const 0)) ;; i64 acc.1
(assert_return (invoke "check.i64" (i32.const 162)) (i32.const 0)) ;; i64 super.1
(assert_return (invoke "check.i64" (i32.const 163)) (i32.const 0)) ;; i64 super.sub.1
(assert_return (invoke "check.i64" (i32.const 164)) (i32.const 0)) ;; i64 add.2.right
(assert_return (invoke "check.i64" (i32.const 165)) (i32.const 0)) ;; i64 add.2.left
(assert_return (invoke "check.i64" (i32.const 166)) (i32.const 0)) ;; i64 sub.2.right
(assert_return (invoke "check.i64" (i32.const 167)) (i32.const 0)) ;; i64 sub.2.left
(assert_return (invoke "check.i64" (i32.const 168)) (i32.const 0)) ;; i64 mul.2.right
(assert_return (invoke "check.i64" (i32.const 169)) (i32.const 0)) ;; i64 mul.2.left
(assert_return (invoke "check.i64" (i32.const 170)) (i32.const 0)) ;; i64 and.2.right
(assert_return (invoke "check.i64" (i32.const 171)) (i32.const 0)) ;; i64 and.2.left
(assert_return (invoke "check.i64" (i32.const 172)) (i32.const 0)) ;; i64 or.2.right
(assert_return (invoke "check.i64" (i32.const 173)) (i32.const 0)) ;; i64 or.2.left
(assert_return (invoke "check.i64" (i32.const 174)) (i32.const 0)) ;; i64 xor.2.right
(assert_return (invoke "check.i64" (i32.const 175)) (i32.const 0)) ;; i64 xor.2.left
(assert_return (invoke "check.i64" (i32.const 176)) (i32.const 0)) ;; i64 shl.2.right
(assert_return (invoke "check.i64" (i32.const 177)) (i32.const 0)) ;; i64 shl.2.left
(assert_return (invoke "check.i64" (i32.const 178)) (i32.const 0)) ;; i64 shr_s.2.right
(assert_return (invoke "check.i64" (i32.const 179)) (i32.const 0)) ;; i64 shr_s.2.left
(assert_return (invoke "check.i64" (i32.const 180)) (i32.const 0)) ;; i64 shr_u.2.right
(assert_return (invoke "check.i64" (i32.const 181)) (i32.const 0)) ;; i64 shr_u.2.left
(assert_return (invoke "check.i64" (i32.const 182)) (i32.const 0)) ;; i64 rotl.2.right
(assert_return (invoke "check.i64" (i32.const 183)) (i32.const 0)) ;; i64 rotl.2.left
(assert_return (invoke "check.i64" (i32.const 184)) (i32.const 0)) ;; i64 rotr.2.right
(assert_return (invoke "check.i64" (i32.const 185)) (i32.const 0)) ;; i64 rotr.2.left
(assert_return (invoke "check.i32" (i32.const 186)) (i32.const 0)) ;; i64 eq.2.right
(assert_return (invoke "check.i32" (i32.const 187)) (i32.const 0)) ;; i64 eq.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 188)) (i32.const 0)) ;; i64 eq.2.right.if
(assert_return (invoke "check.i32" (i32.const 189)) (i32.const 0)) ;; i64 ne.2.right
(assert_return (invoke "check.i32" (i32.const 190)) (i32.const 0)) ;; i64 ne.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 191)) (i32.const 0)) ;; i64 ne.2.right.if
(assert_return (invoke "check.i32" (i32.const 192)) (i32.const 0)) ;; i64 lt_s.2.right
(assert_return (invoke "check.i32" (i32.const 193)) (i32.const 0)) ;; i64 lt_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 194)) (i32.const 0)) ;; i64 lt_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 195)) (i32.const 0)) ;; i64 lt_u.2.right
(assert_return (invoke "check.i32" (i32.const 196)) (i32.const 0)) ;; i64 lt_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 197)) (i32.const 0)) ;; i64 lt_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 198)) (i32.const 0)) ;; i64 gt_s.2.right
(assert_return (invoke "check.i32" (i32.const 199)) (i32.const 0)) ;; i64 gt_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 200)) (i32.const 0)) ;; i64 gt_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 201)) (i32.const 0)) ;; i64 gt_u.2.right
(assert_return (invoke "check.i32" (i32.const 202)) (i32.const 0)) ;; i64 gt_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 203)) (i32.const 0)) ;; i64 gt_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 204)) (i32.const 0)) ;; i64 le_s.2.right
(assert_return (invoke "check.i32" (i32.const 205)) (i32.const 0)) ;; i64 le_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 206)) (i32.const 0)) ;; i64 le_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 207)) (i32.const 0)) ;; i64 le_u.2.right
(assert_return (invoke "check.i32" (i32.const 208)) (i32.const 0)) ;; i64 le_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 209)) (i32.const 0)) ;; i64 le_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 210)) (i32.const 0)) ;; i64 ge_s.2.right
(assert_return (invoke "check.i32" (i32.const 211)) (i32.const 0)) ;; i64 ge_s.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 212)) (i32.const 0)) ;; i64 ge_s.2.right.if
(assert_return (invoke "check.i32" (i32.const 213)) (i32.const 0)) ;; i64 ge_u.2.right
(assert_return (invoke "check.i32" (i32.const 214)) (i32.const 0)) ;; i64 ge_u.2.right.br_if
(assert_return (invoke "check.i32" (i32.const 215)) (i32.const 0)) ;; i64 ge_u.2.right.if
(assert_return (invoke "check.i32" (i32.const 216)) (i32.const 0)) ;; i64 and.2.br_if
(assert_return (invoke "check.i32" (i32.const 217)) (i32.const 0)) ;; i64 and.2.br_if_not
(assert_return (invoke "check.i64" (i32.const 218)) (i32.const 0)) ;; i64 acc.2
(assert_return (invoke "check.i64" (i32.const 219)) (i32.const 0)) ;; i64 super.2
(assert_return (invoke "check.i64" (i32.const 220)) (i32.const 0)) ;; i64 super.sub.2
(assert_return (invoke "check.i64" (i32.const 221)) (i32.const 0)) ;; i64 add.3.right
(assert_return (invoke "check.i64" (i32.const 222)) (i32.const 0)) ;; i64 add.3.left
(assert_return (invoke "check.i64" (i32.const 223)) (i32.const 0)) ;; i64 sub.3.right
(assert_return (invoke "check.i64" (i32.const 224)) (i32.const 0)) ;; i64 sub.3.left
(assert_return (invoke "check.i64" (i32.const 225)) (i32.const 0)) ;; i64 mul.3.right
(assert_return (invoke "check.i64" (i32.const 226)) (i32.const 0)) ;; i64 mul.3.left
(assert_return (invoke "check.i64" (i32.const 227)) (i32.const 0)) ;; i64 and.3.right
(assert_return (invoke "check.i64" (i32.const 228)) (i32.const 0)) ;; i64 and.3.left
(assert_return (invoke "check.i64" (i32.const 229)) (i32.const 0)) ;; i64 or.3.right
(assert_return (invoke "check.i64" (i32.const 230)) (i32.const 0)) ;; i64 or.3.left
(assert_return (invoke "check.i64" (i32.const 231)) (i32.const 0)) ;; i64 xor.3.right
(assert_return (invoke "check.i64" (i32.const 232)) (i32.const 0)) ;; i64 xor.3.left
(assert_return (invoke "check.i64" (i32.const 233)) (i32.const 0)) ;; i64 shl.3.right
(assert_return (invoke "check.i64" (i32.const 234)) (i32.const 0)) ;; i64 shl.3.left
(assert_return (invoke "check.i64" (i32.const 235)) (i32.const 0)) ;; i64 shr_s.3.right
(assert_return (invoke "check.i64" (i32.const 236)) (i32.const 0)) ;; i64 shr_s.3.left
(assert_return (invoke "check.i64" (i32.const 237)) (i32.const 0)) ;; i64 shr_u.3.right
(assert_return (invoke "check.i64" (i32.const 238)) (i32.const 0)) ;; i64 shr_u.3.left
(assert_return (invoke "check.i64" (i32.const 239)) (i32.const 0)) ;; i64 rotl.3.right
(assert_return (invoke "check.i64" (i32.const 240)) (i32.const 0)) ;; i64 rotl.3.left
(assert_return (invoke "check.i64" (i32.const 241)) (i32.const 0)) ;; i64 rotr.3.right
(assert_return (invoke "check.i64" (i32.const 242)) (i32.const 0)) ;; i64 rotr.3.left
(assert_return (invoke "check.i32" (i32.const 243)) (i32.const 0)) ;; i64 eq.3.right
(assert_return (invoke "check.i32" (i32.const 244)) (i32.const 0)) ;; i64 eq.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 245)) (i32.const 0)) ;; i64 eq.3.right.if
(assert_return (invoke "check.i32" (i32.const 246)) (i32.const 0)) ;; i64 ne.3.right
(assert_return (invoke "check.i32" (i32.const 247)) (i32.const 0)) ;; i64 ne.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 248)) (i32.const 0)) ;; i64 ne.3.right.if
(assert_return (invoke "check.i32" (i32.const 249)) (i32.const 0)) ;; i64 lt_s.3.right
(assert_return (invoke "check.i32" (i32.const 250)) (i32.const 0)) ;; i64 lt_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 251)) (i32.const 0)) ;; i64 lt_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 252)) (i32.const 0)) ;; i64 lt_u.3.right
(assert_return (invoke "check.i32" (i32.const 253)) (i32.const 0)) ;; i64 lt_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 254)) (i32.const 0)) ;; i64 lt_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 255)) (i32.const 0)) ;; i64 gt_s.3.right
(assert_return (invoke "check.i32" (i32.const 256)) (i32.const 0)) ;; i64 gt_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 257)) (i32.const 0)) ;; i64 gt_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 258)) (i32.const 0)) ;; i64 gt_u.3.right
(assert_return (invoke "check.i32" (i32.const 259)) (i32.const 0)) ;; i64 gt_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 260)) (i32.const 0)) ;; i64 gt_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 261)) (i32.const 0)) ;; i64 le_s.3.right
(assert_return (invoke "check.i32" (i32.const 262)) (i32.const 0)) ;; i64 le_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 263)) (i32.const 0)) ;; i64 le_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 264)) (i32.const 0)) ;; i64 le_u.3.right
(assert_return (invoke "check.i32" (i32.const 265)) (i32.const 0)) ;; i64 le_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 266)) (i32.const 0)) ;; i64 le_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 267)) (i32.const 0)) ;; i64 ge_s.3.right
(assert_return (invoke "check.i32" (i32.const 268)) (i32.const 0)) ;; i64 ge_s.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 269)) (i32.const 0)) ;; i64 ge_s.3.right.if
(assert_return (invoke "check.i32" (i32.const 270)) (i32.const 0)) ;; i64 ge_u.3.right
(assert_return (invoke "check.i32" (i32.const 271)) (i32.const 0)) ;; i64 ge_u.3.right.br_if
(assert_return (invoke "check.i32" (i32.const 272)) (i32.const 0)) ;; i64 ge_u.3.right.if
(assert_return (invoke "check.i32" (i32.const 273)) (i32.const 0)) ;; i64 and.3.br_if
(assert_return (invoke "check.i32" (i32.const 274)) (i32.const 0)) ;; i64 and.3.br_if_not
(assert_return (invoke "check.i64" (i32.const 275)) (i32.const 0)) ;; i64 acc.3
(assert_return (invoke "check.i64" (i32.const 276)) (i32.const 0)) ;; i64 super.3
(assert_return (invoke "check.i64" (i32.const 277)) (i32.const 0)) ;; i64 super.sub.3

;; More distinct constants than the constant pool holds, read as registers,
;; and constants that stay on the stack across a branch.
(module
  (func (export "many") (param $x i32) (result i32)
    (i32.div_u (i32.const 1000) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1001) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1002) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1003) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1004) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1005) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1006) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1007) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1008) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1009) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1010) (i32.add (local.get $x) (i32.const 1)))(i32.div_u (i32.const 1011) (i32.add (local.get $x) (i32.const 1)))
    (i32.add) (i32.add) (i32.add) (i32.add) (i32.add) (i32.add) (i32.add) (i32.add) (i32.add) (i32.add) (i32.add) )
  (func (export "branch") (param $x i32) (result i32)
    (block (result i32) (i32.const 5) (i32.const 6) (local.get $x) (br_if 0) (drop)))
  (func (export "set") (result i32) (local $y i32) (local.set $y (i32.const 42)) (local.get $y))
)
(assert_return (invoke "many" (i32.const 0)) (i32.const 12066))
(assert_return (invoke "branch" (i32.const 1)) (i32.const 6))
(assert_return (invoke "branch" (i32.const 0)) (i32.const 5))
(assert_return (invoke "set") (i32.const 42))

