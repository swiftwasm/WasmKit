;; GENERATED FILE, DO NOT EDIT. Regenerate with:
;;   python3 Tests/WasmKitTests/ExtraSuite/int_fusion.gen.py > Tests/WasmKitTests/ExtraSuite/int_fusion.wast

;; Two-operation integer superinstructions: (x op1 y) op2 z with the
;; intermediate as the left and as the right operand, against a reference
;; that stores the intermediate in a local. Operands include shift amounts
;; at and past the width. Each driver returns the number of mismatching
;; triples for the k-th form.
(module
  (memory 1)
  (data (i32.const 0) "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\1f\00\00\00\00\00\00\00\00\00\00\00!\00\00\00\00\00\00\00\00\00\00\00xV4\12\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\ff\ff\ff\ff\00\00\00\00\01\00\00\00\ff\ff\ff\7f\00\00\00\00\01\00\00\00\00\00\00\80\00\00\00\00\01\00\00\00\1f\00\00\00\00\00\00\00\01\00\00\00!\00\00\00\00\00\00\00\01\00\00\00xV4\12\00\00\00\00\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\ff\00\00\00\80\00\00\00\00\ff\ff\ff\ff\1f\00\00\00\00\00\00\00\ff\ff\ff\ff!\00\00\00\00\00\00\00\ff\ff\ff\ffxV4\12\00\00\00\00\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\7f\00\00\00\80\00\00\00\00\ff\ff\ff\7f\1f\00\00\00\00\00\00\00\ff\ff\ff\7f!\00\00\00\00\00\00\00\ff\ff\ff\7fxV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\80\00\00\00\00\00\00\00\80\1f\00\00\00\00\00\00\00\00\00\00\80!\00\00\00\00\00\00\00\00\00\00\80xV4\12\00\00\00\00\1f\00\00\00\00\00\00\00\00\00\00\00\1f\00\00\00\01\00\00\00\00\00\00\00\1f\00\00\00\ff\ff\ff\ff\00\00\00\00\1f\00\00\00\ff\ff\ff\7f\00\00\00\00\1f\00\00\00\00\00\00\80\00\00\00\00\1f\00\00\00\1f\00\00\00\00\00\00\00\1f\00\00\00!\00\00\00\00\00\00\00\1f\00\00\00xV4\12\00\00\00\00!\00\00\00\00\00\00\00\00\00\00\00!\00\00\00\01\00\00\00\00\00\00\00!\00\00\00\ff\ff\ff\ff\00\00\00\00!\00\00\00\ff\ff\ff\7f\00\00\00\00!\00\00\00\00\00\00\80\00\00\00\00!\00\00\00\1f\00\00\00\00\00\00\00!\00\00\00!\00\00\00\00\00\00\00!\00\00\00xV4\12\00\00\00\00xV4\12\00\00\00\00\00\00\00\00xV4\12\01\00\00\00\00\00\00\00xV4\12\ff\ff\ff\ff\00\00\00\00xV4\12\ff\ff\ff\7f\00\00\00\00xV4\12\00\00\00\80\00\00\00\00xV4\12\1f\00\00\00\00\00\00\00xV4\12!\00\00\00\00\00\00\00xV4\12xV4\12\01\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\1f\00\00\00\01\00\00\00\00\00\00\00!\00\00\00\01\00\00\00\00\00\00\00xV4\12\01\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\01\00\00\00\01\00\00\00\01\00\00\00\ff\ff\ff\ff\01\00\00\00\01\00\00\00\ff\ff\ff\7f\01\00\00\00\01\00\00\00\00\00\00\80\01\00\00\00\01\00\00\00\1f\00\00\00\01\00\00\00\01\00\00\00!\00\00\00\01\00\00\00\01\00\00\00xV4\12\01\00\00\00\ff\ff\ff\ff\00\00\00\00\01\00\00\00\ff\ff\ff\ff\01\00\00\00\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\ff\00\00\00\80\01\00\00\00\ff\ff\ff\ff\1f\00\00\00\01\00\00\00\ff\ff\ff\ff!\00\00\00\01\00\00\00\ff\ff\ff\ffxV4\12\01\00\00\00\ff\ff\ff\7f\00\00\00\00\01\00\00\00\ff\ff\ff\7f\01\00\00\00\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\7f\00\00\00\80\01\00\00\00\ff\ff\ff\7f\1f\00\00\00\01\00\00\00\ff\ff\ff\7f!\00\00\00\01\00\00\00\ff\ff\ff\7fxV4\12\01\00\00\00\00\00\00\80\00\00\00\00\01\00\00\00\00\00\00\80\01\00\00\00\01\00\00\00\00\00\00\80\ff\ff\ff\ff\01\00\00\00\00\00\00\80\ff\ff\ff\7f\01\00\00\00\00\00\00\80\00\00\00\80\01\00\00\00\00\00\00\80\1f\00\00\00\01\00\00\00\00\00\00\80!\00\00\00\01\00\00\00\00\00\00\80xV4\12\01\00\00\00\1f\00\00\00\00\00\00\00\01\00\00\00\1f\00\00\00\01\00\00\00\01\00\00\00\1f\00\00\00\ff\ff\ff\ff\01\00\00\00\1f\00\00\00\ff\ff\ff\7f\01\00\00\00\1f\00\00\00\00\00\00\80\01\00\00\00\1f\00\00\00\1f\00\00\00\01\00\00\00\1f\00\00\00!\00\00\00\01\00\00\00\1f\00\00\00xV4\12\01\00\00\00!\00\00\00\00\00\00\00\01\00\00\00!\00\00\00\01\00\00\00\01\00\00\00!\00\00\00\ff\ff\ff\ff\01\00\00\00!\00\00\00\ff\ff\ff\7f\01\00\00\00!\00\00\00\00\00\00\80\01\00\00\00!\00\00\00\1f\00\00\00\01\00\00\00!\00\00\00!\00\00\00\01\00\00\00!\00\00\00xV4\12\01\00\00\00xV4\12\00\00\00\00\01\00\00\00xV4\12\01\00\00\00\01\00\00\00xV4\12\ff\ff\ff\ff\01\00\00\00xV4\12\ff\ff\ff\7f\01\00\00\00xV4\12\00\00\00\80\01\00\00\00xV4\12\1f\00\00\00\01\00\00\00xV4\12!\00\00\00\01\00\00\00xV4\12xV4\12\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\00\00\00\00\01\00\00\00\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\00\00\00\00\1f\00\00\00\ff\ff\ff\ff\00\00\00\00!\00\00\00\ff\ff\ff\ff\00\00\00\00xV4\12\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\01\00\00\00\01\00\00\00\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\01\00\00\00\00\00\00\80\ff\ff\ff\ff\01\00\00\00\1f\00\00\00\ff\ff\ff\ff\01\00\00\00!\00\00\00\ff\ff\ff\ff\01\00\00\00xV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff!\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffxV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f!\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fxV4\12\ff\ff\ff\ff\00\00\00\80\00\00\00\00\ff\ff\ff\ff\00\00\00\80\01\00\00\00\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\80\00\00\00\80\ff\ff\ff\ff\00\00\00\80\1f\00\00\00\ff\ff\ff\ff\00\00\00\80!\00\00\00\ff\ff\ff\ff\00\00\00\80xV4\12\ff\ff\ff\ff\1f\00\00\00\00\00\00\00\ff\ff\ff\ff\1f\00\00\00\01\00\00\00\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\1f\00\00\00\00\00\00\80\ff\ff\ff\ff\1f\00\00\00\1f\00\00\00\ff\ff\ff\ff\1f\00\00\00!\00\00\00\ff\ff\ff\ff\1f\00\00\00xV4\12\ff\ff\ff\ff!\00\00\00\00\00\00\00\ff\ff\ff\ff!\00\00\00\01\00\00\00\ff\ff\ff\ff!\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff!\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff!\00\00\00\00\00\00\80\ff\ff\ff\ff!\00\00\00\1f\00\00\00\ff\ff\ff\ff!\00\00\00!\00\00\00\ff\ff\ff\ff!\00\00\00xV4\12\ff\ff\ff\ffxV4\12\00\00\00\00\ff\ff\ff\ffxV4\12\01\00\00\00\ff\ff\ff\ffxV4\12\ff\ff\ff\ff\ff\ff\ff\ffxV4\12\ff\ff\ff\7f\ff\ff\ff\ffxV4\12\00\00\00\80\ff\ff\ff\ffxV4\12\1f\00\00\00\ff\ff\ff\ffxV4\12!\00\00\00\ff\ff\ff\ffxV4\12xV4\12\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\7f\00\00\00\00\01\00\00\00\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\7f\00\00\00\00\1f\00\00\00\ff\ff\ff\7f\00\00\00\00!\00\00\00\ff\ff\ff\7f\00\00\00\00xV4\12\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\7f\01\00\00\00\01\00\00\00\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\01\00\00\00\00\00\00\80\ff\ff\ff\7f\01\00\00\00\1f\00\00\00\ff\ff\ff\7f\01\00\00\00!\00\00\00\ff\ff\ff\7f\01\00\00\00xV4\12\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff!\00\00\00\ff\ff\ff\7f\ff\ff\ff\ffxV4\12\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f!\00\00\00\ff\ff\ff\7f\ff\ff\ff\7fxV4\12\ff\ff\ff\7f\00\00\00\80\00\00\00\00\ff\ff\ff\7f\00\00\00\80\01\00\00\00\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\80\00\00\00\80\ff\ff\ff\7f\00\00\00\80\1f\00\00\00\ff\ff\ff\7f\00\00\00\80!\00\00\00\ff\ff\ff\7f\00\00\00\80xV4\12\ff\ff\ff\7f\1f\00\00\00\00\00\00\00\ff\ff\ff\7f\1f\00\00\00\01\00\00\00\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\1f\00\00\00\00\00\00\80\ff\ff\ff\7f\1f\00\00\00\1f\00\00\00\ff\ff\ff\7f\1f\00\00\00!\00\00\00\ff\ff\ff\7f\1f\00\00\00xV4\12\ff\ff\ff\7f!\00\00\00\00\00\00\00\ff\ff\ff\7f!\00\00\00\01\00\00\00\ff\ff\ff\7f!\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f!\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f!\00\00\00\00\00\00\80\ff\ff\ff\7f!\00\00\00\1f\00\00\00\ff\ff\ff\7f!\00\00\00!\00\00\00\ff\ff\ff\7f!\00\00\00xV4\12\ff\ff\ff\7fxV4\12\00\00\00\00\ff\ff\ff\7fxV4\12\01\00\00\00\ff\ff\ff\7fxV4\12\ff\ff\ff\ff\ff\ff\ff\7fxV4\12\ff\ff\ff\7f\ff\ff\ff\7fxV4\12\00\00\00\80\ff\ff\ff\7fxV4\12\1f\00\00\00\ff\ff\ff\7fxV4\12!\00\00\00\ff\ff\ff\7fxV4\12xV4\12\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\01\00\00\00\00\00\00\80\00\00\00\00\ff\ff\ff\ff\00\00\00\80\00\00\00\00\ff\ff\ff\7f\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\80\00\00\00\00\1f\00\00\00\00\00\00\80\00\00\00\00!\00\00\00\00\00\00\80\00\00\00\00xV4\12\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\01\00\00\00\00\00\00\80\01\00\00\00\ff\ff\ff\ff\00\00\00\80\01\00\00\00\ff\ff\ff\7f\00\00\00\80\01\00\00\00\00\00\00\80\00\00\00\80\01\00\00\00\1f\00\00\00\00\00\00\80\01\00\00\00!\00\00\00\00\00\00\80\01\00\00\00xV4\12\00\00\00\80\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\01\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\ff\00\00\00\80\00\00\00\80\ff\ff\ff\ff\1f\00\00\00\00\00\00\80\ff\ff\ff\ff!\00\00\00\00\00\00\80\ff\ff\ff\ffxV4\12\00\00\00\80\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\7f\01\00\00\00\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\7f\00\00\00\80\00\00\00\80\ff\ff\ff\7f\1f\00\00\00\00\00\00\80\ff\ff\ff\7f!\00\00\00\00\00\00\80\ff\ff\ff\7fxV4\12\00\00\00\80\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\80\01\00\00\00\00\00\00\80\00\00\00\80\ff\ff\ff\ff\00\00\00\80\00\00\00\80\ff\ff\ff\7f\00\00\00\80\00\00\00\80\00\00\00\80\00\00\00\80\00\00\00\80\1f\00\00\00\00\00\00\80\00\00\00\80!\00\00\00\00\00\00\80\00\00\00\80xV4\12\00\00\00\80\1f\00\00\00\00\00\00\00\00\00\00\80\1f\00\00\00\01\00\00\00\00\00\00\80\1f\00\00\00\ff\ff\ff\ff\00\00\00\80\1f\00\00\00\ff\ff\ff\7f\00\00\00\80\1f\00\00\00\00\00\00\80\00\00\00\80\1f\00\00\00\1f\00\00\00\00\00\00\80\1f\00\00\00!\00\00\00\00\00\00\80\1f\00\00\00xV4\12\00\00\00\80!\00\00\00\00\00\00\00\00\00\00\80!\00\00\00\01\00\00\00\00\00\00\80!\00\00\00\ff\ff\ff\ff\00\00\00\80!\00\00\00\ff\ff\ff\7f\00\00\00\80!\00\00\00\00\00\00\80\00\00\00\80!\00\00\00\1f\00\00\00\00\00\00\80!\00\00\00!\00\00\00\00\00\00\80!\00\00\00xV4\12\00\00\00\80xV4\12\00\00\00\00\00\00\00\80xV4\12\01\00\00\00\00\00\00\80xV4\12\ff\ff\ff\ff\00\00\00\80xV4\12\ff\ff\ff\7f\00\00\00\80xV4\12\00\00\00\80\00\00\00\80xV4\12\1f\00\00\00\00\00\00\80xV4\12!\00\00\00\00\00\00\80xV4\12xV4\12\1f\00\00\00\00\00\00\00\00\00\00\00\1f\00\00\00\00\00\00\00\01\00\00\00\1f\00\00\00\00\00\00\00\ff\ff\ff\ff\1f\00\00\00\00\00\00\00\ff\ff\ff\7f\1f\00\00\00\00\00\00\00\00\00\00\80\1f\00\00\00\00\00\00\00\1f\00\00\00\1f\00\00\00\00\00\00\00!\00\00\00\1f\00\00\00\00\00\00\00xV4\12\1f\00\00\00\01\00\00\00\00\00\00\00\1f\00\00\00\01\00\00\00\01\00\00\00\1f\00\00\00\01\00\00\00\ff\ff\ff\ff\1f\00\00\00\01\00\00\00\ff\ff\ff\7f\1f\00\00\00\01\00\00\00\00\00\00\80\1f\00\00\00\01\00\00\00\1f\00\00\00\1f\00\00\00\01\00\00\00!\00\00\00\1f\00\00\00\01\00\00\00xV4\12\1f\00\00\00\ff\ff\ff\ff\00\00\00\00\1f\00\00\00\ff\ff\ff\ff\01\00\00\00\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\ff\00\00\00\80\1f\00\00\00\ff\ff\ff\ff\1f\00\00\00\1f\00\00\00\ff\ff\ff\ff!\00\00\00\1f\00\00\00\ff\ff\ff\ffxV4\12\1f\00\00\00\ff\ff\ff\7f\00\00\00\00\1f\00\00\00\ff\ff\ff\7f\01\00\00\00\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\7f\00\00\00\80\1f\00\00\00\ff\ff\ff\7f\1f\00\00\00\1f\00\00\00\ff\ff\ff\7f!\00\00\00\1f\00\00\00\ff\ff\ff\7fxV4\12\1f\00\00\00\00\00\00\80\00\00\00\00\1f\00\00\00\00\00\00\80\01\00\00\00\1f\00\00\00\00\00\00\80\ff\ff\ff\ff\1f\00\00\00\00\00\00\80\ff\ff\ff\7f\1f\00\00\00\00\00\00\80\00\00\00\80\1f\00\00\00\00\00\00\80\1f\00\00\00\1f\00\00\00\00\00\00\80!\00\00\00\1f\00\00\00\00\00\00\80xV4\12\1f\00\00\00\1f\00\00\00\00\00\00\00\1f\00\00\00\1f\00\00\00\01\00\00\00\1f\00\00\00\1f\00\00\00\ff\ff\ff\ff\1f\00\00\00\1f\00\00\00\ff\ff\ff\7f\1f\00\00\00\1f\00\00\00\00\00\00\80\1f\00\00\00\1f\00\00\00\1f\00\00\00\1f\00\00\00\1f\00\00\00!\00\00\00\1f\00\00\00\1f\00\00\00xV4\12\1f\00\00\00!\00\00\00\00\00\00\00\1f\00\00\00!\00\00\00\01\00\00\00\1f\00\00\00!\00\00\00\ff\ff\ff\ff\1f\00\00\00!\00\00\00\ff\ff\ff\7f\1f\00\00\00!\00\00\00\00\00\00\80\1f\00\00\00!\00\00\00\1f\00\00\00\1f\00\00\00!\00\00\00!\00\00\00\1f\00\00\00!\00\00\00xV4\12\1f\00\00\00xV4\12\00\00\00\00\1f\00\00\00xV4\12\01\00\00\00\1f\00\00\00xV4\12\ff\ff\ff\ff\1f\00\00\00xV4\12\ff\ff\ff\7f\1f\00\00\00xV4\12\00\00\00\80\1f\00\00\00xV4\12\1f\00\00\00\1f\00\00\00xV4\12!\00\00\00\1f\00\00\00xV4\12xV4\12!\00\00\00\00\00\00\00\00\00\00\00!\00\00\00\00\00\00\00\01\00\00\00!\00\00\00\00\00\00\00\ff\ff\ff\ff!\00\00\00\00\00\00\00\ff\ff\ff\7f!\00\00\00\00\00\00\00\00\00\00\80!\00\00\00\00\00\00\00\1f\00\00\00!\00\00\00\00\00\00\00!\00\00\00!\00\00\00\00\00\00\00xV4\12!\00\00\00\01\00\00\00\00\00\00\00!\00\00\00\01\00\00\00\01\00\00\00!\00\00\00\01\00\00\00\ff\ff\ff\ff!\00\00\00\01\00\00\00\ff\ff\ff\7f!\00\00\00\01\00\00\00\00\00\00\80!\00\00\00\01\00\00\00\1f\00\00\00!\00\00\00\01\00\00\00!\00\00\00!\00\00\00\01\00\00\00xV4\12!\00\00\00\ff\ff\ff\ff\00\00\00\00!\00\00\00\ff\ff\ff\ff\01\00\00\00!\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff!\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f!\00\00\00\ff\ff\ff\ff\00\00\00\80!\00\00\00\ff\ff\ff\ff\1f\00\00\00!\00\00\00\ff\ff\ff\ff!\00\00\00!\00\00\00\ff\ff\ff\ffxV4\12!\00\00\00\ff\ff\ff\7f\00\00\00\00!\00\00\00\ff\ff\ff\7f\01\00\00\00!\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff!\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f!\00\00\00\ff\ff\ff\7f\00\00\00\80!\00\00\00\ff\ff\ff\7f\1f\00\00\00!\00\00\00\ff\ff\ff\7f!\00\00\00!\00\00\00\ff\ff\ff\7fxV4\12!\00\00\00\00\00\00\80\00\00\00\00!\00\00\00\00\00\00\80\01\00\00\00!\00\00\00\00\00\00\80\ff\ff\ff\ff!\00\00\00\00\00\00\80\ff\ff\ff\7f!\00\00\00\00\00\00\80\00\00\00\80!\00\00\00\00\00\00\80\1f\00\00\00!\00\00\00\00\00\00\80!\00\00\00!\00\00\00\00\00\00\80xV4\12!\00\00\00\1f\00\00\00\00\00\00\00!\00\00\00\1f\00\00\00\01\00\00\00!\00\00\00\1f\00\00\00\ff\ff\ff\ff!\00\00\00\1f\00\00\00\ff\ff\ff\7f!\00\00\00\1f\00\00\00\00\00\00\80!\00\00\00\1f\00\00\00\1f\00\00\00!\00\00\00\1f\00\00\00!\00\00\00!\00\00\00\1f\00\00\00xV4\12!\00\00\00!\00\00\00\00\00\00\00!\00\00\00!\00\00\00\01\00\00\00!\00\00\00!\00\00\00\ff\ff\ff\ff!\00\00\00!\00\00\00\ff\ff\ff\7f!\00\00\00!\00\00\00\00\00\00\80!\00\00\00!\00\00\00\1f\00\00\00!\00\00\00!\00\00\00!\00\00\00!\00\00\00!\00\00\00xV4\12!\00\00\00xV4\12\00\00\00\00!\00\00\00xV4\12\01\00\00\00!\00\00\00xV4\12\ff\ff\ff\ff!\00\00\00xV4\12\ff\ff\ff\7f!\00\00\00xV4\12\00\00\00\80!\00\00\00xV4\12\1f\00\00\00!\00\00\00xV4\12!\00\00\00!\00\00\00xV4\12xV4\12xV4\12\00\00\00\00\00\00\00\00xV4\12\00\00\00\00\01\00\00\00xV4\12\00\00\00\00\ff\ff\ff\ffxV4\12\00\00\00\00\ff\ff\ff\7fxV4\12\00\00\00\00\00\00\00\80xV4\12\00\00\00\00\1f\00\00\00xV4\12\00\00\00\00!\00\00\00xV4\12\00\00\00\00xV4\12xV4\12\01\00\00\00\00\00\00\00xV4\12\01\00\00\00\01\00\00\00xV4\12\01\00\00\00\ff\ff\ff\ffxV4\12\01\00\00\00\ff\ff\ff\7fxV4\12\01\00\00\00\00\00\00\80xV4\12\01\00\00\00\1f\00\00\00xV4\12\01\00\00\00!\00\00\00xV4\12\01\00\00\00xV4\12xV4\12\ff\ff\ff\ff\00\00\00\00xV4\12\ff\ff\ff\ff\01\00\00\00xV4\12\ff\ff\ff\ff\ff\ff\ff\ffxV4\12\ff\ff\ff\ff\ff\ff\ff\7fxV4\12\ff\ff\ff\ff\00\00\00\80xV4\12\ff\ff\ff\ff\1f\00\00\00xV4\12\ff\ff\ff\ff!\00\00\00xV4\12\ff\ff\ff\ffxV4\12xV4\12\ff\ff\ff\7f\00\00\00\00xV4\12\ff\ff\ff\7f\01\00\00\00xV4\12\ff\ff\ff\7f\ff\ff\ff\ffxV4\12\ff\ff\ff\7f\ff\ff\ff\7fxV4\12\ff\ff\ff\7f\00\00\00\80xV4\12\ff\ff\ff\7f\1f\00\00\00xV4\12\ff\ff\ff\7f!\00\00\00xV4\12\ff\ff\ff\7fxV4\12xV4\12\00\00\00\80\00\00\00\00xV4\12\00\00\00\80\01\00\00\00xV4\12\00\00\00\80\ff\ff\ff\ffxV4\12\00\00\00\80\ff\ff\ff\7fxV4\12\00\00\00\80\00\00\00\80xV4\12\00\00\00\80\1f\00\00\00xV4\12\00\00\00\80!\00\00\00xV4\12\00\00\00\80xV4\12xV4\12\1f\00\00\00\00\00\00\00xV4\12\1f\00\00\00\01\00\00\00xV4\12\1f\00\00\00\ff\ff\ff\ffxV4\12\1f\00\00\00\ff\ff\ff\7fxV4\12\1f\00\00\00\00\00\00\80xV4\12\1f\00\00\00\1f\00\00\00xV4\12\1f\00\00\00!\00\00\00xV4\12\1f\00\00\00xV4\12xV4\12!\00\00\00\00\00\00\00xV4\12!\00\00\00\01\00\00\00xV4\12!\00\00\00\ff\ff\ff\ffxV4\12!\00\00\00\ff\ff\ff\7fxV4\12!\00\00\00\00\00\00\80xV4\12!\00\00\00\1f\00\00\00xV4\12!\00\00\00!\00\00\00xV4\12!\00\00\00xV4\12xV4\12xV4\12\00\00\00\00xV4\12xV4\12\01\00\00\00xV4\12xV4\12\ff\ff\ff\ffxV4\12xV4\12\ff\ff\ff\7fxV4\12xV4\12\00\00\00\80xV4\12xV4\12\1f\00\00\00xV4\12xV4\12!\00\00\00xV4\12xV4\12xV4\12")
  (func $shl.add.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.shl (local.get $a) (local.get $b)) (local.get $c)))
  (func $shl.add.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shl (local.get $a) (local.get $b))) (i32.add (local.get $t) (local.get $c)))
  (func $shl.add.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (local.get $c) (i32.shl (local.get $a) (local.get $b))))
  (func $shl.add.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shl (local.get $a) (local.get $b))) (i32.add (local.get $c) (local.get $t)))
  (func $mul.add.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.mul (local.get $a) (local.get $b)) (local.get $c)))
  (func $mul.add.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.mul (local.get $a) (local.get $b))) (i32.add (local.get $t) (local.get $c)))
  (func $mul.add.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (local.get $c) (i32.mul (local.get $a) (local.get $b))))
  (func $mul.add.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.mul (local.get $a) (local.get $b))) (i32.add (local.get $c) (local.get $t)))
  (func $add.add.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $c)))
  (func $add.add.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.add (local.get $a) (local.get $b))) (i32.add (local.get $t) (local.get $c)))
  (func $add.add.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (local.get $c) (i32.add (local.get $a) (local.get $b))))
  (func $add.add.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.add (local.get $a) (local.get $b))) (i32.add (local.get $c) (local.get $t)))
  (func $and.add.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.and (local.get $a) (local.get $b)) (local.get $c)))
  (func $and.add.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.and (local.get $a) (local.get $b))) (i32.add (local.get $t) (local.get $c)))
  (func $and.add.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (local.get $c) (i32.and (local.get $a) (local.get $b))))
  (func $and.add.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.and (local.get $a) (local.get $b))) (i32.add (local.get $c) (local.get $t)))
  (func $shr_u.and.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (i32.shr_u (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_u.and.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_u (local.get $a) (local.get $b))) (i32.and (local.get $t) (local.get $c)))
  (func $shr_u.and.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (local.get $c) (i32.shr_u (local.get $a) (local.get $b))))
  (func $shr_u.and.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_u (local.get $a) (local.get $b))) (i32.and (local.get $c) (local.get $t)))
  (func $or.and.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (i32.or (local.get $a) (local.get $b)) (local.get $c)))
  (func $or.and.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.or (local.get $a) (local.get $b))) (i32.and (local.get $t) (local.get $c)))
  (func $or.and.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (local.get $c) (i32.or (local.get $a) (local.get $b))))
  (func $or.and.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.or (local.get $a) (local.get $b))) (i32.and (local.get $c) (local.get $t)))
  (func $shr_u.add.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.shr_u (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_u.add.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_u (local.get $a) (local.get $b))) (i32.add (local.get $t) (local.get $c)))
  (func $shr_u.add.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (local.get $c) (i32.shr_u (local.get $a) (local.get $b))))
  (func $shr_u.add.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_u (local.get $a) (local.get $b))) (i32.add (local.get $c) (local.get $t)))
  (func $sub.and.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (i32.sub (local.get $a) (local.get $b)) (local.get $c)))
  (func $sub.and.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.sub (local.get $a) (local.get $b))) (i32.and (local.get $t) (local.get $c)))
  (func $sub.and.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (local.get $c) (i32.sub (local.get $a) (local.get $b))))
  (func $sub.and.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.sub (local.get $a) (local.get $b))) (i32.and (local.get $c) (local.get $t)))
  (func $shl.or.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.or (i32.shl (local.get $a) (local.get $b)) (local.get $c)))
  (func $shl.or.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shl (local.get $a) (local.get $b))) (i32.or (local.get $t) (local.get $c)))
  (func $shl.or.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.or (local.get $c) (i32.shl (local.get $a) (local.get $b))))
  (func $shl.or.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shl (local.get $a) (local.get $b))) (i32.or (local.get $c) (local.get $t)))
  (func $add.and.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (i32.add (local.get $a) (local.get $b)) (local.get $c)))
  (func $add.and.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.add (local.get $a) (local.get $b))) (i32.and (local.get $t) (local.get $c)))
  (func $add.and.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (local.get $c) (i32.add (local.get $a) (local.get $b))))
  (func $add.and.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.add (local.get $a) (local.get $b))) (i32.and (local.get $c) (local.get $t)))
  (func $shr_u.or.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.or (i32.shr_u (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_u.or.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_u (local.get $a) (local.get $b))) (i32.or (local.get $t) (local.get $c)))
  (func $shr_u.or.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.or (local.get $c) (i32.shr_u (local.get $a) (local.get $b))))
  (func $shr_u.or.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_u (local.get $a) (local.get $b))) (i32.or (local.get $c) (local.get $t)))
  (func $xor.shr_u.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_u (i32.xor (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.shr_u.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.xor (local.get $a) (local.get $b))) (i32.shr_u (local.get $t) (local.get $c)))
  (func $xor.shr_u.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_u (local.get $c) (i32.xor (local.get $a) (local.get $b))))
  (func $xor.shr_u.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.xor (local.get $a) (local.get $b))) (i32.shr_u (local.get $c) (local.get $t)))
  (func $add.sub.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.sub (i32.add (local.get $a) (local.get $b)) (local.get $c)))
  (func $add.sub.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.add (local.get $a) (local.get $b))) (i32.sub (local.get $t) (local.get $c)))
  (func $add.sub.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.sub (local.get $c) (i32.add (local.get $a) (local.get $b))))
  (func $add.sub.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.add (local.get $a) (local.get $b))) (i32.sub (local.get $c) (local.get $t)))
  (func $xor.shl.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shl (i32.xor (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.shl.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.xor (local.get $a) (local.get $b))) (i32.shl (local.get $t) (local.get $c)))
  (func $xor.shl.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shl (local.get $c) (i32.xor (local.get $a) (local.get $b))))
  (func $xor.shl.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.xor (local.get $a) (local.get $b))) (i32.shl (local.get $c) (local.get $t)))
  (func $sub.add.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.sub (local.get $a) (local.get $b)) (local.get $c)))
  (func $sub.add.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.sub (local.get $a) (local.get $b))) (i32.add (local.get $t) (local.get $c)))
  (func $sub.add.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (local.get $c) (i32.sub (local.get $a) (local.get $b))))
  (func $sub.add.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.sub (local.get $a) (local.get $b))) (i32.add (local.get $c) (local.get $t)))
  (func $and.shl.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shl (i32.and (local.get $a) (local.get $b)) (local.get $c)))
  (func $and.shl.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.and (local.get $a) (local.get $b))) (i32.shl (local.get $t) (local.get $c)))
  (func $and.shl.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shl (local.get $c) (i32.and (local.get $a) (local.get $b))))
  (func $and.shl.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.and (local.get $a) (local.get $b))) (i32.shl (local.get $c) (local.get $t)))
  (func $mul.sub.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.sub (i32.mul (local.get $a) (local.get $b)) (local.get $c)))
  (func $mul.sub.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.mul (local.get $a) (local.get $b))) (i32.sub (local.get $t) (local.get $c)))
  (func $mul.sub.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.sub (local.get $c) (i32.mul (local.get $a) (local.get $b))))
  (func $mul.sub.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.mul (local.get $a) (local.get $b))) (i32.sub (local.get $c) (local.get $t)))
  (func $shr_s.rotr.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotr (i32.shr_s (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_s.rotr.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_s (local.get $a) (local.get $b))) (i32.rotr (local.get $t) (local.get $c)))
  (func $shr_s.rotr.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotr (local.get $c) (i32.shr_s (local.get $a) (local.get $b))))
  (func $shr_s.rotr.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.shr_s (local.get $a) (local.get $b))) (i32.rotr (local.get $c) (local.get $t)))
  (func $rotl.mul.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.mul (i32.rotl (local.get $a) (local.get $b)) (local.get $c)))
  (func $rotl.mul.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.rotl (local.get $a) (local.get $b))) (i32.mul (local.get $t) (local.get $c)))
  (func $rotl.mul.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.mul (local.get $c) (i32.rotl (local.get $a) (local.get $b))))
  (func $rotl.mul.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.rotl (local.get $a) (local.get $b))) (i32.mul (local.get $c) (local.get $t)))
  (type $bin (func (param $a i32) (param $b i32) (param $c i32) (result i32)))
  (table funcref (elem $shl.add.left $shl.add.left.ref $shl.add.right $shl.add.right.ref $mul.add.left $mul.add.left.ref $mul.add.right $mul.add.right.ref $add.add.left $add.add.left.ref $add.add.right $add.add.right.ref $and.add.left $and.add.left.ref $and.add.right $and.add.right.ref $shr_u.and.left $shr_u.and.left.ref $shr_u.and.right $shr_u.and.right.ref $or.and.left $or.and.left.ref $or.and.right $or.and.right.ref $shr_u.add.left $shr_u.add.left.ref $shr_u.add.right $shr_u.add.right.ref $sub.and.left $sub.and.left.ref $sub.and.right $sub.and.right.ref $shl.or.left $shl.or.left.ref $shl.or.right $shl.or.right.ref $add.and.left $add.and.left.ref $add.and.right $add.and.right.ref $shr_u.or.left $shr_u.or.left.ref $shr_u.or.right $shr_u.or.right.ref $xor.shr_u.left $xor.shr_u.left.ref $xor.shr_u.right $xor.shr_u.right.ref $add.sub.left $add.sub.left.ref $add.sub.right $add.sub.right.ref $xor.shl.left $xor.shl.left.ref $xor.shl.right $xor.shl.right.ref $sub.add.left $sub.add.left.ref $sub.add.right $sub.add.right.ref $and.shl.left $and.shl.left.ref $and.shl.right $and.shl.right.ref $mul.sub.left $mul.sub.left.ref $mul.sub.right $mul.sub.right.ref $shr_s.rotr.left $shr_s.rotr.left.ref $shr_s.rotr.right $shr_s.rotr.right.ref $rotl.mul.left $rotl.mul.left.ref $rotl.mul.right $rotl.mul.right.ref))
  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $o (i32.mul (local.get $i) (i32.const 12)))
      (if (i32.ne (call_indirect (type $bin) (i32.load (i32.add (local.get $o) (i32.const 0))) (i32.load (i32.add (local.get $o) (i32.const 4))) (i32.load (i32.add (local.get $o) (i32.const 8))) (local.get $f))
                  (call_indirect (type $bin) (i32.load (i32.add (local.get $o) (i32.const 0))) (i32.load (i32.add (local.get $o) (i32.const 4))) (i32.load (i32.add (local.get $o) (i32.const 8))) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 512))))
    (local.get $n))
