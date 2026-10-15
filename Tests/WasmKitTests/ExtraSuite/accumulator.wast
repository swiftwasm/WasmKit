;; GENERATED FILE, DO NOT EDIT. Regenerate with:
;;   python3 Tests/WasmKitTests/ExtraSuite/accumulator.gen.py > Tests/WasmKitTests/ExtraSuite/accumulator.wast

(module
  (memory 1)
  (data (i32.const 0) "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\1f\00\00\00\00\00\00\00\00\00\00\00!\00\00\00\00\00\00\00\00\00\00\00xV4\12\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\ff\ff\ff\ff\00\00\00\00\01\00\00\00\ff\ff\ff\7f\00\00\00\00\01\00\00\00\00\00\00\80\00\00\00\00\01\00\00\00\1f\00\00\00\00\00\00\00\01\00\00\00!\00\00\00\00\00\00\00\01\00\00\00xV4\12\00\00\00\00\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\ff\00\00\00\80\00\00\00\00\ff\ff\ff\ff\1f\00\00\00\00\00\00\00\ff\ff\ff\ff!\00\00\00\00\00\00\00\ff\ff\ff\ffxV4\12\00\00\00\00\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\7f\00\00\00\80\00\00\00\00\ff\ff\ff\7f\1f\00\00\00\00\00\00\00\ff\ff\ff\7f!\00\00\00\00\00\00\00\ff\ff\ff\7fxV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\80\00\00\00\00\00\00\00\80\1f\00\00\00\00\00\00\00\00\00\00\80!\00\00\00\00\00\00\00\00\00\00\80xV4\12\00\00\00\00\1f\00\00\00\00\00\00\00\00\00\00\00\1f\00\00\00\01\00\00\00\00\00\00\00\1f\00\00\00\ff\ff\ff\ff\00\00\00\00\1f\00\00\00\ff\ff\ff\7f\00\00\00\00\1f\00\00\00\00\00\00\80\00\00\00\00\1f\00\00\00\1f\00\00\00\00\00\00\00\1f\00\00\00!\00\00\00\00\00\00\00\1f\00\00\00xV4\12\00\00\00\00!\00\00\00\00\00\00\00\00\00\00\00!\00\00\00\01\00\00\00\00\00\00\00!\00\00\00\ff\ff\ff\ff\00\00\00\00!\00\00\00\ff\ff\ff\7f\00\00\00\00!\00\00\00\00\00\00\80\00\00\00\00!\00\00\00\1f\00\00\00\00\00\00\00!\00\00\00!\00\00\00\00\00\00\00!\00\00\00xV4\12\00\00\00\00xV4\12\00\00\00\00\00\00\00\00xV4\12\01\00\00\00\00\00\00\00xV4\12\ff\ff\ff\ff\00\00\00\00xV4\12\ff\ff\ff\7f\00\00\00\00xV4\12\00\00\00\80\00\00\00\00xV4\12\1f\00\00\00\00\00\00\00xV4\12!\00\00\00\00\00\00\00xV4\12xV4\12\01\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\1f\00\00\00\01\00\00\00\00\00\00\00!\00\00\00\01\00\00\00\00\00\00\00xV4\12\01\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\01\00\00\00\01\00\00\00\01\00\00\00\ff\ff\ff\ff\01\00\00\00\01\00\00\00\ff\ff\ff\7f\01\00\00\00\01\00\00\00\00\00\00\80\01\00\00\00\01\00\00\00\1f\00\00\00\01\00\00\00\01\00\00\00!\00\00\00\01\00\00\00\01\00\00\00xV4\12\01\00\00\00\ff\ff\ff\ff\00\00\00\00\01\00\00\00\ff\ff\ff\ff\01\00\00\00\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\ff\00\00\00\80\01\00\00\00\ff\ff\ff\ff\1f\00\00\00\01\00\00\00\ff\ff\ff\ff!\00\00\00\01\00\00\00\ff\ff\ff\ffxV4\12\01\00\00\00\ff\ff\ff\7f\00\00\00\00\01\00\00\00\ff\ff\ff\7f\01\00\00\00\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\7f\00\00\00\80\01\00\00\00\ff\ff\ff\7f\1f\00\00\00\01\00\00\00\ff\ff\ff\7f!\00\00\00\01\00\00\00\ff\ff\ff\7fxV4\12\01\00\00\00\00\00\00\80\00\00\00\00\01\00\00\00\00\00\00\80\01\00\00\00\01\00\00\00\00\00\00\80\ff\ff\ff\ff\01\00\00\00\00\00\00\80\ff\ff\ff\7f\01\00\00\00\00\00\00\80\00\00\00\80\01\00\00\00\00\00\00\80\1f\00\00\00\01\00\00\00\00\00\00\80!\00\00\00\01\00\00\00\00\00\00\80xV4\12\01\00\00\00\1f\00\00\00\00\00\00\00\01\00\00\00\1f\00\00\00\01\00\00\00\01\00\00\00\1f\00\00\00\ff\ff\ff\ff\01\00\00\00\1f\00\00\00\ff\ff\ff\7f\01\00\00\00\1f\00\00\00\00\00\00\80\01\00\00\00\1f\00\00\00\1f\00\00\00\01\00\00\00\1f\00\00\00!\00\00\00\01\00\00\00\1f\00\00\00xV4\12\01\00\00\00!\00\00\00\00\00\00\00\01\00\00\00!\00\00\00\01\00\00\00\01\00\00\00!\00\00\00\ff\ff\ff\ff\01\00\00\00!\00\00\00\ff\ff\ff\7f\01\00\00\00!\00\00\00\00\00\00\80\01\00\00\00!\00\00\00\1f\00\00\00\01\00\00\00!\00\00\00!\00\00\00\01\00\00\00!\00\00\00xV4\12\01\00\00\00xV4\12\00\00\00\00\01\00\00\00xV4\12\01\00\00\00\01\00\00\00xV4\12\ff\ff\ff\ff\01\00\00\00xV4\12\ff\ff\ff\7f\01\00\00\00xV4\12\00\00\00\80\01\00\00\00xV4\12\1f\00\00\00\01\00\00\00xV4\12!\00\00\00\01\00\00\00xV4\12xV4\12\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\00\00\00\00\01\00\00\00\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\00\00\00\00\1f\00\00\00\ff\ff\ff\ff\00\00\00\00!\00\00\00\ff\ff\ff\ff\00\00\00\00xV4\12\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\01\00\00\00\01\00\00\00\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\01\00\00\00\00\00\00\80\ff\ff\ff\ff\01\00\00\00\1f\00\00\00\ff\ff\ff\ff\01\00\00\00!\00\00\00\ff\ff\ff\ff\01\00\00\00xV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff!\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffxV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f!\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fxV4\12\ff\ff\ff\ff\00\00\00\80\00\00\00\00\ff\ff\ff\ff\00\00\00\80\01\00\00\00\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\80\00\00\00\80\ff\ff\ff\ff\00\00\00\80\1f\00\00\00\ff\ff\ff\ff\00\00\00\80!\00\00\00\ff\ff\ff\ff\00\00\00\80xV4\12\ff\ff\ff\ff\1f\00\00\00\00\00\00\00\ff\ff\ff\ff\1f\00\00\00\01\00\00\00\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\1f\00\00\00\00\00\00\80\ff\ff\ff\ff\1f\00\00\00\1f\00\00\00\ff\ff\ff\ff\1f\00\00\00!\00\00\00\ff\ff\ff\ff\1f\00\00\00xV4\12\ff\ff\ff\ff!\00\00\00\00\00\00\00\ff\ff\ff\ff!\00\00\00\01\00\00\00\ff\ff\ff\ff!\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff!\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff!\00\00\00\00\00\00\80\ff\ff\ff\ff!\00\00\00\1f\00\00\00\ff\ff\ff\ff!\00\00\00!\00\00\00\ff\ff\ff\ff!\00\00\00xV4\12\ff\ff\ff\ffxV4\12\00\00\00\00\ff\ff\ff\ffxV4\12\01\00\00\00\ff\ff\ff\ffxV4\12\ff\ff\ff\ff\ff\ff\ff\ffxV4\12\ff\ff\ff\7f\ff\ff\ff\ffxV4\12\00\00\00\80\ff\ff\ff\ffxV4\12\1f\00\00\00\ff\ff\ff\ffxV4\12!\00\00\00\ff\ff\ff\ffxV4\12xV4\12\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\7f\00\00\00\00\01\00\00\00\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\7f\00\00\00\00\1f\00\00\00\ff\ff\ff\7f\00\00\00\00!\00\00\00\ff\ff\ff\7f\00\00\00\00xV4\12\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\7f\01\00\00\00\01\00\00\00\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\01\00\00\00\00\00\00\80\ff\ff\ff\7f\01\00\00\00\1f\00\00\00\ff\ff\ff\7f\01\00\00\00!\00\00\00\ff\ff\ff\7f\01\00\00\00xV4\12\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff!\00\00\00\ff\ff\ff\7f\ff\ff\ff\ffxV4\12\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\01\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f!\00\00\00\ff\ff\ff\7f\ff\ff\ff\7fxV4\12\ff\ff\ff\7f\00\00\00\80\00\00\00\00\ff\ff\ff\7f\00\00\00\80\01\00\00\00\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\80\00\00\00\80\ff\ff\ff\7f\00\00\00\80\1f\00\00\00\ff\ff\ff\7f\00\00\00\80!\00\00\00\ff\ff\ff\7f\00\00\00\80xV4\12\ff\ff\ff\7f\1f\00\00\00\00\00\00\00\ff\ff\ff\7f\1f\00\00\00\01\00\00\00\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\1f\00\00\00\00\00\00\80\ff\ff\ff\7f\1f\00\00\00\1f\00\00\00\ff\ff\ff\7f\1f\00\00\00!\00\00\00\ff\ff\ff\7f\1f\00\00\00xV4\12\ff\ff\ff\7f!\00\00\00\00\00\00\00\ff\ff\ff\7f!\00\00\00\01\00\00\00\ff\ff\ff\7f!\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f!\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f!\00\00\00\00\00\00\80\ff\ff\ff\7f!\00\00\00\1f\00\00\00\ff\ff\ff\7f!\00\00\00!\00\00\00\ff\ff\ff\7f!\00\00\00xV4\12\ff\ff\ff\7fxV4\12\00\00\00\00\ff\ff\ff\7fxV4\12\01\00\00\00\ff\ff\ff\7fxV4\12\ff\ff\ff\ff\ff\ff\ff\7fxV4\12\ff\ff\ff\7f\ff\ff\ff\7fxV4\12\00\00\00\80\ff\ff\ff\7fxV4\12\1f\00\00\00\ff\ff\ff\7fxV4\12!\00\00\00\ff\ff\ff\7fxV4\12xV4\12\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\01\00\00\00\00\00\00\80\00\00\00\00\ff\ff\ff\ff\00\00\00\80\00\00\00\00\ff\ff\ff\7f\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\80\00\00\00\00\1f\00\00\00\00\00\00\80\00\00\00\00!\00\00\00\00\00\00\80\00\00\00\00xV4\12\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\01\00\00\00\00\00\00\80\01\00\00\00\ff\ff\ff\ff\00\00\00\80\01\00\00\00\ff\ff\ff\7f\00\00\00\80\01\00\00\00\00\00\00\80\00\00\00\80\01\00\00\00\1f\00\00\00\00\00\00\80\01\00\00\00!\00\00\00\00\00\00\80\01\00\00\00xV4\12\00\00\00\80\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\01\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\ff\00\00\00\80\00\00\00\80\ff\ff\ff\ff\1f\00\00\00\00\00\00\80\ff\ff\ff\ff!\00\00\00\00\00\00\80\ff\ff\ff\ffxV4\12\00\00\00\80\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\7f\01\00\00\00\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\ff\00\00\00\80\ff\ff\ff\7f\ff\ff\ff\7f\00\00\00\80\ff\ff\ff\7f\00\00\00\80\00\00\00\80\ff\ff\ff\7f\1f\00\00\00\00\00\00\80\ff\ff\ff\7f!\00\00\00\00\00\00\80\ff\ff\ff\7fxV4\12\00\00\00\80\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\80\01\00\00\00\00\00\00\80\00\00\00\80\ff\ff\ff\ff\00\00\00\80\00\00\00\80\ff\ff\ff\7f\00\00\00\80\00\00\00\80\00\00\00\80\00\00\00\80\00\00\00\80\1f\00\00\00\00\00\00\80\00\00\00\80!\00\00\00\00\00\00\80\00\00\00\80xV4\12\00\00\00\80\1f\00\00\00\00\00\00\00\00\00\00\80\1f\00\00\00\01\00\00\00\00\00\00\80\1f\00\00\00\ff\ff\ff\ff\00\00\00\80\1f\00\00\00\ff\ff\ff\7f\00\00\00\80\1f\00\00\00\00\00\00\80\00\00\00\80\1f\00\00\00\1f\00\00\00\00\00\00\80\1f\00\00\00!\00\00\00\00\00\00\80\1f\00\00\00xV4\12\00\00\00\80!\00\00\00\00\00\00\00\00\00\00\80!\00\00\00\01\00\00\00\00\00\00\80!\00\00\00\ff\ff\ff\ff\00\00\00\80!\00\00\00\ff\ff\ff\7f\00\00\00\80!\00\00\00\00\00\00\80\00\00\00\80!\00\00\00\1f\00\00\00\00\00\00\80!\00\00\00!\00\00\00\00\00\00\80!\00\00\00xV4\12\00\00\00\80xV4\12\00\00\00\00\00\00\00\80xV4\12\01\00\00\00\00\00\00\80xV4\12\ff\ff\ff\ff\00\00\00\80xV4\12\ff\ff\ff\7f\00\00\00\80xV4\12\00\00\00\80\00\00\00\80xV4\12\1f\00\00\00\00\00\00\80xV4\12!\00\00\00\00\00\00\80xV4\12xV4\12\1f\00\00\00\00\00\00\00\00\00\00\00\1f\00\00\00\00\00\00\00\01\00\00\00\1f\00\00\00\00\00\00\00\ff\ff\ff\ff\1f\00\00\00\00\00\00\00\ff\ff\ff\7f\1f\00\00\00\00\00\00\00\00\00\00\80\1f\00\00\00\00\00\00\00\1f\00\00\00\1f\00\00\00\00\00\00\00!\00\00\00\1f\00\00\00\00\00\00\00xV4\12\1f\00\00\00\01\00\00\00\00\00\00\00\1f\00\00\00\01\00\00\00\01\00\00\00\1f\00\00\00\01\00\00\00\ff\ff\ff\ff\1f\00\00\00\01\00\00\00\ff\ff\ff\7f\1f\00\00\00\01\00\00\00\00\00\00\80\1f\00\00\00\01\00\00\00\1f\00\00\00\1f\00\00\00\01\00\00\00!\00\00\00\1f\00\00\00\01\00\00\00xV4\12\1f\00\00\00\ff\ff\ff\ff\00\00\00\00\1f\00\00\00\ff\ff\ff\ff\01\00\00\00\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\ff\00\00\00\80\1f\00\00\00\ff\ff\ff\ff\1f\00\00\00\1f\00\00\00\ff\ff\ff\ff!\00\00\00\1f\00\00\00\ff\ff\ff\ffxV4\12\1f\00\00\00\ff\ff\ff\7f\00\00\00\00\1f\00\00\00\ff\ff\ff\7f\01\00\00\00\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff\1f\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f\1f\00\00\00\ff\ff\ff\7f\00\00\00\80\1f\00\00\00\ff\ff\ff\7f\1f\00\00\00\1f\00\00\00\ff\ff\ff\7f!\00\00\00\1f\00\00\00\ff\ff\ff\7fxV4\12\1f\00\00\00\00\00\00\80\00\00\00\00\1f\00\00\00\00\00\00\80\01\00\00\00\1f\00\00\00\00\00\00\80\ff\ff\ff\ff\1f\00\00\00\00\00\00\80\ff\ff\ff\7f\1f\00\00\00\00\00\00\80\00\00\00\80\1f\00\00\00\00\00\00\80\1f\00\00\00\1f\00\00\00\00\00\00\80!\00\00\00\1f\00\00\00\00\00\00\80xV4\12\1f\00\00\00\1f\00\00\00\00\00\00\00\1f\00\00\00\1f\00\00\00\01\00\00\00\1f\00\00\00\1f\00\00\00\ff\ff\ff\ff\1f\00\00\00\1f\00\00\00\ff\ff\ff\7f\1f\00\00\00\1f\00\00\00\00\00\00\80\1f\00\00\00\1f\00\00\00\1f\00\00\00\1f\00\00\00\1f\00\00\00!\00\00\00\1f\00\00\00\1f\00\00\00xV4\12\1f\00\00\00!\00\00\00\00\00\00\00\1f\00\00\00!\00\00\00\01\00\00\00\1f\00\00\00!\00\00\00\ff\ff\ff\ff\1f\00\00\00!\00\00\00\ff\ff\ff\7f\1f\00\00\00!\00\00\00\00\00\00\80\1f\00\00\00!\00\00\00\1f\00\00\00\1f\00\00\00!\00\00\00!\00\00\00\1f\00\00\00!\00\00\00xV4\12\1f\00\00\00xV4\12\00\00\00\00\1f\00\00\00xV4\12\01\00\00\00\1f\00\00\00xV4\12\ff\ff\ff\ff\1f\00\00\00xV4\12\ff\ff\ff\7f\1f\00\00\00xV4\12\00\00\00\80\1f\00\00\00xV4\12\1f\00\00\00\1f\00\00\00xV4\12!\00\00\00\1f\00\00\00xV4\12xV4\12!\00\00\00\00\00\00\00\00\00\00\00!\00\00\00\00\00\00\00\01\00\00\00!\00\00\00\00\00\00\00\ff\ff\ff\ff!\00\00\00\00\00\00\00\ff\ff\ff\7f!\00\00\00\00\00\00\00\00\00\00\80!\00\00\00\00\00\00\00\1f\00\00\00!\00\00\00\00\00\00\00!\00\00\00!\00\00\00\00\00\00\00xV4\12!\00\00\00\01\00\00\00\00\00\00\00!\00\00\00\01\00\00\00\01\00\00\00!\00\00\00\01\00\00\00\ff\ff\ff\ff!\00\00\00\01\00\00\00\ff\ff\ff\7f!\00\00\00\01\00\00\00\00\00\00\80!\00\00\00\01\00\00\00\1f\00\00\00!\00\00\00\01\00\00\00!\00\00\00!\00\00\00\01\00\00\00xV4\12!\00\00\00\ff\ff\ff\ff\00\00\00\00!\00\00\00\ff\ff\ff\ff\01\00\00\00!\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff!\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f!\00\00\00\ff\ff\ff\ff\00\00\00\80!\00\00\00\ff\ff\ff\ff\1f\00\00\00!\00\00\00\ff\ff\ff\ff!\00\00\00!\00\00\00\ff\ff\ff\ffxV4\12!\00\00\00\ff\ff\ff\7f\00\00\00\00!\00\00\00\ff\ff\ff\7f\01\00\00\00!\00\00\00\ff\ff\ff\7f\ff\ff\ff\ff!\00\00\00\ff\ff\ff\7f\ff\ff\ff\7f!\00\00\00\ff\ff\ff\7f\00\00\00\80!\00\00\00\ff\ff\ff\7f\1f\00\00\00!\00\00\00\ff\ff\ff\7f!\00\00\00!\00\00\00\ff\ff\ff\7fxV4\12!\00\00\00\00\00\00\80\00\00\00\00!\00\00\00\00\00\00\80\01\00\00\00!\00\00\00\00\00\00\80\ff\ff\ff\ff!\00\00\00\00\00\00\80\ff\ff\ff\7f!\00\00\00\00\00\00\80\00\00\00\80!\00\00\00\00\00\00\80\1f\00\00\00!\00\00\00\00\00\00\80!\00\00\00!\00\00\00\00\00\00\80xV4\12!\00\00\00\1f\00\00\00\00\00\00\00!\00\00\00\1f\00\00\00\01\00\00\00!\00\00\00\1f\00\00\00\ff\ff\ff\ff!\00\00\00\1f\00\00\00\ff\ff\ff\7f!\00\00\00\1f\00\00\00\00\00\00\80!\00\00\00\1f\00\00\00\1f\00\00\00!\00\00\00\1f\00\00\00!\00\00\00!\00\00\00\1f\00\00\00xV4\12!\00\00\00!\00\00\00\00\00\00\00!\00\00\00!\00\00\00\01\00\00\00!\00\00\00!\00\00\00\ff\ff\ff\ff!\00\00\00!\00\00\00\ff\ff\ff\7f!\00\00\00!\00\00\00\00\00\00\80!\00\00\00!\00\00\00\1f\00\00\00!\00\00\00!\00\00\00!\00\00\00!\00\00\00!\00\00\00xV4\12!\00\00\00xV4\12\00\00\00\00!\00\00\00xV4\12\01\00\00\00!\00\00\00xV4\12\ff\ff\ff\ff!\00\00\00xV4\12\ff\ff\ff\7f!\00\00\00xV4\12\00\00\00\80!\00\00\00xV4\12\1f\00\00\00!\00\00\00xV4\12!\00\00\00!\00\00\00xV4\12xV4\12xV4\12\00\00\00\00\00\00\00\00xV4\12\00\00\00\00\01\00\00\00xV4\12\00\00\00\00\ff\ff\ff\ffxV4\12\00\00\00\00\ff\ff\ff\7fxV4\12\00\00\00\00\00\00\00\80xV4\12\00\00\00\00\1f\00\00\00xV4\12\00\00\00\00!\00\00\00xV4\12\00\00\00\00xV4\12xV4\12\01\00\00\00\00\00\00\00xV4\12\01\00\00\00\01\00\00\00xV4\12\01\00\00\00\ff\ff\ff\ffxV4\12\01\00\00\00\ff\ff\ff\7fxV4\12\01\00\00\00\00\00\00\80xV4\12\01\00\00\00\1f\00\00\00xV4\12\01\00\00\00!\00\00\00xV4\12\01\00\00\00xV4\12xV4\12\ff\ff\ff\ff\00\00\00\00xV4\12\ff\ff\ff\ff\01\00\00\00xV4\12\ff\ff\ff\ff\ff\ff\ff\ffxV4\12\ff\ff\ff\ff\ff\ff\ff\7fxV4\12\ff\ff\ff\ff\00\00\00\80xV4\12\ff\ff\ff\ff\1f\00\00\00xV4\12\ff\ff\ff\ff!\00\00\00xV4\12\ff\ff\ff\ffxV4\12xV4\12\ff\ff\ff\7f\00\00\00\00xV4\12\ff\ff\ff\7f\01\00\00\00xV4\12\ff\ff\ff\7f\ff\ff\ff\ffxV4\12\ff\ff\ff\7f\ff\ff\ff\7fxV4\12\ff\ff\ff\7f\00\00\00\80xV4\12\ff\ff\ff\7f\1f\00\00\00xV4\12\ff\ff\ff\7f!\00\00\00xV4\12\ff\ff\ff\7fxV4\12xV4\12\00\00\00\80\00\00\00\00xV4\12\00\00\00\80\01\00\00\00xV4\12\00\00\00\80\ff\ff\ff\ffxV4\12\00\00\00\80\ff\ff\ff\7fxV4\12\00\00\00\80\00\00\00\80xV4\12\00\00\00\80\1f\00\00\00xV4\12\00\00\00\80!\00\00\00xV4\12\00\00\00\80xV4\12xV4\12\1f\00\00\00\00\00\00\00xV4\12\1f\00\00\00\01\00\00\00xV4\12\1f\00\00\00\ff\ff\ff\ffxV4\12\1f\00\00\00\ff\ff\ff\7fxV4\12\1f\00\00\00\00\00\00\80xV4\12\1f\00\00\00\1f\00\00\00xV4\12\1f\00\00\00!\00\00\00xV4\12\1f\00\00\00xV4\12xV4\12!\00\00\00\00\00\00\00xV4\12!\00\00\00\01\00\00\00xV4\12!\00\00\00\ff\ff\ff\ffxV4\12!\00\00\00\ff\ff\ff\7fxV4\12!\00\00\00\00\00\00\80xV4\12!\00\00\00\1f\00\00\00xV4\12!\00\00\00!\00\00\00xV4\12!\00\00\00xV4\12xV4\12xV4\12\00\00\00\00xV4\12xV4\12\01\00\00\00xV4\12xV4\12\ff\ff\ff\ffxV4\12xV4\12\ff\ff\ff\7fxV4\12xV4\12\00\00\00\80xV4\12xV4\12\1f\00\00\00xV4\12xV4\12!\00\00\00xV4\12xV4\12xV4\12")
  (func $add.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $add.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.add (local.get $t) (local.get $c)))
  (func $add.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $add.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.add (local.get $c) (local.get $t)))
  (func $add.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $add.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.add (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $sub.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $sub.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.sub (local.get $t) (local.get $c)))
  (func $sub.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.sub (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $sub.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.sub (local.get $c) (local.get $t)))
  (func $sub.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.sub (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $sub.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.sub (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $mul.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.mul (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $mul.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.mul (local.get $t) (local.get $c)))
  (func $mul.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.mul (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $mul.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.mul (local.get $c) (local.get $t)))
  (func $mul.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.mul (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $mul.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.mul (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $and.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $and.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.and (local.get $t) (local.get $c)))
  (func $and.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $and.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.and (local.get $c) (local.get $t)))
  (func $and.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.and (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $and.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.and (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $or.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.or (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $or.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.or (local.get $t) (local.get $c)))
  (func $or.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.or (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $or.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.or (local.get $c) (local.get $t)))
  (func $or.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.or (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $or.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.or (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $xor.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.xor (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.xor (local.get $t) (local.get $c)))
  (func $xor.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.xor (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $xor.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.xor (local.get $c) (local.get $t)))
  (func $xor.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.xor (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $xor.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.xor (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $shl.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shl (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $shl.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shl (local.get $t) (local.get $c)))
  (func $shl.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shl (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $shl.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shl (local.get $c) (local.get $t)))
  (func $shl.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shl (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $shl.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shl (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $shr_s.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_s.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shr_s (local.get $t) (local.get $c)))
  (func $shr_s.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $shr_s.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shr_s (local.get $c) (local.get $t)))
  (func $shr_s.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_s (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $shr_s.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shr_s (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $shr_u.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_u.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shr_u (local.get $t) (local.get $c)))
  (func $shr_u.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $shr_u.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shr_u (local.get $c) (local.get $t)))
  (func $shr_u.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.shr_u (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $shr_u.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.shr_u (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $rotl.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotl (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $rotl.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.rotl (local.get $t) (local.get $c)))
  (func $rotl.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotl (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $rotl.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.rotl (local.get $c) (local.get $t)))
  (func $rotl.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotl (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $rotl.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.rotl (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $rotr.left (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotr (i32.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $rotr.left.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.rotr (local.get $t) (local.get $c)))
  (func $rotr.right (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotr (local.get $c) (i32.rotr (local.get $a) (local.get $b))))
  (func $rotr.right.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.rotr (local.get $c) (local.get $t)))
  (func $rotr.chain (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.rotr (i32.sub (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $rotr.chain.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.rotr (i32.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $eq.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.eq (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $eq.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.eq (local.get $t) (local.get $c)))
  (func $eq.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.eq (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $eq.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.eq (local.get $t) (local.get $c)))
  (func $eq.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.eq (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $eq.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.eq (local.get $t) (local.get $c)))
  (func $eq.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.eq (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $eq.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.eq (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $eq.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.eq (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $eq.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.eq (local.get $c) (local.get $t)))
  (func $eq.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.eq (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $eq.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.eq (local.get $c) (local.get $t)))
  (func $eq.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.eq (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $eq.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.eq (local.get $c) (local.get $t)))
  (func $eq.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.eq (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $eq.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.eq (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ne.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.ne (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $ne.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $t) (local.get $c)))
  (func $ne.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.ne (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $ne.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $t) (local.get $c)))
  (func $ne.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.ne (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $ne.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $t) (local.get $c)))
  (func $ne.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.ne (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $ne.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.ne (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ne.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.ne (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $ne.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $c) (local.get $t)))
  (func $ne.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.ne (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $ne.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $c) (local.get $t)))
  (func $ne.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.ne (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $ne.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $c) (local.get $t)))
  (func $ne.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.ne (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $ne.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.ne (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_s.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.lt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $lt_s.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_s (local.get $t) (local.get $c)))
  (func $lt_s.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.lt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_s.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_s (local.get $t) (local.get $c)))
  (func $lt_s.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.lt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $lt_s.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_s (local.get $t) (local.get $c)))
  (func $lt_s.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.lt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $lt_s.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.lt_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_s.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.lt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $lt_s.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_s (local.get $c) (local.get $t)))
  (func $lt_s.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.lt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_s.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_s (local.get $c) (local.get $t)))
  (func $lt_s.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.lt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $lt_s.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_s (local.get $c) (local.get $t)))
  (func $lt_s.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.lt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $lt_s.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.lt_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_u.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.lt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $lt_u.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_u (local.get $t) (local.get $c)))
  (func $lt_u.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.lt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_u.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_u (local.get $t) (local.get $c)))
  (func $lt_u.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.lt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $lt_u.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_u (local.get $t) (local.get $c)))
  (func $lt_u.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.lt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $lt_u.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.lt_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_u.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.lt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $lt_u.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_u (local.get $c) (local.get $t)))
  (func $lt_u.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.lt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_u.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_u (local.get $c) (local.get $t)))
  (func $lt_u.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.lt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $lt_u.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.lt_u (local.get $c) (local.get $t)))
  (func $lt_u.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.lt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $lt_u.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.lt_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_s.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.gt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $gt_s.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_s (local.get $t) (local.get $c)))
  (func $gt_s.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.gt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_s.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_s (local.get $t) (local.get $c)))
  (func $gt_s.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.gt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $gt_s.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_s (local.get $t) (local.get $c)))
  (func $gt_s.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.gt_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $gt_s.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.gt_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_s.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.gt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $gt_s.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_s (local.get $c) (local.get $t)))
  (func $gt_s.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.gt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_s.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_s (local.get $c) (local.get $t)))
  (func $gt_s.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.gt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $gt_s.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_s (local.get $c) (local.get $t)))
  (func $gt_s.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.gt_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $gt_s.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.gt_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_u.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.gt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $gt_u.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_u (local.get $t) (local.get $c)))
  (func $gt_u.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.gt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_u.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_u (local.get $t) (local.get $c)))
  (func $gt_u.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.gt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $gt_u.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_u (local.get $t) (local.get $c)))
  (func $gt_u.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.gt_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $gt_u.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.gt_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_u.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.gt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $gt_u.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_u (local.get $c) (local.get $t)))
  (func $gt_u.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.gt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_u.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_u (local.get $c) (local.get $t)))
  (func $gt_u.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.gt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $gt_u.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.gt_u (local.get $c) (local.get $t)))
  (func $gt_u.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.gt_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $gt_u.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.gt_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_s.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.le_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $le_s.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_s (local.get $t) (local.get $c)))
  (func $le_s.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.le_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_s.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_s (local.get $t) (local.get $c)))
  (func $le_s.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.le_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $le_s.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_s (local.get $t) (local.get $c)))
  (func $le_s.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.le_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $le_s.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.le_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_s.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.le_s (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $le_s.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_s (local.get $c) (local.get $t)))
  (func $le_s.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.le_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_s.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_s (local.get $c) (local.get $t)))
  (func $le_s.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.le_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $le_s.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_s (local.get $c) (local.get $t)))
  (func $le_s.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.le_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $le_s.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.le_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_u.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.le_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $le_u.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_u (local.get $t) (local.get $c)))
  (func $le_u.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.le_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_u.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_u (local.get $t) (local.get $c)))
  (func $le_u.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.le_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $le_u.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_u (local.get $t) (local.get $c)))
  (func $le_u.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.le_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $le_u.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.le_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_u.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.le_u (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $le_u.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_u (local.get $c) (local.get $t)))
  (func $le_u.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.le_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_u.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_u (local.get $c) (local.get $t)))
  (func $le_u.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.le_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $le_u.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.le_u (local.get $c) (local.get $t)))
  (func $le_u.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.le_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $le_u.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.le_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_s.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.ge_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $ge_s.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_s (local.get $t) (local.get $c)))
  (func $ge_s.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.ge_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_s.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_s (local.get $t) (local.get $c)))
  (func $ge_s.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.ge_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $ge_s.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_s (local.get $t) (local.get $c)))
  (func $ge_s.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.ge_s (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $ge_s.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.ge_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_s.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.ge_s (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $ge_s.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_s (local.get $c) (local.get $t)))
  (func $ge_s.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.ge_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_s.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_s (local.get $c) (local.get $t)))
  (func $ge_s.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.ge_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $ge_s.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_s (local.get $c) (local.get $t)))
  (func $ge_s.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.ge_s (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $ge_s.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.ge_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_u.left.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.ge_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $ge_u.left.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_u (local.get $t) (local.get $c)))
  (func $ge_u.left.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.ge_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_u.left.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_u (local.get $t) (local.get $c)))
  (func $ge_u.left.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.ge_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $ge_u.left.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_u (local.get $t) (local.get $c)))
  (func $ge_u.left.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.ge_u (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $ge_u.left.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.ge_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_u.right.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.ge_u (local.get $c) (i32.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $ge_u.right.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_u (local.get $c) (local.get $t)))
  (func $ge_u.right.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.ge_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_u.right.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_u (local.get $c) (local.get $t)))
  (func $ge_u.right.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.ge_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $ge_u.right.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ge_u (local.get $c) (local.get $t)))
  (func $ge_u.right.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.ge_u (local.get $c) (i32.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $ge_u.right.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.ge_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $cond.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.rotr (local.get $a) (local.get $b))) (return (i32.const 0))) (i32.const 1))
  (func $cond.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $t) (i32.const 0)))
  (func $cond.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.rotr (local.get $a) (local.get $b)) (then (i32.const 1)) (else (i32.const 0))))
  (func $cond.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $t) (i32.const 0)))
  (func $cond.br_if_pad (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i32.rotr (local.get $a) (local.get $b)) (br_if 0) (i32.sub)))
  (func $cond.br_if_pad.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (if (result i32) (i32.ne (local.get $t) (i32.const 0)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $cond.br_if_copy (param $a i32) (param $b i32) (param $c i32) (result i32) (block (result i32) (i32.const 1) (i32.rotr (local.get $a) (local.get $b)) (br_if 0) (drop) (i32.const 0)))
  (func $cond.br_if_copy.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (local.get $t) (i32.const 0)))
  (func $and.br_if (param $a i32) (param $b i32) (param $c i32) (result i32) (block (br_if 0 (i32.and (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $and.br_if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (i32.and (local.get $t) (local.get $c)) (i32.const 0)))
  (func $and.eqz.if (param $a i32) (param $b i32) (param $c i32) (result i32) (if (result i32) (i32.eqz (i32.and (i32.rotr (local.get $a) (local.get $b)) (local.get $c))) (then (i32.const 0)) (else (i32.const 1))))
  (func $and.eqz.if.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.ne (i32.and (local.get $t) (local.get $c)) (i32.const 0)))
  (func $super.after (param $a i32) (param $b i32) (param $c i32) (result i32) (i32.add (i32.shl (i32.and (i32.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $b)) (local.get $a)))
  (func $super.after.ref (param $a i32) (param $b i32) (param $c i32) (result i32) (local $t i32) (local.set $t (i32.rotr (local.get $a) (local.get $b))) (i32.add (i32.shl (i32.and (local.get $t) (local.get $c)) (local.get $b)) (local.get $a)))
  (type $fi32 (func (param $a i32) (param $b i32) (param $c i32) (result i32)))
  (table funcref (elem $add.left $add.left.ref $add.right $add.right.ref $add.chain $add.chain.ref $sub.left $sub.left.ref $sub.right $sub.right.ref $sub.chain $sub.chain.ref $mul.left $mul.left.ref $mul.right $mul.right.ref $mul.chain $mul.chain.ref $and.left $and.left.ref $and.right $and.right.ref $and.chain $and.chain.ref $or.left $or.left.ref $or.right $or.right.ref $or.chain $or.chain.ref $xor.left $xor.left.ref $xor.right $xor.right.ref $xor.chain $xor.chain.ref $shl.left $shl.left.ref $shl.right $shl.right.ref $shl.chain $shl.chain.ref $shr_s.left $shr_s.left.ref $shr_s.right $shr_s.right.ref $shr_s.chain $shr_s.chain.ref $shr_u.left $shr_u.left.ref $shr_u.right $shr_u.right.ref $shr_u.chain $shr_u.chain.ref $rotl.left $rotl.left.ref $rotl.right $rotl.right.ref $rotl.chain $rotl.chain.ref $rotr.left $rotr.left.ref $rotr.right $rotr.right.ref $rotr.chain $rotr.chain.ref $eq.left.br_if $eq.left.br_if.ref $eq.left.if $eq.left.if.ref $eq.left.br_if_copy $eq.left.br_if_copy.ref $eq.left.br_if_pad $eq.left.br_if_pad.ref $eq.right.br_if $eq.right.br_if.ref $eq.right.if $eq.right.if.ref $eq.right.br_if_copy $eq.right.br_if_copy.ref $eq.right.br_if_pad $eq.right.br_if_pad.ref $ne.left.br_if $ne.left.br_if.ref $ne.left.if $ne.left.if.ref $ne.left.br_if_copy $ne.left.br_if_copy.ref $ne.left.br_if_pad $ne.left.br_if_pad.ref $ne.right.br_if $ne.right.br_if.ref $ne.right.if $ne.right.if.ref $ne.right.br_if_copy $ne.right.br_if_copy.ref $ne.right.br_if_pad $ne.right.br_if_pad.ref $lt_s.left.br_if $lt_s.left.br_if.ref $lt_s.left.if $lt_s.left.if.ref $lt_s.left.br_if_copy $lt_s.left.br_if_copy.ref $lt_s.left.br_if_pad $lt_s.left.br_if_pad.ref $lt_s.right.br_if $lt_s.right.br_if.ref $lt_s.right.if $lt_s.right.if.ref $lt_s.right.br_if_copy $lt_s.right.br_if_copy.ref $lt_s.right.br_if_pad $lt_s.right.br_if_pad.ref $lt_u.left.br_if $lt_u.left.br_if.ref $lt_u.left.if $lt_u.left.if.ref $lt_u.left.br_if_copy $lt_u.left.br_if_copy.ref $lt_u.left.br_if_pad $lt_u.left.br_if_pad.ref $lt_u.right.br_if $lt_u.right.br_if.ref $lt_u.right.if $lt_u.right.if.ref $lt_u.right.br_if_copy $lt_u.right.br_if_copy.ref $lt_u.right.br_if_pad $lt_u.right.br_if_pad.ref $gt_s.left.br_if $gt_s.left.br_if.ref $gt_s.left.if $gt_s.left.if.ref $gt_s.left.br_if_copy $gt_s.left.br_if_copy.ref $gt_s.left.br_if_pad $gt_s.left.br_if_pad.ref $gt_s.right.br_if $gt_s.right.br_if.ref $gt_s.right.if $gt_s.right.if.ref $gt_s.right.br_if_copy $gt_s.right.br_if_copy.ref $gt_s.right.br_if_pad $gt_s.right.br_if_pad.ref $gt_u.left.br_if $gt_u.left.br_if.ref $gt_u.left.if $gt_u.left.if.ref $gt_u.left.br_if_copy $gt_u.left.br_if_copy.ref $gt_u.left.br_if_pad $gt_u.left.br_if_pad.ref $gt_u.right.br_if $gt_u.right.br_if.ref $gt_u.right.if $gt_u.right.if.ref $gt_u.right.br_if_copy $gt_u.right.br_if_copy.ref $gt_u.right.br_if_pad $gt_u.right.br_if_pad.ref $le_s.left.br_if $le_s.left.br_if.ref $le_s.left.if $le_s.left.if.ref $le_s.left.br_if_copy $le_s.left.br_if_copy.ref $le_s.left.br_if_pad $le_s.left.br_if_pad.ref $le_s.right.br_if $le_s.right.br_if.ref $le_s.right.if $le_s.right.if.ref $le_s.right.br_if_copy $le_s.right.br_if_copy.ref $le_s.right.br_if_pad $le_s.right.br_if_pad.ref $le_u.left.br_if $le_u.left.br_if.ref $le_u.left.if $le_u.left.if.ref $le_u.left.br_if_copy $le_u.left.br_if_copy.ref $le_u.left.br_if_pad $le_u.left.br_if_pad.ref $le_u.right.br_if $le_u.right.br_if.ref $le_u.right.if $le_u.right.if.ref $le_u.right.br_if_copy $le_u.right.br_if_copy.ref $le_u.right.br_if_pad $le_u.right.br_if_pad.ref $ge_s.left.br_if $ge_s.left.br_if.ref $ge_s.left.if $ge_s.left.if.ref $ge_s.left.br_if_copy $ge_s.left.br_if_copy.ref $ge_s.left.br_if_pad $ge_s.left.br_if_pad.ref $ge_s.right.br_if $ge_s.right.br_if.ref $ge_s.right.if $ge_s.right.if.ref $ge_s.right.br_if_copy $ge_s.right.br_if_copy.ref $ge_s.right.br_if_pad $ge_s.right.br_if_pad.ref $ge_u.left.br_if $ge_u.left.br_if.ref $ge_u.left.if $ge_u.left.if.ref $ge_u.left.br_if_copy $ge_u.left.br_if_copy.ref $ge_u.left.br_if_pad $ge_u.left.br_if_pad.ref $ge_u.right.br_if $ge_u.right.br_if.ref $ge_u.right.if $ge_u.right.if.ref $ge_u.right.br_if_copy $ge_u.right.br_if_copy.ref $ge_u.right.br_if_pad $ge_u.right.br_if_pad.ref $cond.br_if $cond.br_if.ref $cond.if $cond.if.ref $cond.br_if_pad $cond.br_if_pad.ref $cond.br_if_copy $cond.br_if_copy.ref $and.br_if $and.br_if.ref $and.eqz.if $and.eqz.if.ref $super.after $super.after.ref))
  (func (export "check.i32") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $o (i32.mul (local.get $i) (i32.const 12)))
      (if (i32.ne (call_indirect (type $fi32) (i32.load (i32.add (local.get $o) (i32.const 0))) (i32.load (i32.add (local.get $o) (i32.const 4))) (i32.load (i32.add (local.get $o) (i32.const 8))) (local.get $f))
                  (call_indirect (type $fi32) (i32.load (i32.add (local.get $o) (i32.const 0))) (i32.load (i32.add (local.get $o) (i32.const 4))) (i32.load (i32.add (local.get $o) (i32.const 8))) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 512))))
    (local.get $n))
)
;; i32 add.left
(assert_return (invoke "check.i32" (i32.const 0)) (i32.const 0))
;; i32 add.right
(assert_return (invoke "check.i32" (i32.const 1)) (i32.const 0))
;; i32 add.chain
(assert_return (invoke "check.i32" (i32.const 2)) (i32.const 0))
;; i32 sub.left
(assert_return (invoke "check.i32" (i32.const 3)) (i32.const 0))
;; i32 sub.right
(assert_return (invoke "check.i32" (i32.const 4)) (i32.const 0))
;; i32 sub.chain
(assert_return (invoke "check.i32" (i32.const 5)) (i32.const 0))
;; i32 mul.left
(assert_return (invoke "check.i32" (i32.const 6)) (i32.const 0))
;; i32 mul.right
(assert_return (invoke "check.i32" (i32.const 7)) (i32.const 0))
;; i32 mul.chain
(assert_return (invoke "check.i32" (i32.const 8)) (i32.const 0))
;; i32 and.left
(assert_return (invoke "check.i32" (i32.const 9)) (i32.const 0))
;; i32 and.right
(assert_return (invoke "check.i32" (i32.const 10)) (i32.const 0))
;; i32 and.chain
(assert_return (invoke "check.i32" (i32.const 11)) (i32.const 0))
;; i32 or.left
(assert_return (invoke "check.i32" (i32.const 12)) (i32.const 0))
;; i32 or.right
(assert_return (invoke "check.i32" (i32.const 13)) (i32.const 0))
;; i32 or.chain
(assert_return (invoke "check.i32" (i32.const 14)) (i32.const 0))
;; i32 xor.left
(assert_return (invoke "check.i32" (i32.const 15)) (i32.const 0))
;; i32 xor.right
(assert_return (invoke "check.i32" (i32.const 16)) (i32.const 0))
;; i32 xor.chain
(assert_return (invoke "check.i32" (i32.const 17)) (i32.const 0))
;; i32 shl.left
(assert_return (invoke "check.i32" (i32.const 18)) (i32.const 0))
;; i32 shl.right
(assert_return (invoke "check.i32" (i32.const 19)) (i32.const 0))
;; i32 shl.chain
(assert_return (invoke "check.i32" (i32.const 20)) (i32.const 0))
;; i32 shr_s.left
(assert_return (invoke "check.i32" (i32.const 21)) (i32.const 0))
;; i32 shr_s.right
(assert_return (invoke "check.i32" (i32.const 22)) (i32.const 0))
;; i32 shr_s.chain
(assert_return (invoke "check.i32" (i32.const 23)) (i32.const 0))
;; i32 shr_u.left
(assert_return (invoke "check.i32" (i32.const 24)) (i32.const 0))
;; i32 shr_u.right
(assert_return (invoke "check.i32" (i32.const 25)) (i32.const 0))
;; i32 shr_u.chain
(assert_return (invoke "check.i32" (i32.const 26)) (i32.const 0))
;; i32 rotl.left
(assert_return (invoke "check.i32" (i32.const 27)) (i32.const 0))
;; i32 rotl.right
(assert_return (invoke "check.i32" (i32.const 28)) (i32.const 0))
;; i32 rotl.chain
(assert_return (invoke "check.i32" (i32.const 29)) (i32.const 0))
;; i32 rotr.left
(assert_return (invoke "check.i32" (i32.const 30)) (i32.const 0))
;; i32 rotr.right
(assert_return (invoke "check.i32" (i32.const 31)) (i32.const 0))
;; i32 rotr.chain
(assert_return (invoke "check.i32" (i32.const 32)) (i32.const 0))
;; i32 eq.left.br_if
(assert_return (invoke "check.i32" (i32.const 33)) (i32.const 0))
;; i32 eq.left.if
(assert_return (invoke "check.i32" (i32.const 34)) (i32.const 0))
;; i32 eq.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 35)) (i32.const 0))
;; i32 eq.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 36)) (i32.const 0))
;; i32 eq.right.br_if
(assert_return (invoke "check.i32" (i32.const 37)) (i32.const 0))
;; i32 eq.right.if
(assert_return (invoke "check.i32" (i32.const 38)) (i32.const 0))
;; i32 eq.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 39)) (i32.const 0))
;; i32 eq.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 40)) (i32.const 0))
;; i32 ne.left.br_if
(assert_return (invoke "check.i32" (i32.const 41)) (i32.const 0))
;; i32 ne.left.if
(assert_return (invoke "check.i32" (i32.const 42)) (i32.const 0))
;; i32 ne.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 43)) (i32.const 0))
;; i32 ne.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 44)) (i32.const 0))
;; i32 ne.right.br_if
(assert_return (invoke "check.i32" (i32.const 45)) (i32.const 0))
;; i32 ne.right.if
(assert_return (invoke "check.i32" (i32.const 46)) (i32.const 0))
;; i32 ne.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 47)) (i32.const 0))
;; i32 ne.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 48)) (i32.const 0))
;; i32 lt_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 49)) (i32.const 0))
;; i32 lt_s.left.if
(assert_return (invoke "check.i32" (i32.const 50)) (i32.const 0))
;; i32 lt_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 51)) (i32.const 0))
;; i32 lt_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 52)) (i32.const 0))
;; i32 lt_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 53)) (i32.const 0))
;; i32 lt_s.right.if
(assert_return (invoke "check.i32" (i32.const 54)) (i32.const 0))
;; i32 lt_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 55)) (i32.const 0))
;; i32 lt_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 56)) (i32.const 0))
;; i32 lt_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 57)) (i32.const 0))
;; i32 lt_u.left.if
(assert_return (invoke "check.i32" (i32.const 58)) (i32.const 0))
;; i32 lt_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 59)) (i32.const 0))
;; i32 lt_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 60)) (i32.const 0))
;; i32 lt_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 61)) (i32.const 0))
;; i32 lt_u.right.if
(assert_return (invoke "check.i32" (i32.const 62)) (i32.const 0))
;; i32 lt_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 63)) (i32.const 0))
;; i32 lt_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 64)) (i32.const 0))
;; i32 gt_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 65)) (i32.const 0))
;; i32 gt_s.left.if
(assert_return (invoke "check.i32" (i32.const 66)) (i32.const 0))
;; i32 gt_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 67)) (i32.const 0))
;; i32 gt_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 68)) (i32.const 0))
;; i32 gt_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 69)) (i32.const 0))
;; i32 gt_s.right.if
(assert_return (invoke "check.i32" (i32.const 70)) (i32.const 0))
;; i32 gt_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 71)) (i32.const 0))
;; i32 gt_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 72)) (i32.const 0))
;; i32 gt_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 73)) (i32.const 0))
;; i32 gt_u.left.if
(assert_return (invoke "check.i32" (i32.const 74)) (i32.const 0))
;; i32 gt_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 75)) (i32.const 0))
;; i32 gt_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 76)) (i32.const 0))
;; i32 gt_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 77)) (i32.const 0))
;; i32 gt_u.right.if
(assert_return (invoke "check.i32" (i32.const 78)) (i32.const 0))
;; i32 gt_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 79)) (i32.const 0))
;; i32 gt_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 80)) (i32.const 0))
;; i32 le_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 81)) (i32.const 0))
;; i32 le_s.left.if
(assert_return (invoke "check.i32" (i32.const 82)) (i32.const 0))
;; i32 le_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 83)) (i32.const 0))
;; i32 le_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 84)) (i32.const 0))
;; i32 le_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 85)) (i32.const 0))
;; i32 le_s.right.if
(assert_return (invoke "check.i32" (i32.const 86)) (i32.const 0))
;; i32 le_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 87)) (i32.const 0))
;; i32 le_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 88)) (i32.const 0))
;; i32 le_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 89)) (i32.const 0))
;; i32 le_u.left.if
(assert_return (invoke "check.i32" (i32.const 90)) (i32.const 0))
;; i32 le_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 91)) (i32.const 0))
;; i32 le_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 92)) (i32.const 0))
;; i32 le_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 93)) (i32.const 0))
;; i32 le_u.right.if
(assert_return (invoke "check.i32" (i32.const 94)) (i32.const 0))
;; i32 le_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 95)) (i32.const 0))
;; i32 le_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 96)) (i32.const 0))
;; i32 ge_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 97)) (i32.const 0))
;; i32 ge_s.left.if
(assert_return (invoke "check.i32" (i32.const 98)) (i32.const 0))
;; i32 ge_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 99)) (i32.const 0))
;; i32 ge_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 100)) (i32.const 0))
;; i32 ge_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 101)) (i32.const 0))
;; i32 ge_s.right.if
(assert_return (invoke "check.i32" (i32.const 102)) (i32.const 0))
;; i32 ge_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 103)) (i32.const 0))
;; i32 ge_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 104)) (i32.const 0))
;; i32 ge_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 105)) (i32.const 0))
;; i32 ge_u.left.if
(assert_return (invoke "check.i32" (i32.const 106)) (i32.const 0))
;; i32 ge_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 107)) (i32.const 0))
;; i32 ge_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 108)) (i32.const 0))
;; i32 ge_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 109)) (i32.const 0))
;; i32 ge_u.right.if
(assert_return (invoke "check.i32" (i32.const 110)) (i32.const 0))
;; i32 ge_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 111)) (i32.const 0))
;; i32 ge_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 112)) (i32.const 0))
;; i32 cond.br_if
(assert_return (invoke "check.i32" (i32.const 113)) (i32.const 0))
;; i32 cond.if
(assert_return (invoke "check.i32" (i32.const 114)) (i32.const 0))
;; i32 cond.br_if_pad
(assert_return (invoke "check.i32" (i32.const 115)) (i32.const 0))
;; i32 cond.br_if_copy
(assert_return (invoke "check.i32" (i32.const 116)) (i32.const 0))
;; i32 and.br_if
(assert_return (invoke "check.i32" (i32.const 117)) (i32.const 0))
;; i32 and.eqz.if
(assert_return (invoke "check.i32" (i32.const 118)) (i32.const 0))
;; i32 super.after
(assert_return (invoke "check.i32" (i32.const 119)) (i32.const 0))