;; A local.set right after a pushed local must store that local's value,
;; not the operation emitted before it.
  (func (export "set-local") (param $a i32) (param $b i32) (param $c i32) (result i32) (local $x i32)
    (i32.shl (local.get $a) (local.get $b)) (local.get $c) (local.set $x) (drop) (local.get $x))
;; A label between the two operations blocks the fold.
  (func (export "label") (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (block (result i32) (i32.mul (local.get $a) (local.get $b))) (local.get $c)))
;; A chain of three folds the first pair and keeps the third operation.
  (func (export "chain") (param $a i32) (param $b i32) (param $c i32) (param $d i32) (result i32) (i32.sub (i32.add (i32.mul (local.get $a) (local.get $b)) (local.get $c)) (local.get $d)))
;; A live intermediate is not folded.
  (func (export "live") (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32)
    (local.set $t (i32.mul (local.get $a) (local.get $b))) (i32.add (i32.add (local.get $t) (local.get $c)) (local.get $t)))
;; Constant operands on both operations.
  (func (export "const") (param $a i32) (result i32) (i32.add (i32.shl (local.get $a) (i32.const 3)) (i32.const 5)))
;; A folded and-producer or and-consumer feeding a branch.
  (func (export "and-branch") (param $a i32) (param $b i32) (param $c i32) (result i32)
    (block (br_if 0 (i32.eqz (i32.and (i32.shr_u (local.get $a) (local.get $b)) (local.get $c)))) (return (i32.const 1)))
    (block (br_if 0 (i32.ne (i32.and (i32.xor (local.get $a) (local.get $b)) (local.get $c)) (i32.const 0))) (return (i32.const 2)))
    (i32.const 3))
;; Division has no superinstruction.
  (func (export "div") (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.div_s (local.get $a) (local.get $b)) (local.get $c)))
)
;; i32 shl.add.left
(assert_return (invoke "check" (i32.const 0)) (i32.const 0))
;; i32 shl.add.right
(assert_return (invoke "check" (i32.const 1)) (i32.const 0))
;; i32 mul.add.left
(assert_return (invoke "check" (i32.const 2)) (i32.const 0))
;; i32 mul.add.right
(assert_return (invoke "check" (i32.const 3)) (i32.const 0))
;; i32 add.add.left
(assert_return (invoke "check" (i32.const 4)) (i32.const 0))
;; i32 add.add.right
(assert_return (invoke "check" (i32.const 5)) (i32.const 0))
;; i32 and.add.left
(assert_return (invoke "check" (i32.const 6)) (i32.const 0))
;; i32 and.add.right
(assert_return (invoke "check" (i32.const 7)) (i32.const 0))
;; i32 shr_u.and.left
(assert_return (invoke "check" (i32.const 8)) (i32.const 0))
;; i32 shr_u.and.right
(assert_return (invoke "check" (i32.const 9)) (i32.const 0))
;; i32 or.and.left
(assert_return (invoke "check" (i32.const 10)) (i32.const 0))
;; i32 or.and.right
(assert_return (invoke "check" (i32.const 11)) (i32.const 0))
;; i32 shr_u.add.left
(assert_return (invoke "check" (i32.const 12)) (i32.const 0))
;; i32 shr_u.add.right
(assert_return (invoke "check" (i32.const 13)) (i32.const 0))
;; i32 sub.and.left
(assert_return (invoke "check" (i32.const 14)) (i32.const 0))
;; i32 sub.and.right
(assert_return (invoke "check" (i32.const 15)) (i32.const 0))
;; i32 shl.or.left
(assert_return (invoke "check" (i32.const 16)) (i32.const 0))
;; i32 shl.or.right
(assert_return (invoke "check" (i32.const 17)) (i32.const 0))
;; i32 add.and.left
(assert_return (invoke "check" (i32.const 18)) (i32.const 0))
;; i32 add.and.right
(assert_return (invoke "check" (i32.const 19)) (i32.const 0))
;; i32 shr_u.or.left
(assert_return (invoke "check" (i32.const 20)) (i32.const 0))
;; i32 shr_u.or.right
(assert_return (invoke "check" (i32.const 21)) (i32.const 0))
;; i32 xor.shr_u.left
(assert_return (invoke "check" (i32.const 22)) (i32.const 0))
;; i32 xor.shr_u.right
(assert_return (invoke "check" (i32.const 23)) (i32.const 0))
;; i32 add.sub.left
(assert_return (invoke "check" (i32.const 24)) (i32.const 0))
;; i32 add.sub.right
(assert_return (invoke "check" (i32.const 25)) (i32.const 0))
;; i32 xor.shl.left
(assert_return (invoke "check" (i32.const 26)) (i32.const 0))
;; i32 xor.shl.right
(assert_return (invoke "check" (i32.const 27)) (i32.const 0))
;; i32 sub.add.left
(assert_return (invoke "check" (i32.const 28)) (i32.const 0))
;; i32 sub.add.right
(assert_return (invoke "check" (i32.const 29)) (i32.const 0))
;; i32 and.shl.left
(assert_return (invoke "check" (i32.const 30)) (i32.const 0))
;; i32 and.shl.right
(assert_return (invoke "check" (i32.const 31)) (i32.const 0))
;; i32 mul.sub.left
(assert_return (invoke "check" (i32.const 32)) (i32.const 0))
;; i32 mul.sub.right
(assert_return (invoke "check" (i32.const 33)) (i32.const 0))
;; i32 shr_s.rotr.left
(assert_return (invoke "check" (i32.const 34)) (i32.const 0))
;; i32 shr_s.rotr.right
(assert_return (invoke "check" (i32.const 35)) (i32.const 0))
;; i32 rotl.mul.left
(assert_return (invoke "check" (i32.const 36)) (i32.const 0))
;; i32 rotl.mul.right
(assert_return (invoke "check" (i32.const 37)) (i32.const 0))
(assert_return (invoke "set-local" (i32.const 3) (i32.const 4) (i32.const 5)) (i32.const 5))
(assert_return (invoke "label" (i32.const 3) (i32.const 4) (i32.const 5)) (i32.const 17))
(assert_return (invoke "chain" (i32.const 3) (i32.const 4) (i32.const 5) (i32.const 2)) (i32.const 15))
(assert_return (invoke "live" (i32.const 3) (i32.const 4) (i32.const 5)) (i32.const 29))
(assert_return (invoke "const" (i32.const 2)) (i32.const 21))
(assert_return (invoke "and-branch" (i32.const 12) (i32.const 2) (i32.const 1)) (i32.const 1))
(assert_return (invoke "and-branch" (i32.const 12) (i32.const 2) (i32.const 4)) (i32.const 3))
(assert_return (invoke "and-branch" (i32.const 12) (i32.const 2) (i32.const 16)) (i32.const 2))
(assert_return (invoke "div" (i32.const -7) (i32.const 2) (i32.const 1)) (i32.const -2))