(module
  (memory 1)
  (data (i32.const 0) "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ffA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7fA\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\01\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\ff\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\ff\ff\ff\ff\ff\ff\ff\7f\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\00\00\00\00\00\00\00\80\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12?\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12A\00\00\00\00\00\00\00\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12\f0\de\bc\9axV4\12")
  (func $add.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $add.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.add (local.get $t) (local.get $c)))
  (func $add.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $add.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.add (local.get $c) (local.get $t)))
  (func $add.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $add.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.add (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $sub.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $sub.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.sub (local.get $t) (local.get $c)))
  (func $sub.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.sub (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $sub.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.sub (local.get $c) (local.get $t)))
  (func $sub.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.sub (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $sub.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.sub (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $mul.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.mul (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $mul.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.mul (local.get $t) (local.get $c)))
  (func $mul.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.mul (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $mul.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.mul (local.get $c) (local.get $t)))
  (func $mul.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.mul (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $mul.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.mul (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $and.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $and.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.and (local.get $t) (local.get $c)))
  (func $and.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $and.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.and (local.get $c) (local.get $t)))
  (func $and.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.and (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $and.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.and (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $or.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.or (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $or.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.or (local.get $t) (local.get $c)))
  (func $or.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.or (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $or.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.or (local.get $c) (local.get $t)))
  (func $or.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.or (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $or.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.or (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $xor.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $xor.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.xor (local.get $t) (local.get $c)))
  (func $xor.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $xor.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.xor (local.get $c) (local.get $t)))
  (func $xor.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.xor (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $xor.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.xor (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $shl.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shl (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $shl.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shl (local.get $t) (local.get $c)))
  (func $shl.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shl (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $shl.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shl (local.get $c) (local.get $t)))
  (func $shl.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shl (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $shl.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shl (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $shr_s.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_s.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shr_s (local.get $t) (local.get $c)))
  (func $shr_s.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $shr_s.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shr_s (local.get $c) (local.get $t)))
  (func $shr_s.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_s (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $shr_s.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shr_s (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $shr_u.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $shr_u.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shr_u (local.get $t) (local.get $c)))
  (func $shr_u.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $shr_u.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shr_u (local.get $c) (local.get $t)))
  (func $shr_u.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.shr_u (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $shr_u.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.shr_u (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $rotl.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotl (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $rotl.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.rotl (local.get $t) (local.get $c)))
  (func $rotl.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotl (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $rotl.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.rotl (local.get $c) (local.get $t)))
  (func $rotl.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotl (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $rotl.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.rotl (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $rotr.left (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotr (i64.rotr (local.get $a) (local.get $b)) (local.get $c)))
  (func $rotr.left.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.rotr (local.get $t) (local.get $c)))
  (func $rotr.right (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotr (local.get $c) (i64.rotr (local.get $a) (local.get $b))))
  (func $rotr.right.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.rotr (local.get $c) (local.get $t)))
  (func $rotr.chain (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.rotr (i64.sub (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $a)))
  (func $rotr.chain.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.rotr (i64.sub (local.get $t) (local.get $c)) (local.get $a)))
  (func $eq.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.eq (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $eq.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.eq (local.get $t) (local.get $c)))
  (func $eq.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.eq (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $eq.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.eq (local.get $t) (local.get $c)))
  (func $eq.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.eq (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $eq.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.eq (local.get $t) (local.get $c)))
  (func $eq.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.eq (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $eq.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.eq (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $eq.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.eq (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $eq.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.eq (local.get $c) (local.get $t)))
  (func $eq.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.eq (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $eq.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.eq (local.get $c) (local.get $t)))
  (func $eq.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.eq (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $eq.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.eq (local.get $c) (local.get $t)))
  (func $eq.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.eq (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $eq.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.eq (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ne.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.ne (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $ne.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $t) (local.get $c)))
  (func $ne.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.ne (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $ne.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $t) (local.get $c)))
  (func $ne.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.ne (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $ne.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $t) (local.get $c)))
  (func $ne.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.ne (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $ne.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.ne (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ne.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.ne (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $ne.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $c) (local.get $t)))
  (func $ne.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.ne (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $ne.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $c) (local.get $t)))
  (func $ne.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.ne (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $ne.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $c) (local.get $t)))
  (func $ne.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.ne (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $ne.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.ne (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_s.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.lt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $lt_s.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_s (local.get $t) (local.get $c)))
  (func $lt_s.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.lt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_s.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_s (local.get $t) (local.get $c)))
  (func $lt_s.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.lt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $lt_s.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_s (local.get $t) (local.get $c)))
  (func $lt_s.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.lt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $lt_s.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.lt_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_s.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.lt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $lt_s.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_s (local.get $c) (local.get $t)))
  (func $lt_s.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.lt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_s.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_s (local.get $c) (local.get $t)))
  (func $lt_s.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.lt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $lt_s.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_s (local.get $c) (local.get $t)))
  (func $lt_s.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.lt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $lt_s.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.lt_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_u.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.lt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $lt_u.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_u (local.get $t) (local.get $c)))
  (func $lt_u.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.lt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_u.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_u (local.get $t) (local.get $c)))
  (func $lt_u.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.lt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $lt_u.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_u (local.get $t) (local.get $c)))
  (func $lt_u.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.lt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $lt_u.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.lt_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $lt_u.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.lt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $lt_u.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_u (local.get $c) (local.get $t)))
  (func $lt_u.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.lt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $lt_u.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_u (local.get $c) (local.get $t)))
  (func $lt_u.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.lt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $lt_u.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.lt_u (local.get $c) (local.get $t)))
  (func $lt_u.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.lt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $lt_u.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.lt_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_s.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.gt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $gt_s.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_s (local.get $t) (local.get $c)))
  (func $gt_s.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.gt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_s.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_s (local.get $t) (local.get $c)))
  (func $gt_s.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.gt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $gt_s.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_s (local.get $t) (local.get $c)))
  (func $gt_s.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.gt_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $gt_s.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.gt_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_s.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.gt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $gt_s.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_s (local.get $c) (local.get $t)))
  (func $gt_s.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.gt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_s.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_s (local.get $c) (local.get $t)))
  (func $gt_s.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.gt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $gt_s.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_s (local.get $c) (local.get $t)))
  (func $gt_s.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.gt_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $gt_s.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.gt_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_u.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.gt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $gt_u.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_u (local.get $t) (local.get $c)))
  (func $gt_u.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.gt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_u.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_u (local.get $t) (local.get $c)))
  (func $gt_u.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.gt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $gt_u.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_u (local.get $t) (local.get $c)))
  (func $gt_u.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.gt_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $gt_u.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.gt_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $gt_u.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.gt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $gt_u.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_u (local.get $c) (local.get $t)))
  (func $gt_u.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.gt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $gt_u.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_u (local.get $c) (local.get $t)))
  (func $gt_u.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.gt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $gt_u.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.gt_u (local.get $c) (local.get $t)))
  (func $gt_u.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.gt_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $gt_u.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.gt_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_s.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.le_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $le_s.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_s (local.get $t) (local.get $c)))
  (func $le_s.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.le_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_s.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_s (local.get $t) (local.get $c)))
  (func $le_s.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.le_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $le_s.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_s (local.get $t) (local.get $c)))
  (func $le_s.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.le_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $le_s.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.le_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_s.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.le_s (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $le_s.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_s (local.get $c) (local.get $t)))
  (func $le_s.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.le_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_s.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_s (local.get $c) (local.get $t)))
  (func $le_s.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.le_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $le_s.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_s (local.get $c) (local.get $t)))
  (func $le_s.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.le_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $le_s.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.le_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_u.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.le_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $le_u.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_u (local.get $t) (local.get $c)))
  (func $le_u.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.le_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_u.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_u (local.get $t) (local.get $c)))
  (func $le_u.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.le_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $le_u.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_u (local.get $t) (local.get $c)))
  (func $le_u.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.le_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $le_u.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.le_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $le_u.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.le_u (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $le_u.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_u (local.get $c) (local.get $t)))
  (func $le_u.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.le_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $le_u.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_u (local.get $c) (local.get $t)))
  (func $le_u.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.le_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $le_u.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.le_u (local.get $c) (local.get $t)))
  (func $le_u.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.le_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $le_u.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.le_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_s.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.ge_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $ge_s.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_s (local.get $t) (local.get $c)))
  (func $ge_s.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.ge_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_s.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_s (local.get $t) (local.get $c)))
  (func $ge_s.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.ge_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $ge_s.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_s (local.get $t) (local.get $c)))
  (func $ge_s.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.ge_s (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $ge_s.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.ge_s (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_s.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.ge_s (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $ge_s.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_s (local.get $c) (local.get $t)))
  (func $ge_s.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.ge_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_s.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_s (local.get $c) (local.get $t)))
  (func $ge_s.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.ge_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $ge_s.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_s (local.get $c) (local.get $t)))
  (func $ge_s.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.ge_s (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $ge_s.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.ge_s (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_u.left.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.ge_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (return (i32.const 0))) (i32.const 1))
  (func $ge_u.left.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_u (local.get $t) (local.get $c)))
  (func $ge_u.left.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.ge_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_u.left.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_u (local.get $t) (local.get $c)))
  (func $ge_u.left.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.ge_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (drop) (i32.const 0)))
  (func $ge_u.left.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_u (local.get $t) (local.get $c)))
  (func $ge_u.left.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.ge_u (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (br_if 0) (i32.sub)))
  (func $ge_u.left.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.ge_u (local.get $t) (local.get $c)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $ge_u.right.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.ge_u (local.get $c) (i64.rotr (local.get $a) (local.get $b)))) (return (i32.const 0))) (i32.const 1))
  (func $ge_u.right.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_u (local.get $c) (local.get $t)))
  (func $ge_u.right.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.ge_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (then (i32.const 1)) (else (i32.const 0))))
  (func $ge_u.right.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_u (local.get $c) (local.get $t)))
  (func $ge_u.right.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.ge_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (drop) (i32.const 0)))
  (func $ge_u.right.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ge_u (local.get $c) (local.get $t)))
  (func $ge_u.right.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.ge_u (local.get $c) (i64.rotr (local.get $a) (local.get $b))) (br_if 0) (i32.sub)))
  (func $ge_u.right.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.ge_u (local.get $c) (local.get $t)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $cond.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i64.ne (i64.rotr (local.get $a) (local.get $b)) (i64.const 0))) (return (i32.const 0))) (i32.const 1))
  (func $cond.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $t) (i64.const 0)))
  (func $cond.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.ne (i64.rotr (local.get $a) (local.get $b)) (i64.const 0)) (then (i32.const 1)) (else (i32.const 0))))
  (func $cond.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $t) (i64.const 0)))
  (func $cond.br_if_pad (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2)) (i64.ne (i64.rotr (local.get $a) (local.get $b)) (i64.const 0)) (br_if 0) (i32.sub)))
  (func $cond.br_if_pad.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (if (result i32) (i64.ne (local.get $t) (i64.const 0)) (then (i32.const 5)) (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5)))))
  (func $cond.br_if_copy (param $a i64) (param $b i64) (param $c i64) (result i32) (block (result i32) (i32.const 1) (i64.ne (i64.rotr (local.get $a) (local.get $b)) (i64.const 0)) (br_if 0) (drop) (i32.const 0)))
  (func $cond.br_if_copy.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (local.get $t) (i64.const 0)))
  (func $and.br_if (param $a i64) (param $b i64) (param $c i64) (result i32) (block (br_if 0 (i32.eqz (i64.eqz (i64.and (i64.rotr (local.get $a) (local.get $b)) (local.get $c))))) (return (i32.const 0))) (i32.const 1))
  (func $and.br_if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (i64.and (local.get $t) (local.get $c)) (i64.const 0)))
  (func $and.eqz.if (param $a i64) (param $b i64) (param $c i64) (result i32) (if (result i32) (i64.eqz (i64.and (i64.rotr (local.get $a) (local.get $b)) (local.get $c))) (then (i32.const 0)) (else (i32.const 1))))
  (func $and.eqz.if.ref (param $a i64) (param $b i64) (param $c i64) (result i32) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.ne (i64.and (local.get $t) (local.get $c)) (i64.const 0)))
  (func $super.after (param $a i64) (param $b i64) (param $c i64) (result i64) (i64.add (i64.shl (i64.and (i64.rotr (local.get $a) (local.get $b)) (local.get $c)) (local.get $b)) (local.get $a)))
  (func $super.after.ref (param $a i64) (param $b i64) (param $c i64) (result i64) (local $t i64) (local.set $t (i64.rotr (local.get $a) (local.get $b))) (i64.add (i64.shl (i64.and (local.get $t) (local.get $c)) (local.get $b)) (local.get $a)))
  (type $fi64 (func (param $a i64) (param $b i64) (param $c i64) (result i64)))
  (type $fi32 (func (param $a i64) (param $b i64) (param $c i64) (result i32)))
  (table funcref (elem $add.left $add.left.ref $add.right $add.right.ref $add.chain $add.chain.ref $sub.left $sub.left.ref $sub.right $sub.right.ref $sub.chain $sub.chain.ref $mul.left $mul.left.ref $mul.right $mul.right.ref $mul.chain $mul.chain.ref $and.left $and.left.ref $and.right $and.right.ref $and.chain $and.chain.ref $or.left $or.left.ref $or.right $or.right.ref $or.chain $or.chain.ref $xor.left $xor.left.ref $xor.right $xor.right.ref $xor.chain $xor.chain.ref $shl.left $shl.left.ref $shl.right $shl.right.ref $shl.chain $shl.chain.ref $shr_s.left $shr_s.left.ref $shr_s.right $shr_s.right.ref $shr_s.chain $shr_s.chain.ref $shr_u.left $shr_u.left.ref $shr_u.right $shr_u.right.ref $shr_u.chain $shr_u.chain.ref $rotl.left $rotl.left.ref $rotl.right $rotl.right.ref $rotl.chain $rotl.chain.ref $rotr.left $rotr.left.ref $rotr.right $rotr.right.ref $rotr.chain $rotr.chain.ref $eq.left.br_if $eq.left.br_if.ref $eq.left.if $eq.left.if.ref $eq.left.br_if_copy $eq.left.br_if_copy.ref $eq.left.br_if_pad $eq.left.br_if_pad.ref $eq.right.br_if $eq.right.br_if.ref $eq.right.if $eq.right.if.ref $eq.right.br_if_copy $eq.right.br_if_copy.ref $eq.right.br_if_pad $eq.right.br_if_pad.ref $ne.left.br_if $ne.left.br_if.ref $ne.left.if $ne.left.if.ref $ne.left.br_if_copy $ne.left.br_if_copy.ref $ne.left.br_if_pad $ne.left.br_if_pad.ref $ne.right.br_if $ne.right.br_if.ref $ne.right.if $ne.right.if.ref $ne.right.br_if_copy $ne.right.br_if_copy.ref $ne.right.br_if_pad $ne.right.br_if_pad.ref $lt_s.left.br_if $lt_s.left.br_if.ref $lt_s.left.if $lt_s.left.if.ref $lt_s.left.br_if_copy $lt_s.left.br_if_copy.ref $lt_s.left.br_if_pad $lt_s.left.br_if_pad.ref $lt_s.right.br_if $lt_s.right.br_if.ref $lt_s.right.if $lt_s.right.if.ref $lt_s.right.br_if_copy $lt_s.right.br_if_copy.ref $lt_s.right.br_if_pad $lt_s.right.br_if_pad.ref $lt_u.left.br_if $lt_u.left.br_if.ref $lt_u.left.if $lt_u.left.if.ref $lt_u.left.br_if_copy $lt_u.left.br_if_copy.ref $lt_u.left.br_if_pad $lt_u.left.br_if_pad.ref $lt_u.right.br_if $lt_u.right.br_if.ref $lt_u.right.if $lt_u.right.if.ref $lt_u.right.br_if_copy $lt_u.right.br_if_copy.ref $lt_u.right.br_if_pad $lt_u.right.br_if_pad.ref $gt_s.left.br_if $gt_s.left.br_if.ref $gt_s.left.if $gt_s.left.if.ref $gt_s.left.br_if_copy $gt_s.left.br_if_copy.ref $gt_s.left.br_if_pad $gt_s.left.br_if_pad.ref $gt_s.right.br_if $gt_s.right.br_if.ref $gt_s.right.if $gt_s.right.if.ref $gt_s.right.br_if_copy $gt_s.right.br_if_copy.ref $gt_s.right.br_if_pad $gt_s.right.br_if_pad.ref $gt_u.left.br_if $gt_u.left.br_if.ref $gt_u.left.if $gt_u.left.if.ref $gt_u.left.br_if_copy $gt_u.left.br_if_copy.ref $gt_u.left.br_if_pad $gt_u.left.br_if_pad.ref $gt_u.right.br_if $gt_u.right.br_if.ref $gt_u.right.if $gt_u.right.if.ref $gt_u.right.br_if_copy $gt_u.right.br_if_copy.ref $gt_u.right.br_if_pad $gt_u.right.br_if_pad.ref $le_s.left.br_if $le_s.left.br_if.ref $le_s.left.if $le_s.left.if.ref $le_s.left.br_if_copy $le_s.left.br_if_copy.ref $le_s.left.br_if_pad $le_s.left.br_if_pad.ref $le_s.right.br_if $le_s.right.br_if.ref $le_s.right.if $le_s.right.if.ref $le_s.right.br_if_copy $le_s.right.br_if_copy.ref $le_s.right.br_if_pad $le_s.right.br_if_pad.ref $le_u.left.br_if $le_u.left.br_if.ref $le_u.left.if $le_u.left.if.ref $le_u.left.br_if_copy $le_u.left.br_if_copy.ref $le_u.left.br_if_pad $le_u.left.br_if_pad.ref $le_u.right.br_if $le_u.right.br_if.ref $le_u.right.if $le_u.right.if.ref $le_u.right.br_if_copy $le_u.right.br_if_copy.ref $le_u.right.br_if_pad $le_u.right.br_if_pad.ref $ge_s.left.br_if $ge_s.left.br_if.ref $ge_s.left.if $ge_s.left.if.ref $ge_s.left.br_if_copy $ge_s.left.br_if_copy.ref $ge_s.left.br_if_pad $ge_s.left.br_if_pad.ref $ge_s.right.br_if $ge_s.right.br_if.ref $ge_s.right.if $ge_s.right.if.ref $ge_s.right.br_if_copy $ge_s.right.br_if_copy.ref $ge_s.right.br_if_pad $ge_s.right.br_if_pad.ref $ge_u.left.br_if $ge_u.left.br_if.ref $ge_u.left.if $ge_u.left.if.ref $ge_u.left.br_if_copy $ge_u.left.br_if_copy.ref $ge_u.left.br_if_pad $ge_u.left.br_if_pad.ref $ge_u.right.br_if $ge_u.right.br_if.ref $ge_u.right.if $ge_u.right.if.ref $ge_u.right.br_if_copy $ge_u.right.br_if_copy.ref $ge_u.right.br_if_pad $ge_u.right.br_if_pad.ref $cond.br_if $cond.br_if.ref $cond.if $cond.if.ref $cond.br_if_pad $cond.br_if_pad.ref $cond.br_if_copy $cond.br_if_copy.ref $and.br_if $and.br_if.ref $and.eqz.if $and.eqz.if.ref $super.after $super.after.ref))
  (func (export "check.i64") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $o (i32.mul (local.get $i) (i32.const 24)))
      (if (i64.ne (call_indirect (type $fi64) (i64.load (i32.add (local.get $o) (i32.const 0))) (i64.load (i32.add (local.get $o) (i32.const 8))) (i64.load (i32.add (local.get $o) (i32.const 16))) (local.get $f))
                  (call_indirect (type $fi64) (i64.load (i32.add (local.get $o) (i32.const 0))) (i64.load (i32.add (local.get $o) (i32.const 8))) (i64.load (i32.add (local.get $o) (i32.const 16))) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 512))))
    (local.get $n))
  (func (export "check.i32") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)
    (local.set $f (i32.shl (local.get $k) (i32.const 1)))
    (loop $l
      (local.set $o (i32.mul (local.get $i) (i32.const 24)))
      (if (i32.ne (call_indirect (type $fi32) (i64.load (i32.add (local.get $o) (i32.const 0))) (i64.load (i32.add (local.get $o) (i32.const 8))) (i64.load (i32.add (local.get $o) (i32.const 16))) (local.get $f))
                  (call_indirect (type $fi32) (i64.load (i32.add (local.get $o) (i32.const 0))) (i64.load (i32.add (local.get $o) (i32.const 8))) (i64.load (i32.add (local.get $o) (i32.const 16))) (i32.add (local.get $f) (i32.const 1))))
        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))
      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 512))))
    (local.get $n))
)
;; i64 add.left
(assert_return (invoke "check.i64" (i32.const 0)) (i32.const 0))
;; i64 add.right
(assert_return (invoke "check.i64" (i32.const 1)) (i32.const 0))
;; i64 add.chain
(assert_return (invoke "check.i64" (i32.const 2)) (i32.const 0))
;; i64 sub.left
(assert_return (invoke "check.i64" (i32.const 3)) (i32.const 0))
;; i64 sub.right
(assert_return (invoke "check.i64" (i32.const 4)) (i32.const 0))
;; i64 sub.chain
(assert_return (invoke "check.i64" (i32.const 5)) (i32.const 0))
;; i64 mul.left
(assert_return (invoke "check.i64" (i32.const 6)) (i32.const 0))
;; i64 mul.right
(assert_return (invoke "check.i64" (i32.const 7)) (i32.const 0))
;; i64 mul.chain
(assert_return (invoke "check.i64" (i32.const 8)) (i32.const 0))
;; i64 and.left
(assert_return (invoke "check.i64" (i32.const 9)) (i32.const 0))
;; i64 and.right
(assert_return (invoke "check.i64" (i32.const 10)) (i32.const 0))
;; i64 and.chain
(assert_return (invoke "check.i64" (i32.const 11)) (i32.const 0))
;; i64 or.left
(assert_return (invoke "check.i64" (i32.const 12)) (i32.const 0))
;; i64 or.right
(assert_return (invoke "check.i64" (i32.const 13)) (i32.const 0))
;; i64 or.chain
(assert_return (invoke "check.i64" (i32.const 14)) (i32.const 0))
;; i64 xor.left
(assert_return (invoke "check.i64" (i32.const 15)) (i32.const 0))
;; i64 xor.right
(assert_return (invoke "check.i64" (i32.const 16)) (i32.const 0))
;; i64 xor.chain
(assert_return (invoke "check.i64" (i32.const 17)) (i32.const 0))
;; i64 shl.left
(assert_return (invoke "check.i64" (i32.const 18)) (i32.const 0))
;; i64 shl.right
(assert_return (invoke "check.i64" (i32.const 19)) (i32.const 0))
;; i64 shl.chain
(assert_return (invoke "check.i64" (i32.const 20)) (i32.const 0))
;; i64 shr_s.left
(assert_return (invoke "check.i64" (i32.const 21)) (i32.const 0))
;; i64 shr_s.right
(assert_return (invoke "check.i64" (i32.const 22)) (i32.const 0))
;; i64 shr_s.chain
(assert_return (invoke "check.i64" (i32.const 23)) (i32.const 0))
;; i64 shr_u.left
(assert_return (invoke "check.i64" (i32.const 24)) (i32.const 0))
;; i64 shr_u.right
(assert_return (invoke "check.i64" (i32.const 25)) (i32.const 0))
;; i64 shr_u.chain
(assert_return (invoke "check.i64" (i32.const 26)) (i32.const 0))
;; i64 rotl.left
(assert_return (invoke "check.i64" (i32.const 27)) (i32.const 0))
;; i64 rotl.right
(assert_return (invoke "check.i64" (i32.const 28)) (i32.const 0))
;; i64 rotl.chain
(assert_return (invoke "check.i64" (i32.const 29)) (i32.const 0))
;; i64 rotr.left
(assert_return (invoke "check.i64" (i32.const 30)) (i32.const 0))
;; i64 rotr.right
(assert_return (invoke "check.i64" (i32.const 31)) (i32.const 0))
;; i64 rotr.chain
(assert_return (invoke "check.i64" (i32.const 32)) (i32.const 0))
;; i64 eq.left.br_if
(assert_return (invoke "check.i32" (i32.const 33)) (i32.const 0))
;; i64 eq.left.if
(assert_return (invoke "check.i32" (i32.const 34)) (i32.const 0))
;; i64 eq.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 35)) (i32.const 0))
;; i64 eq.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 36)) (i32.const 0))
;; i64 eq.right.br_if
(assert_return (invoke "check.i32" (i32.const 37)) (i32.const 0))
;; i64 eq.right.if
(assert_return (invoke "check.i32" (i32.const 38)) (i32.const 0))
;; i64 eq.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 39)) (i32.const 0))
;; i64 eq.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 40)) (i32.const 0))
;; i64 ne.left.br_if
(assert_return (invoke "check.i32" (i32.const 41)) (i32.const 0))
;; i64 ne.left.if
(assert_return (invoke "check.i32" (i32.const 42)) (i32.const 0))
;; i64 ne.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 43)) (i32.const 0))
;; i64 ne.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 44)) (i32.const 0))
;; i64 ne.right.br_if
(assert_return (invoke "check.i32" (i32.const 45)) (i32.const 0))
;; i64 ne.right.if
(assert_return (invoke "check.i32" (i32.const 46)) (i32.const 0))
;; i64 ne.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 47)) (i32.const 0))
;; i64 ne.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 48)) (i32.const 0))
;; i64 lt_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 49)) (i32.const 0))
;; i64 lt_s.left.if
(assert_return (invoke "check.i32" (i32.const 50)) (i32.const 0))
;; i64 lt_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 51)) (i32.const 0))
;; i64 lt_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 52)) (i32.const 0))
;; i64 lt_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 53)) (i32.const 0))
;; i64 lt_s.right.if
(assert_return (invoke "check.i32" (i32.const 54)) (i32.const 0))
;; i64 lt_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 55)) (i32.const 0))
;; i64 lt_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 56)) (i32.const 0))
;; i64 lt_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 57)) (i32.const 0))
;; i64 lt_u.left.if
(assert_return (invoke "check.i32" (i32.const 58)) (i32.const 0))
;; i64 lt_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 59)) (i32.const 0))
;; i64 lt_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 60)) (i32.const 0))
;; i64 lt_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 61)) (i32.const 0))
;; i64 lt_u.right.if
(assert_return (invoke "check.i32" (i32.const 62)) (i32.const 0))
;; i64 lt_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 63)) (i32.const 0))
;; i64 lt_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 64)) (i32.const 0))
;; i64 gt_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 65)) (i32.const 0))
;; i64 gt_s.left.if
(assert_return (invoke "check.i32" (i32.const 66)) (i32.const 0))
;; i64 gt_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 67)) (i32.const 0))
;; i64 gt_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 68)) (i32.const 0))
;; i64 gt_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 69)) (i32.const 0))
;; i64 gt_s.right.if
(assert_return (invoke "check.i32" (i32.const 70)) (i32.const 0))
;; i64 gt_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 71)) (i32.const 0))
;; i64 gt_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 72)) (i32.const 0))
;; i64 gt_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 73)) (i32.const 0))
;; i64 gt_u.left.if
(assert_return (invoke "check.i32" (i32.const 74)) (i32.const 0))
;; i64 gt_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 75)) (i32.const 0))
;; i64 gt_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 76)) (i32.const 0))
;; i64 gt_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 77)) (i32.const 0))
;; i64 gt_u.right.if
(assert_return (invoke "check.i32" (i32.const 78)) (i32.const 0))
;; i64 gt_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 79)) (i32.const 0))
;; i64 gt_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 80)) (i32.const 0))
;; i64 le_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 81)) (i32.const 0))
;; i64 le_s.left.if
(assert_return (invoke "check.i32" (i32.const 82)) (i32.const 0))
;; i64 le_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 83)) (i32.const 0))
;; i64 le_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 84)) (i32.const 0))
;; i64 le_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 85)) (i32.const 0))
;; i64 le_s.right.if
(assert_return (invoke "check.i32" (i32.const 86)) (i32.const 0))
;; i64 le_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 87)) (i32.const 0))
;; i64 le_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 88)) (i32.const 0))
;; i64 le_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 89)) (i32.const 0))
;; i64 le_u.left.if
(assert_return (invoke "check.i32" (i32.const 90)) (i32.const 0))
;; i64 le_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 91)) (i32.const 0))
;; i64 le_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 92)) (i32.const 0))
;; i64 le_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 93)) (i32.const 0))
;; i64 le_u.right.if
(assert_return (invoke "check.i32" (i32.const 94)) (i32.const 0))
;; i64 le_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 95)) (i32.const 0))
;; i64 le_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 96)) (i32.const 0))
;; i64 ge_s.left.br_if
(assert_return (invoke "check.i32" (i32.const 97)) (i32.const 0))
;; i64 ge_s.left.if
(assert_return (invoke "check.i32" (i32.const 98)) (i32.const 0))
;; i64 ge_s.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 99)) (i32.const 0))
;; i64 ge_s.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 100)) (i32.const 0))
;; i64 ge_s.right.br_if
(assert_return (invoke "check.i32" (i32.const 101)) (i32.const 0))
;; i64 ge_s.right.if
(assert_return (invoke "check.i32" (i32.const 102)) (i32.const 0))
;; i64 ge_s.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 103)) (i32.const 0))
;; i64 ge_s.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 104)) (i32.const 0))
;; i64 ge_u.left.br_if
(assert_return (invoke "check.i32" (i32.const 105)) (i32.const 0))
;; i64 ge_u.left.if
(assert_return (invoke "check.i32" (i32.const 106)) (i32.const 0))
;; i64 ge_u.left.br_if_copy
(assert_return (invoke "check.i32" (i32.const 107)) (i32.const 0))
;; i64 ge_u.left.br_if_pad
(assert_return (invoke "check.i32" (i32.const 108)) (i32.const 0))
;; i64 ge_u.right.br_if
(assert_return (invoke "check.i32" (i32.const 109)) (i32.const 0))
;; i64 ge_u.right.if
(assert_return (invoke "check.i32" (i32.const 110)) (i32.const 0))
;; i64 ge_u.right.br_if_copy
(assert_return (invoke "check.i32" (i32.const 111)) (i32.const 0))
;; i64 ge_u.right.br_if_pad
(assert_return (invoke "check.i32" (i32.const 112)) (i32.const 0))
;; i64 cond.br_if
(assert_return (invoke "check.i32" (i32.const 113)) (i32.const 0))
;; i64 cond.if
(assert_return (invoke "check.i32" (i32.const 114)) (i32.const 0))
;; i64 cond.br_if_pad
(assert_return (invoke "check.i32" (i32.const 115)) (i32.const 0))
;; i64 cond.br_if_copy
(assert_return (invoke "check.i32" (i32.const 116)) (i32.const 0))
;; i64 and.br_if
(assert_return (invoke "check.i32" (i32.const 117)) (i32.const 0))
;; i64 and.eqz.if
(assert_return (invoke "check.i32" (i32.const 118)) (i32.const 0))
;; i64 super.after
(assert_return (invoke "check.i64" (i32.const 119)) (i32.const 0))