(module
  (memory 1)
  (data (i32.const 0) "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12")
  (func $xor.rotl.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotl (i64.xor (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.rotl.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.rotl (local.get $t) (local.get $c)))
  (func $xor.rotl.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotl (local.get $c) (i64.xor (local.get $a) (local.get $b))))
  (func $xor.rotl.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.rotl (local.get $c) (local.get $t)))
  (func $mul.add.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (i64.mul (local.get $a) (local.get $b)) (local.get $c)))
  (func $mul.add.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.mul (local.get $a) (local.get $b))) (i64.add (local.get $t) (local.get $c)))
  (func $mul.add.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (local.get $c) (i64.mul (local.get $a) (local.get $b))))
  (func $mul.add.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.mul (local.get $a) (local.get $b))) (i64.add (local.get $c) (local.get $t)))
  (func $shl.and.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (i64.shl (local.get $a) (local.get $b)) (local.get $c)))
  (func $shl.and.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shl (local.get $a) (local.get $b))) (i64.and (local.get $t) (local.get $c)))
  (func $shl.and.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (local.get $c) (i64.shl (local.get $a) (local.get $b))))
  (func $shl.and.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shl (local.get $a) (local.get $b))) (i64.and (local.get $c) (local.get $t)))
  (func $and.mul.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.mul (i64.and (local.get $a) (local.get $b)) (local.get $c)))
  (func $and.mul.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.and (local.get $a) (local.get $b))) (i64.mul (local.get $t) (local.get $c)))
  (func $and.mul.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.mul (local.get $c) (i64.and (local.get $a) (local.get $b))))
  (func $and.mul.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.and (local.get $a) (local.get $b))) (i64.mul (local.get $c) (local.get $t)))
  (func $shl.or.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.or (i64.shl (local.get $a) (local.get $b)) (local.get $c)))
  (func $shl.or.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shl (local.get $a) (local.get $b))) (i64.or (local.get $t) (local.get $c)))
  (func $shl.or.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.or (local.get $c) (i64.shl (local.get $a) (local.get $b))))
  (func $shl.or.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shl (local.get $a) (local.get $b))) (i64.or (local.get $c) (local.get $t)))
  (func $xor.and.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (i64.xor (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.and.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.and (local.get $t) (local.get $c)))
  (func $xor.and.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (local.get $c) (i64.xor (local.get $a) (local.get $b))))
  (func $xor.and.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.and (local.get $c) (local.get $t)))
  (func $mul.xor.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (i64.mul (local.get $a) (local.get $b)) (local.get $c)))
  (func $mul.xor.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.mul (local.get $a) (local.get $b))) (i64.xor (local.get $t) (local.get $c)))
  (func $mul.xor.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (local.get $c) (i64.mul (local.get $a) (local.get $b))))
  (func $mul.xor.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.mul (local.get $a) (local.get $b))) (i64.xor (local.get $c) (local.get $t)))
  (func $and.xor.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (i64.and (local.get $a) (local.get $b)) (local.get $c)))
  (func $and.xor.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.and (local.get $a) (local.get $b))) (i64.xor (local.get $t) (local.get $c)))
  (func $and.xor.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (local.get $c) (i64.and (local.get $a) (local.get $b))))
  (func $and.xor.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.and (local.get $a) (local.get $b))) (i64.xor (local.get $c) (local.get $t)))
  (func $rotl.xor.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (i64.rotl (local.get $a) (local.get $b)) (local.get $c)))
  (func $rotl.xor.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.rotl (local.get $a) (local.get $b))) (i64.xor (local.get $t) (local.get $c)))
  (func $rotl.xor.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (local.get $c) (i64.rotl (local.get $a) (local.get $b))))
  (func $rotl.xor.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.rotl (local.get $a) (local.get $b))) (i64.xor (local.get $c) (local.get $t)))
  (func $sub.and.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (i64.sub (local.get $a) (local.get $b)) (local.get $c)))
  (func $sub.and.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.sub (local.get $a) (local.get $b))) (i64.and (local.get $t) (local.get $c)))
  (func $sub.and.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (local.get $c) (i64.sub (local.get $a) (local.get $b))))
  (func $sub.and.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.sub (local.get $a) (local.get $b))) (i64.and (local.get $c) (local.get $t)))
  (func $xor.xor.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (i64.xor (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.xor.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.xor (local.get $t) (local.get $c)))
  (func $xor.xor.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (local.get $c) (i64.xor (local.get $a) (local.get $b))))
  (func $xor.xor.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.xor (local.get $c) (local.get $t)))
  (func $or.or.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.or (i64.or (local.get $a) (local.get $b)) (local.get $c)))
  (func $or.or.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.or (local.get $a) (local.get $b))) (i64.or (local.get $t) (local.get $c)))
  (func $or.or.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.or (local.get $c) (i64.or (local.get $a) (local.get $b))))
  (func $or.or.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.or (local.get $a) (local.get $b))) (i64.or (local.get $c) (local.get $t)))
  (func $shr_u.and.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (i64.shr_u (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_u.and.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shr_u (local.get $a) (local.get $b))) (i64.and (local.get $t) (local.get $c)))
  (func $shr_u.and.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (local.get $c) (i64.shr_u (local.get $a) (local.get $b))))
  (func $shr_u.and.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shr_u (local.get $a) (local.get $b))) (i64.and (local.get $c) (local.get $t)))
  (func $and.and.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (i64.and (local.get $a) (local.get $b)) (local.get $c)))
  (func $and.and.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.and (local.get $a) (local.get $b))) (i64.and (local.get $t) (local.get $c)))
  (func $and.and.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (local.get $c) (i64.and (local.get $a) (local.get $b))))
  (func $and.and.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.and (local.get $a) (local.get $b))) (i64.and (local.get $c) (local.get $t)))
  (func $xor.mul.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.mul (i64.xor (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.mul.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.mul (local.get $t) (local.get $c)))
  (func $xor.mul.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.mul (local.get $c) (i64.xor (local.get $a) (local.get $b))))
  (func $xor.mul.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.mul (local.get $c) (local.get $t)))
  (func $xor.shr_u.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_u (i64.xor (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.shr_u.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.shr_u (local.get $t) (local.get $c)))
  (func $xor.shr_u.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_u (local.get $c) (i64.xor (local.get $a) (local.get $b))))
  (func $xor.shr_u.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.xor (local.get $a) (local.get $b))) (i64.shr_u (local.get $c) (local.get $t)))
  (func $mul.sub.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.sub (i64.mul (local.get $a) (local.get $b)) (local.get $c)))
  (func $mul.sub.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.mul (local.get $a) (local.get $b))) (i64.sub (local.get $t) (local.get $c)))
  (func $mul.sub.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.sub (local.get $c) (i64.mul (local.get $a) (local.get $b))))
  (func $mul.sub.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.mul (local.get $a) (local.get $b))) (i64.sub (local.get $c) (local.get $t)))
  (func $shr_s.rotr.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotr (i64.shr_s (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_s.rotr.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shr_s (local.get $a) (local.get $b))) (i64.rotr (local.get $t) (local.get $c)))
  (func $shr_s.rotr.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotr (local.get $c) (i64.shr_s (local.get $a) (local.get $b))))
  (func $shr_s.rotr.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.shr_s (local.get $a) (local.get $b))) (i64.rotr (local.get $c) (local.get $t)))
  (func $rotr.sub.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $rotr.sub.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.sub (local.get $t) (local.get $c)))
  (func $rotr.sub.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.sub (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $rotr.sub.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.sub (local.get $c) (local.get $t)))
  (type $bin (func (param $a i64) (param $b i64) (param $c i64) (result i64)))
  (table funcref (elem $xor.rotl.left $xor.rotl.left.ref $xor.rotl.right $xor.rotl.right.ref $mul.add.left $mul.add.left.ref $mul.add.right $mul.add.right.ref $shl.and.left $shl.and.left.ref $shl.and.right $shl.and.right.ref $and.mul.left $and.mul.left.ref $and.mul.right $and.mul.right.ref $shl.or.left $shl.or.left.ref $shl.or.right $shl.or.right.ref $xor.and.left $xor.and.left.ref $xor.and.right $xor.and.right.ref $mul.xor.left $mul.xor.left.ref $mul.xor.right $mul.xor.right.ref $and.xor.left $and.xor.left.ref $and.xor.right $and.xor.right.ref $rotl.xor.left $rotl.xor.left.ref $rotl.xor.right $rotl.xor.right.ref $sub.and.left $sub.and.left.ref $sub.and.right $sub.and.right.ref $xor.xor.left $xor.xor.left.ref $xor.xor.right $xor.xor.right.ref $or.or.left $or.or.left.ref $or.or.right $or.or.right.ref $shr_u.and.left $shr_u.and.left.ref $shr_u.and.right $shr_u.and.right.ref $and.and.left $and.and.left.ref $and.and.right $and.and.right.ref $xor.mul.left $xor.mul.left.ref $xor.mul.right $xor.mul.right.ref $xor.shr_u.left $xor.shr_u.left.ref $xor.shr_u.right $xor.shr_u.right.ref $mul.sub.left $mul.sub.left.ref $mul.sub.right $mul.sub.right.ref $shr_s.rotr.left $shr_s.rotr.left.ref $shr_s.rotr.right $shr_s.rotr.right.ref $rotr.sub.left $rotr.sub.left.ref $rotr.sub.right $rotr.sub.right.ref))
  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $o (i32.mul (local.get $i) (i32.const 24)))
      (if (i64.ne (call_indirect (type $bin) (i64.load (i32.add (local.get $o) (i32.const 0))) (i64.load (i32.add (local.get $o) (i32.const 8))) (i64.load (i32.add (local.get $o) (i32.const 16))) (local.get $f))
                  (call_indirect (type $bin) (i64.load (i32.add (local.get $o) (i32.const 0))) (i64.load (i32.add (local.get $o) (i32.const 8))) (i64.load (i32.add (local.get $o) (i32.const 16))) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 512))))
    (local.get $n))
;; A local.set right after a pushed local must store that local's value,
;; not the operation emitted before it.
  (func (export "set-local") (param $a i64) (param $b i64) (param $c i64) (result i64) (local $x i64)
    (i64.shl (local.get $a) (local.get $b)) (local.get $c) (local.set $x) (drop) (local.get $x))
;; A label between the two operations blocks the fold.
  (func (export "label") (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (block (result i64) (i64.mul (local.get $a) (local.get $b))) (local.get $c)))
;; A chain of three folds the first pair and keeps the third operation.
  (func (export "chain") (param $a i64) (param $b i64) (param $c i64) (param $d i64) (result i64) (i64.sub (i64.add (i64.mul (local.get $a) (local.get $b)) (local.get $c)) (local.get $d)))
;; A live intermediate is not folded.
  (func (export "live") (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64)
    (local.set $t (i64.mul (local.get $a) (local.get $b))) (i64.add (i64.add (local.get $t) (local.get $c)) (local.get $t)))
;; Constant operands on both operations.
  (func (export "const") (param $a i64) (result i64) (i64.add (i64.shl (local.get $a) (i64.const 3)) (i64.const 5)))
;; A folded and-producer or and-consumer feeding a branch.
  (func (export "and-branch") (param $a i64) (param $b i64) (param $c i64) (result i32)
    (block (br_if 0 (i64.eqz (i64.and (i64.shr_u (local.get $a) (local.get $b)) (local.get $c)))) (return (i32.const 1)))
    (block (br_if 0 (i64.ne (i64.and (i64.xor (local.get $a) (local.get $b)) (local.get $c)) (i64.const 0))) (return (i32.const 2)))
    (i32.const 3))