;; Edges around a hand-off: a label, a call, a trapping instruction, a
;; relinked local.set and a pushed local between producer and consumer.
(module
  (global $g (mut i32) (i32.const 0))
  (global $h (mut i64) (i64.const 0))
  (func $id (param i32) (result i32) (local.get 0))
  (func (export "label") (param $a i32) (param $b i32) (result i32)
    (i32.sub (block (result i32) (i32.rotr (local.get $a) (local.get $b))) (local.get $b)))
  (func (export "call") (param $a i32) (param $b i32) (result i32)
    (i32.sub (i32.rotr (local.get $a) (local.get $b)) (call $id (local.get $b))))
  (func (export "div") (param $a i32) (param $b i32) (result i32)
    (i32.sub (i32.rotr (local.get $a) (local.get $b)) (i32.div_s (local.get $a) (local.get $b))))
  (func (export "live") (param $a i32) (param $b i32) (result i32) (local $t i32)
    (i32.sub (local.tee $t (i32.rotr (local.get $a) (local.get $b))) (local.get $t)))
  (func (export "set-local") (param $a i32) (param $b i32) (result i32) (local $x i32)
    (i32.rotr (local.get $a) (local.get $b)) (local.get $b) (local.set $x) (drop) (local.get $x))
  (func (export "pushed-local") (param $a i32) (param $b i32) (result i32)
    (i32.rotr (local.get $a) (local.get $b)) (local.get $b) (i32.sub))
;; A counter loop through a global, and globals as compare operands and conditions.
  (func (export "counter") (param $n i32) (result i32)
    (global.set $g (local.get $n))
    (loop $l (br_if $l (global.set $g (i32.sub (global.get $g) (i32.const 1))) (global.get $g)))
    (global.get $g))
  (func (export "global-cmp") (param $a i32) (result i32)
    (global.set $g (local.get $a))
    (block (br_if 0 (i32.lt_u (global.get $g) (i32.const 10))) (return (i32.const 0))) (i32.const 1))
  (func (export "global-cond") (param $a i32) (result i32)
    (global.set $g (local.get $a))
    (if (result i32) (global.get $g) (then (i32.const 1)) (else (i32.const 0))))
  (func (export "global64") (param $a i64) (result i64)
    (global.set $h (local.get $a))
    (i64.add (global.get $h) (i64.const 0x100000000)))
)
(assert_return (invoke "label" (i32.const 8) (i32.const 1)) (i32.const 3))
(assert_return (invoke "call" (i32.const 8) (i32.const 1)) (i32.const 3))
(assert_return (invoke "div" (i32.const 8) (i32.const 1)) (i32.const -4))
(assert_trap (invoke "div" (i32.const 8) (i32.const 0)) "integer divide by zero")
(assert_return (invoke "live" (i32.const 8) (i32.const 1)) (i32.const 0))
(assert_return (invoke "set-local" (i32.const 8) (i32.const 1)) (i32.const 1))
(assert_return (invoke "pushed-local" (i32.const 8) (i32.const 1)) (i32.const 3))
(assert_return (invoke "counter" (i32.const 100)) (i32.const 0))
(assert_return (invoke "global-cmp" (i32.const 3)) (i32.const 1))
(assert_return (invoke "global-cmp" (i32.const 30)) (i32.const 0))
(assert_return (invoke "global-cond" (i32.const 0)) (i32.const 0))
(assert_return (invoke "global-cond" (i32.const 256)) (i32.const 1))
(assert_return (invoke "global64" (i64.const -1)) (i64.const 0xffffffff))