;; Division has no superinstruction.
  (func (export "div") (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (i64.div_s (local.get $a) (local.get $b)) (local.get $c)))
)
;; i64 xor.rotl.left
(assert_return (invoke "check" (i32.const 0)) (i32.const 0))
;; i64 xor.rotl.right
(assert_return (invoke "check" (i32.const 1)) (i32.const 0))
;; i64 mul.add.left
(assert_return (invoke "check" (i32.const 2)) (i32.const 0))
;; i64 mul.add.right
(assert_return (invoke "check" (i32.const 3)) (i32.const 0))
;; i64 shl.and.left
(assert_return (invoke "check" (i32.const 4)) (i32.const 0))
;; i64 shl.and.right
(assert_return (invoke "check" (i32.const 5)) (i32.const 0))
;; i64 and.mul.left
(assert_return (invoke "check" (i32.const 6)) (i32.const 0))
;; i64 and.mul.right
(assert_return (invoke "check" (i32.const 7)) (i32.const 0))
;; i64 shl.or.left
(assert_return (invoke "check" (i32.const 8)) (i32.const 0))
;; i64 shl.or.right
(assert_return (invoke "check" (i32.const 9)) (i32.const 0))
;; i64 xor.and.left
(assert_return (invoke "check" (i32.const 10)) (i32.const 0))
;; i64 xor.and.right
(assert_return (invoke "check" (i32.const 11)) (i32.const 0))
;; i64 mul.xor.left
(assert_return (invoke "check" (i32.const 12)) (i32.const 0))
;; i64 mul.xor.right
(assert_return (invoke "check" (i32.const 13)) (i32.const 0))
;; i64 and.xor.left
(assert_return (invoke "check" (i32.const 14)) (i32.const 0))
;; i64 and.xor.right
(assert_return (invoke "check" (i32.const 15)) (i32.const 0))
;; i64 rotl.xor.left
(assert_return (invoke "check" (i32.const 16)) (i32.const 0))
;; i64 rotl.xor.right
(assert_return (invoke "check" (i32.const 17)) (i32.const 0))
;; i64 sub.and.left
(assert_return (invoke "check" (i32.const 18)) (i32.const 0))
;; i64 sub.and.right
(assert_return (invoke "check" (i32.const 19)) (i32.const 0))
;; i64 xor.xor.left
(assert_return (invoke "check" (i32.const 20)) (i32.const 0))
;; i64 xor.xor.right
(assert_return (invoke "check" (i32.const 21)) (i32.const 0))
;; i64 or.or.left
(assert_return (invoke "check" (i32.const 22)) (i32.const 0))
;; i64 or.or.right
(assert_return (invoke "check" (i32.const 23)) (i32.const 0))
;; i64 shr_u.and.left
(assert_return (invoke "check" (i32.const 24)) (i32.const 0))
;; i64 shr_u.and.right
(assert_return (invoke "check" (i32.const 25)) (i32.const 0))
;; i64 and.and.left
(assert_return (invoke "check" (i32.const 26)) (i32.const 0))
;; i64 and.and.right
(assert_return (invoke "check" (i32.const 27)) (i32.const 0))
;; i64 xor.mul.left
(assert_return (invoke "check" (i32.const 28)) (i32.const 0))
;; i64 xor.mul.right
(assert_return (invoke "check" (i32.const 29)) (i32.const 0))
;; i64 xor.shr_u.left
(assert_return (invoke "check" (i32.const 30)) (i32.const 0))
;; i64 xor.shr_u.right
(assert_return (invoke "check" (i32.const 31)) (i32.const 0))
;; i64 mul.sub.left
(assert_return (invoke "check" (i32.const 32)) (i32.const 0))
;; i64 mul.sub.right
(assert_return (invoke "check" (i32.const 33)) (i32.const 0))
;; i64 shr_s.rotr.left
(assert_return (invoke "check" (i32.const 34)) (i32.const 0))
;; i64 shr_s.rotr.right
(assert_return (invoke "check" (i32.const 35)) (i32.const 0))
;; i64 rotr.sub.left
(assert_return (invoke "check" (i32.const 36)) (i32.const 0))
;; i64 rotr.sub.right
(assert_return (invoke "check" (i32.const 37)) (i32.const 0))
(assert_return (invoke "set-local" (i64.const 3) (i64.const 4) (i64.const 5)) (i64.const 5))
(assert_return (invoke "label" (i64.const 3) (i64.const 4) (i64.const 5)) (i64.const 17))
(assert_return (invoke "chain" (i64.const 3) (i64.const 4) (i64.const 5) (i64.const 2)) (i64.const 15))
(assert_return (invoke "live" (i64.const 3) (i64.const 4) (i64.const 5)) (i64.const 29))
(assert_return (invoke "const" (i64.const 2)) (i64.const 21))
(assert_return (invoke "and-branch" (i64.const 12) (i64.const 2) (i64.const 1)) (i32.const 1))
(assert_return (invoke "and-branch" (i64.const 12) (i64.const 2) (i64.const 4)) (i32.const 3))
(assert_return (invoke "and-branch" (i64.const 12) (i64.const 2) (i64.const 16)) (i32.const 2))
(assert_return (invoke "div" (i64.const -7) (i64.const 2) (i64.const 1)) (i64.const -2))
