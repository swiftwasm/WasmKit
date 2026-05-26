
## Comparing results between 'main' and 'eh-branch'

```
Host 'MacBookAir.lan' with 8 'arm64' processors with 16 GB memory
```
## MacroPlugin

### Expand FoundationMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2929 |      2947 |      2955 |      2970 |      2994 |      3070 |      3250 |       334 |
|                eh-branch                 |      2890 |      2949 |      2957 |      2970 |      2990 |      3092 |      3230 |       335 |
|                    Δ                     |       -39 |         2 |         2 |         0 |        -4 |        22 |       -20 |         1 |
|              Improvement %               |         1 |         0 |         0 |         0 |         0 |        -1 |         1 |         1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2931 |      2949 |      2959 |      2972 |      2992 |      3060 |      3235 |       334 |
|                eh-branch                 |      2892 |      2951 |      2961 |      2974 |      2992 |      3097 |      3235 |       335 |
|                    Δ                     |       -39 |         2 |         2 |         2 |         0 |        37 |         0 |         1 |
|              Improvement %               |         1 |         0 |         0 |         0 |         0 |        -1 |         0 |         1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       341 |       339 |       338 |       337 |       334 |       326 |       308 |       334 |
|                eh-branch                 |       346 |       339 |       338 |       337 |       335 |       323 |       310 |       335 |
|                    Δ                     |         5 |         0 |         0 |         0 |         1 |        -3 |         2 |         1 |
|              Improvement %               |         1 |         0 |         0 |         0 |         0 |        -1 |         1 |         1 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        50 |        50 |        50 |        50 |        50 |        50 |        50 |       334 |
|                eh-branch                 |        50 |        50 |        50 |        50 |        50 |        50 |        50 |       335 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|             Malloc (total) *             |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        24 |        24 |        24 |        24 |        24 |        24 |       151 |       334 |
|                eh-branch                 |        24 |        24 |        24 |        24 |        24 |        24 |       151 |       335 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        20 |        20 |        20 |        20 |        20 |        20 |        20 |       334 |
|                eh-branch                 |        20 |        20 |        20 |        20 |        20 |        20 |        20 |       335 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

### Expand MMIOMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        12 |        12 |        12 |        12 |        12 |        85 |
|                eh-branch                 |        11 |        12 |        12 |        12 |        12 |        12 |        12 |        85 |
|                    Δ                     |        -1 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         8 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        12 |        12 |        12 |        12 |        12 |        85 |
|                eh-branch                 |        11 |        12 |        12 |        12 |        12 |        12 |        12 |        85 |
|                    Δ                     |        -1 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         8 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        86 |        85 |        85 |        85 |        84 |        83 |        83 |        85 |
|                eh-branch                 |        87 |        86 |        85 |        85 |        84 |        83 |        83 |        85 |
|                    Δ                     |         1 |         1 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         1 |         1 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       169 |       169 |       169 |       169 |       169 |       169 |       169 |        85 |
|                eh-branch                 |       169 |       170 |       170 |       170 |       170 |       170 |       170 |        85 |
|                    Δ                     |         0 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |         0 |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|             Malloc (total) *             |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        56 |        56 |        56 |        56 |        56 |       658 |       658 |        85 |
|                eh-branch                 |        56 |        56 |        56 |        56 |        56 |       658 |       658 |        85 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        84 |        84 |        84 |        84 |        84 |        86 |        86 |        85 |
|                eh-branch                 |        84 |        84 |        84 |        84 |        84 |        85 |        85 |        85 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |        -1 |        -1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         1 |         1 |         0 |

<p>
</details>

### Expand StringifyMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2355 |      2374 |      2382 |      2396 |      2427 |      2480 |      2660 |       413 |
|                eh-branch                 |      2322 |      2357 |      2378 |      2390 |      2404 |      2488 |      2591 |       416 |
|                    Δ                     |       -33 |       -17 |        -4 |        -6 |       -23 |         8 |       -69 |         3 |
|              Improvement %               |         1 |         1 |         0 |         0 |         1 |         0 |         3 |         3 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2357 |      2376 |      2384 |      2398 |      2431 |      2478 |      2662 |       413 |
|                eh-branch                 |      2324 |      2359 |      2380 |      2392 |      2406 |      2490 |      2574 |       416 |
|                    Δ                     |       -33 |       -17 |        -4 |        -6 |       -25 |        12 |       -88 |         3 |
|              Improvement %               |         1 |         1 |         0 |         0 |         1 |         0 |         3 |         3 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       425 |       422 |       420 |       418 |       412 |       403 |       376 |       413 |
|                eh-branch                 |       431 |       424 |       421 |       419 |       416 |       402 |       386 |       416 |
|                    Δ                     |         6 |         2 |         1 |         1 |         4 |        -1 |        10 |         3 |
|              Improvement %               |         1 |         0 |         0 |         0 |         1 |         0 |         3 |         3 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        43 |        43 |        43 |        43 |        43 |        43 |        43 |       413 |
|                eh-branch                 |        44 |        44 |        44 |        44 |        44 |        44 |        44 |       416 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         3 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |         3 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|             Malloc (total) *             |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        30 |        30 |        30 |        30 |        30 |        30 |       157 |       413 |
|                eh-branch                 |        30 |        30 |        30 |        30 |        30 |        30 |       157 |       416 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        15 |        15 |        15 |        15 |        15 |        15 |        15 |       413 |
|                eh-branch                 |        15 |        15 |        15 |        15 |        15 |        15 |        15 |       416 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |

<p>
</details>

### Expand TestingMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      5926 |      5951 |      5968 |      6001 |      6042 |      6291 |      6311 |       166 |
|                eh-branch                 |      5855 |      5980 |      5997 |      6017 |      6054 |      6283 |      6306 |       166 |
|                    Δ                     |       -71 |        29 |        29 |        16 |        12 |        -8 |        -5 |         0 |
|              Improvement %               |         1 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      5928 |      5956 |      5968 |      6005 |      6038 |      6296 |      6312 |       166 |
|                eh-branch                 |      5861 |      5984 |      6001 |      6021 |      6062 |      6287 |      6311 |       166 |
|                    Δ                     |       -67 |        28 |        33 |        16 |        24 |        -9 |        -1 |         0 |
|              Improvement %               |         1 |         0 |        -1 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       169 |       168 |       168 |       167 |       166 |       159 |       158 |       166 |
|                eh-branch                 |       171 |       167 |       167 |       166 |       165 |       159 |       159 |       166 |
|                    Δ                     |         2 |        -1 |        -1 |        -1 |        -1 |         0 |         1 |         0 |
|              Improvement %               |         1 |        -1 |        -1 |        -1 |        -1 |         0 |         1 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       102 |       102 |       102 |       102 |       102 |       102 |       102 |       166 |
|                eh-branch                 |       102 |       102 |       102 |       102 |       102 |       102 |       102 |       166 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|             Malloc (total) *             |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       202 |       202 |       202 |       202 |       202 |       202 |       202 |       166 |
|                eh-branch                 |       202 |       202 |       202 |       202 |       202 |       202 |       202 |       166 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        36 |        36 |        36 |        36 |        36 |        36 |        36 |       166 |
|                eh-branch                 |        36 |        36 |        36 |        36 |        36 |        36 |        36 |       166 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### Startup FoundationMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        88 |        89 |        89 |        89 |        89 |        89 |        89 |        12 |
|                eh-branch                 |        87 |        87 |        88 |        88 |        89 |        89 |        89 |        12 |
|                    Δ                     |        -1 |        -2 |        -1 |        -1 |         0 |         0 |         0 |         0 |
|              Improvement %               |         1 |         2 |         1 |         1 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        88 |        89 |        89 |        89 |        89 |        89 |        89 |        12 |
|                eh-branch                 |        87 |        87 |        88 |        88 |        89 |        89 |        89 |        12 |
|                    Δ                     |        -1 |        -2 |        -1 |        -1 |         0 |         0 |         0 |         0 |
|              Improvement %               |         1 |         2 |         1 |         1 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        12 |
|                eh-branch                 |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        70 |        72 |        73 |        73 |        73 |        73 |        73 |        12 |
|                eh-branch                 |        70 |        73 |        80 |        80 |        80 |        80 |        80 |        12 |
|                    Δ                     |         0 |         1 |         7 |         7 |         7 |         7 |         7 |         0 |
|              Improvement %               |         0 |        -1 |       -10 |       -10 |       -10 |       -10 |       -10 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       531 |       531 |       531 |       531 |       531 |       531 |       531 |        12 |
|                eh-branch                 |       531 |       531 |       531 |       531 |       531 |       531 |       531 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1243 |      1249 |      1251 |      1255 |      1258 |      1258 |      1258 |        12 |
|                eh-branch                 |      1233 |      1235 |      1236 |      1237 |      1246 |      1251 |      1251 |        12 |
|                    Δ                     |       -10 |       -14 |       -15 |       -18 |       -12 |        -7 |        -7 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

### Startup MMIOMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       184 |       185 |       185 |       186 |       187 |       187 |       187 |         6 |
|                eh-branch                 |       185 |       185 |       186 |       187 |       188 |       188 |       188 |         6 |
|                    Δ                     |         1 |         0 |         1 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |        -1 |         0 |        -1 |        -1 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       184 |       185 |       185 |       186 |       187 |       187 |       187 |         6 |
|                eh-branch                 |       185 |       185 |       186 |       187 |       188 |       188 |       188 |         6 |
|                    Δ                     |         1 |         0 |         1 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |        -1 |         0 |        -1 |        -1 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         6 |
|                eh-branch                 |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         6 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       234 |       235 |       235 |       236 |       236 |       236 |       236 |         6 |
|                eh-branch                 |       234 |       234 |       239 |       239 |       239 |       239 |       239 |         6 |
|                    Δ                     |         0 |        -1 |         4 |         3 |         3 |         3 |         3 |         0 |
|              Improvement %               |         0 |         0 |        -2 |        -1 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       628 |       628 |       628 |       628 |       628 |       628 |       628 |         6 |
|                eh-branch                 |       628 |       628 |       628 |       628 |       628 |       628 |       628 |         6 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2249 |      2252 |      2252 |      2261 |      2266 |      2266 |      2266 |         6 |
|                eh-branch                 |      2263 |      2265 |      2267 |      2273 |      2274 |      2274 |      2274 |         6 |
|                    Δ                     |        14 |        13 |        15 |        12 |         8 |         8 |         8 |         0 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |         0 |         0 |         0 |         0 |

<p>
</details>

### Startup StringifyMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        88 |        89 |        90 |        90 |        91 |        92 |        92 |        12 |
|                eh-branch                 |        89 |        89 |        90 |        90 |        90 |        90 |        90 |        12 |
|                    Δ                     |         1 |         0 |         0 |         0 |        -1 |        -2 |        -2 |         0 |
|              Improvement %               |        -1 |         0 |         0 |         0 |         1 |         2 |         2 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        88 |        89 |        90 |        90 |        91 |        92 |        92 |        12 |
|                eh-branch                 |        89 |        89 |        90 |        90 |        90 |        90 |        90 |        12 |
|                    Δ                     |         1 |         0 |         0 |         0 |        -1 |        -2 |        -2 |         0 |
|              Improvement %               |        -1 |         0 |         0 |         0 |         1 |         2 |         2 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        12 |
|                eh-branch                 |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        74 |        74 |        76 |        77 |        78 |        78 |        78 |        12 |
|                eh-branch                 |        74 |        75 |        77 |        82 |        82 |        82 |        82 |        12 |
|                    Δ                     |         0 |         1 |         1 |         5 |         4 |         4 |         4 |         0 |
|              Improvement %               |         0 |        -1 |        -1 |        -6 |        -5 |        -5 |        -5 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       532 |       532 |       532 |       532 |       532 |       532 |       532 |        12 |
|                eh-branch                 |       532 |       532 |       532 |       532 |       532 |       532 |       532 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1245 |      1249 |      1254 |      1256 |      1260 |      1261 |      1261 |        12 |
|                eh-branch                 |      1255 |      1258 |      1260 |      1264 |      1270 |      1270 |      1270 |        12 |
|                    Δ                     |        10 |         9 |         6 |         8 |        10 |         9 |         9 |         0 |
|              Improvement %               |        -1 |        -1 |         0 |        -1 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

### Startup TestingMacros.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       119 |       119 |       119 |       119 |       120 |       120 |       120 |         9 |
|                eh-branch                 |       118 |       118 |       118 |       119 |       119 |       119 |       119 |         9 |
|                    Δ                     |        -1 |        -1 |        -1 |         0 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         1 |         1 |         1 |         0 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       119 |       119 |       119 |       120 |       120 |       120 |       120 |         9 |
|                eh-branch                 |       118 |       118 |       118 |       119 |       119 |       119 |       119 |         9 |
|                    Δ                     |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         8 |         8 |         8 |         8 |         8 |         8 |         8 |         9 |
|                eh-branch                 |         9 |         8 |         8 |         8 |         8 |         8 |         8 |         9 |
|                    Δ                     |         1 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |        12 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       126 |       126 |       133 |       133 |       133 |       133 |       133 |         9 |
|                eh-branch                 |       127 |       129 |       138 |       138 |       138 |       138 |       138 |         9 |
|                    Δ                     |         1 |         3 |         5 |         5 |         5 |         5 |         5 |         0 |
|              Improvement %               |        -1 |        -2 |        -4 |        -4 |        -4 |        -4 |        -4 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       462 |       462 |       462 |       462 |       462 |       462 |       462 |         9 |
|                eh-branch                 |       462 |       462 |       462 |       462 |       462 |       462 |       462 |         9 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1529 |      1533 |      1537 |      1539 |      1543 |      1543 |      1543 |         9 |
|                eh-branch                 |      1525 |      1527 |      1533 |      1536 |      1539 |      1539 |      1539 |         9 |
|                    Δ                     |        -4 |        -6 |        -4 |        -3 |        -4 |        -4 |        -4 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

## MicroBench

### empty instantiation metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        26 |        27 |        27 |        27 |        27 |        31 |        54 |     10000 |
|                eh-branch                 |        27 |        27 |        27 |        28 |        28 |        31 |        91 |     10000 |
|                    Δ                     |         1 |         0 |         0 |         1 |         1 |         0 |        37 |         0 |
|              Improvement %               |        -4 |         0 |         0 |        -4 |        -4 |         0 |       -69 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        28 |        29 |        29 |        29 |        29 |        33 |        54 |     10000 |
|                eh-branch                 |        28 |        29 |        29 |        29 |        30 |        34 |        66 |     10000 |
|                    Δ                     |         0 |         0 |         0 |         0 |         1 |         1 |        12 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -3 |        -3 |       -22 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (K)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        38 |        37 |        37 |        37 |        37 |        32 |        19 |     10000 |
|                eh-branch                 |        38 |        37 |        37 |        36 |        36 |        32 |        11 |     10000 |
|                    Δ                     |         0 |         0 |         0 |        -1 |        -1 |         0 |        -8 |         0 |
|              Improvement %               |         0 |         0 |         0 |        -3 |        -3 |         0 |       -42 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (K)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      9093 |      9421 |      9421 |      9421 |      9421 |      9421 |      9421 |     10000 |
|                eh-branch                 |      9060 |      9396 |      9429 |      9437 |      9437 |      9437 |      9437 |     10000 |
|                    Δ                     |       -33 |       -25 |         8 |        16 |        16 |        16 |        16 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|             Malloc (total) *             |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        98 |        98 |        98 |        98 |        98 |        98 |        98 |     10000 |
|                eh-branch                 |       101 |       101 |       101 |       101 |       101 |       101 |       101 |     10000 |
|                    Δ                     |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         0 |
|              Improvement %               |        -3 |        -3 |        -3 |        -3 |        -3 |        -3 |        -3 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (K) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       309 |       310 |       311 |       311 |       311 |       319 |       335 |     10000 |
|                eh-branch                 |       315 |       316 |       316 |       316 |       316 |       324 |       336 |     10000 |
|                    Δ                     |         6 |         6 |         5 |         5 |         5 |         5 |         1 |         0 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |         0 |         0 |

<p>
</details>

## WasmParserBenchmark

### parseWasmBenchmark metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1003 |      1003 |      1003 |      1003 |      1003 |      1003 |      1003 |         1 |
|                eh-branch                 |       907 |       908 |       908 |       908 |       908 |       908 |       908 |         2 |
|                    Δ                     |       -96 |       -95 |       -95 |       -95 |       -95 |       -95 |       -95 |         1 |
|              Improvement %               |        10 |         9 |         9 |         9 |         9 |         9 |         9 |         1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       926 |       926 |       926 |       926 |       926 |       926 |       926 |         1 |
|                eh-branch                 |       908 |       908 |       908 |       908 |       908 |       908 |       908 |         2 |
|                    Δ                     |       -18 |       -18 |       -18 |       -18 |       -18 |       -18 |       -18 |         1 |
|              Improvement %               |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        55 |        55 |        55 |        55 |        55 |        55 |        55 |         1 |
|                eh-branch                 |        55 |        55 |        55 |        56 |        56 |        56 |        56 |         2 |
|                    Δ                     |         0 |         0 |         0 |         1 |         1 |         1 |         1 |         1 |
|              Improvement %               |         0 |         0 |         0 |        -2 |        -2 |        -2 |        -2 |         1 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2894 |      2894 |      2894 |      2894 |      2894 |      2894 |      2894 |         1 |
|                eh-branch                 |      2895 |      2895 |      2895 |      2895 |      2895 |      2895 |      2895 |         2 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        15 |        15 |        15 |        15 |        15 |        15 |        15 |         1 |
|                eh-branch                 |        15 |        15 |        15 |        15 |        15 |        15 |        15 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

## WishYouWereFast

### aead_chacha20poly1305.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       393 |       393 |       403 |       456 |       456 |       456 |       456 |         3 |
|                eh-branch                 |       388 |       388 |       388 |       388 |       388 |       388 |       388 |         3 |
|                    Δ                     |        -5 |        -5 |       -15 |       -68 |       -68 |       -68 |       -68 |         0 |
|              Improvement %               |         1 |         1 |         4 |        15 |        15 |        15 |        15 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       392 |       392 |       403 |       432 |       432 |       432 |       432 |         3 |
|                eh-branch                 |       388 |       388 |       388 |       389 |       389 |       389 |       389 |         3 |
|                    Δ                     |        -4 |        -4 |       -15 |       -43 |       -43 |       -43 |       -43 |         0 |
|              Improvement %               |         1 |         1 |         4 |        10 |        10 |        10 |        10 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         3 |         3 |         2 |         2 |         2 |         2 |         2 |         3 |
|                eh-branch                 |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         3 |
|                    Δ                     |         0 |         0 |         1 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |        50 |        50 |        50 |        50 |        50 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        14 |        14 |        14 |        14 |        14 |         3 |
|                eh-branch                 |        12 |        12 |        13 |        13 |        13 |        13 |        13 |         3 |
|                    Δ                     |         0 |         0 |        -1 |        -1 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         0 |         0 |         7 |         7 |         7 |         7 |         7 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       104 |       104 |       104 |       104 |       104 |       104 |       104 |         3 |
|                eh-branch                 |       104 |       104 |       104 |       104 |       104 |       104 |       104 |         3 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4765 |      4765 |      4769 |      4772 |      4772 |      4772 |      4772 |         3 |
|                eh-branch                 |      4763 |      4763 |      4763 |      4763 |      4763 |      4763 |      4763 |         3 |
|                    Δ                     |        -2 |        -2 |        -6 |        -9 |        -9 |        -9 |        -9 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### aead_chacha20poly13052.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       815 |       816 |       816 |       818 |       818 |       818 |       818 |         2 |
|                eh-branch                 |       816 |       816 |       816 |       816 |       816 |       816 |       816 |         2 |
|                    Δ                     |         1 |         0 |         0 |        -2 |        -2 |        -2 |        -2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       816 |       816 |       816 |       818 |       818 |       818 |       818 |         2 |
|                eh-branch                 |       816 |       816 |       816 |       816 |       816 |       816 |       816 |         2 |
|                    Δ                     |         0 |         0 |         0 |        -2 |        -2 |        -2 |        -2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        14 |        14 |        14 |        15 |        15 |        15 |        15 |         2 |
|                eh-branch                 |        14 |        14 |        14 |        15 |        15 |        15 |        15 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        65 |        65 |        65 |        65 |        65 |        65 |        65 |         2 |
|                eh-branch                 |        65 |        65 |        65 |        65 |        65 |        65 |        65 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      9130 |      9130 |      9130 |      9130 |      9130 |      9130 |      9130 |         2 |
|                eh-branch                 |      9128 |      9128 |      9128 |      9128 |      9128 |      9128 |      9128 |         2 |
|                    Δ                     |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### aead_xchacha20poly1305.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       404 |       404 |       405 |       405 |       405 |       405 |       405 |         3 |
|                eh-branch                 |       405 |       405 |       406 |       407 |       407 |       407 |       407 |         3 |
|                    Δ                     |         1 |         1 |         1 |         2 |         2 |         2 |         2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       404 |       404 |       405 |       405 |       405 |       405 |       405 |         3 |
|                eh-branch                 |       405 |       406 |       406 |       407 |       407 |       407 |       407 |         3 |
|                    Δ                     |         1 |         2 |         1 |         2 |         2 |         2 |         2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         3 |
|                eh-branch                 |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         3 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        14 |        14 |        14 |        14 |        14 |         3 |
|                eh-branch                 |        12 |        12 |        13 |        13 |        13 |        13 |        13 |         3 |
|                    Δ                     |         0 |         0 |        -1 |        -1 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         0 |         0 |         7 |         7 |         7 |         7 |         7 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        84 |        84 |        84 |        84 |        84 |        84 |        84 |         3 |
|                eh-branch                 |        84 |        84 |        84 |        84 |        84 |        84 |        84 |         3 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4653 |      4654 |      4654 |      4654 |      4654 |      4654 |      4654 |         3 |
|                eh-branch                 |      4652 |      4652 |      4652 |      4652 |      4652 |      4652 |      4652 |         3 |
|                    Δ                     |        -1 |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### auth.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        97 |        97 |        98 |        99 |        99 |        99 |        99 |        11 |
|                eh-branch                 |        97 |        98 |        98 |        98 |        98 |        98 |        98 |        11 |
|                    Δ                     |         0 |         1 |         0 |        -1 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         0 |        -1 |         0 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        97 |        98 |        98 |        99 |        99 |        99 |        99 |        11 |
|                eh-branch                 |        97 |        98 |        98 |        98 |        98 |        98 |        98 |        11 |
|                    Δ                     |         0 |         0 |         0 |        -1 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        10 |        10 |        10 |        10 |        10 |        10 |        10 |        11 |
|                eh-branch                 |        10 |        10 |        10 |        10 |        10 |        10 |        10 |        11 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        11 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        11 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        35 |        35 |        35 |        35 |        35 |        35 |        35 |        11 |
|                eh-branch                 |        35 |        35 |        35 |        35 |        35 |        35 |        35 |        11 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1511 |      1511 |      1511 |      1511 |      1511 |      1511 |      1511 |        11 |
|                eh-branch                 |      1512 |      1513 |      1513 |      1513 |      1513 |      1513 |      1513 |        11 |
|                    Δ                     |         1 |         2 |         2 |         2 |         2 |         2 |         2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### auth2.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7715 |      7741 |      7758 |      7782 |      7807 |      8016 |      8040 |       128 |
|                eh-branch                 |      7737 |      7770 |      7786 |      7811 |      7856 |      8065 |      8066 |       128 |
|                    Δ                     |        22 |        29 |        28 |        29 |        49 |        49 |        26 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -1 |        -1 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7717 |      7746 |      7762 |      7786 |      7811 |      8012 |      8043 |       128 |
|                eh-branch                 |      7743 |      7774 |      7791 |      7815 |      7848 |      8061 |      8068 |       128 |
|                    Δ                     |        26 |        28 |        29 |        29 |        37 |        49 |        25 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |        -1 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       130 |       129 |       129 |       128 |       128 |       125 |       124 |       128 |
|                eh-branch                 |       129 |       129 |       128 |       128 |       127 |       124 |       124 |       128 |
|                    Δ                     |        -1 |         0 |        -1 |         0 |        -1 |        -1 |         0 |         0 |
|              Improvement %               |        -1 |         0 |        -1 |         0 |        -1 |        -1 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        14 |        14 |        14 |        14 |        14 |       128 |
|                eh-branch                 |        11 |        14 |        14 |        14 |        14 |        14 |        14 |       128 |
|                    Δ                     |         0 |         1 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |        -8 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        24 |        24 |        24 |        24 |        24 |        24 |        24 |       128 |
|                eh-branch                 |        24 |        24 |        24 |        24 |        24 |        24 |        24 |       128 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       118 |       118 |       118 |       118 |       118 |       119 |       120 |       128 |
|                eh-branch                 |       118 |       118 |       118 |       118 |       118 |       119 |       120 |       128 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### auth3.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        14 |        17 |        17 |        77 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |        78 |
|                    Δ                     |         0 |         0 |         0 |         0 |        -1 |        -4 |        -4 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         7 |        24 |        24 |         1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        14 |        16 |        16 |        77 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |        78 |
|                    Δ                     |         0 |         0 |         0 |         0 |        -1 |        -3 |        -3 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         7 |        19 |        19 |         1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        80 |        79 |        79 |        77 |        72 |        59 |        59 |        77 |
|                eh-branch                 |        79 |        79 |        78 |        78 |        78 |        75 |        75 |        78 |
|                    Δ                     |        -1 |         0 |        -1 |         1 |         6 |        16 |        16 |         1 |
|              Improvement %               |        -1 |         0 |        -1 |         1 |         8 |        27 |        27 |         1 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        15 |        15 |        15 |        15 |        77 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        78 |
|                    Δ                     |         0 |         0 |         0 |        -2 |        -2 |        -2 |        -2 |         1 |
|              Improvement %               |         0 |         0 |         0 |        13 |        13 |        13 |        13 |         1 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        77 |
|                eh-branch                 |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        78 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       192 |       192 |       192 |       192 |       192 |       194 |       194 |        77 |
|                eh-branch                 |       193 |       193 |       193 |       193 |       193 |       195 |       195 |        78 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |         1 |

<p>
</details>

### auth6.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        10 |        10 |        10 |        11 |        11 |        11 |        11 |        95 |
|                eh-branch                 |        10 |        10 |        10 |        10 |        11 |        11 |        11 |        96 |
|                    Δ                     |         0 |         0 |         0 |        -1 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         9 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        10 |        10 |        10 |        11 |        11 |        11 |        11 |        95 |
|                eh-branch                 |        10 |        10 |        10 |        10 |        11 |        11 |        11 |        96 |
|                    Δ                     |         0 |         0 |         0 |        -1 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         9 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        96 |        96 |        96 |        95 |        95 |        93 |        93 |        95 |
|                eh-branch                 |        96 |        96 |        96 |        95 |        95 |        93 |        93 |        96 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        13 |        13 |        13 |        13 |        13 |        95 |
|                eh-branch                 |        11 |        13 |        13 |        14 |        14 |        14 |        14 |        96 |
|                    Δ                     |         0 |         0 |         0 |         1 |         1 |         1 |         1 |         1 |
|              Improvement %               |         0 |         0 |         0 |        -8 |        -8 |        -8 |        -8 |         1 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        95 |
|                eh-branch                 |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        96 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       162 |       162 |       162 |       162 |       162 |       164 |       164 |        95 |
|                eh-branch                 |       161 |       161 |       162 |       162 |       162 |       164 |       164 |        96 |
|                    Δ                     |        -1 |        -1 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         1 |         1 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

### box.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1407 |      1407 |      1407 |      1407 |      1407 |      1407 |      1407 |         1 |
|                eh-branch                 |      1393 |      1393 |      1393 |      1393 |      1393 |      1393 |      1393 |         1 |
|                    Δ                     |       -14 |       -14 |       -14 |       -14 |       -14 |       -14 |       -14 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1408 |      1408 |      1408 |      1408 |      1408 |      1408 |      1408 |         1 |
|                eh-branch                 |      1393 |      1393 |      1393 |      1393 |      1393 |      1393 |      1393 |         1 |
|                    Δ                     |       -15 |       -15 |       -15 |       -15 |       -15 |       -15 |       -15 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        57 |        57 |        57 |        57 |        57 |        57 |        57 |         1 |
|                eh-branch                 |        57 |        57 |        57 |        57 |        57 |        57 |        57 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        16 |        16 |        16 |        16 |        16 |        16 |        16 |         1 |
|                eh-branch                 |        16 |        16 |        16 |        16 |        16 |        16 |        16 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### box2.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1409 |      1409 |      1409 |      1409 |      1409 |      1409 |      1409 |         1 |
|                eh-branch                 |      1397 |      1397 |      1397 |      1397 |      1397 |      1397 |      1397 |         1 |
|                    Δ                     |       -12 |       -12 |       -12 |       -12 |       -12 |       -12 |       -12 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1409 |      1409 |      1409 |      1409 |      1409 |      1409 |      1409 |         1 |
|                eh-branch                 |      1397 |      1397 |      1397 |      1397 |      1397 |      1397 |      1397 |         1 |
|                    Δ                     |       -12 |       -12 |       -12 |       -12 |       -12 |       -12 |       -12 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        58 |        58 |        58 |        58 |        58 |        58 |        58 |         1 |
|                eh-branch                 |        58 |        58 |        58 |        58 |        58 |        58 |        58 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        16 |        16 |        16 |        16 |        16 |        16 |        16 |         1 |
|                eh-branch                 |        16 |        16 |        16 |        16 |        16 |        16 |        16 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### box_easy.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2794 |      2794 |      2794 |      2794 |      2794 |      2794 |      2794 |         1 |
|                eh-branch                 |      2775 |      2775 |      2775 |      2775 |      2775 |      2775 |      2775 |         1 |
|                    Δ                     |       -19 |       -19 |       -19 |       -19 |       -19 |       -19 |       -19 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2795 |      2795 |      2795 |      2795 |      2795 |      2795 |      2795 |         1 |
|                eh-branch                 |      2776 |      2776 |      2776 |      2776 |      2776 |      2776 |      2776 |         1 |
|                    Δ                     |       -19 |       -19 |       -19 |       -19 |       -19 |       -19 |       -19 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        60 |        60 |        60 |        60 |        60 |        60 |        60 |         1 |
|                eh-branch                 |        60 |        60 |        60 |        60 |        60 |        60 |        60 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        31 |        31 |        31 |        31 |        31 |        31 |        31 |         1 |
|                eh-branch                 |        31 |        31 |        31 |        31 |        31 |        31 |        31 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### box_seal.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7506 |      7506 |      7506 |      7506 |      7506 |      7506 |      7506 |         1 |
|                eh-branch                 |      7462 |      7462 |      7462 |      7462 |      7462 |      7462 |      7462 |         1 |
|                    Δ                     |       -44 |       -44 |       -44 |       -44 |       -44 |       -44 |       -44 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7506 |      7506 |      7506 |      7506 |      7506 |      7506 |      7506 |         1 |
|                eh-branch                 |      7465 |      7465 |      7465 |      7465 |      7465 |      7465 |      7465 |         1 |
|                    Δ                     |       -41 |       -41 |       -41 |       -41 |       -41 |       -41 |       -41 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       199 |       199 |       199 |       199 |       199 |       199 |       199 |         1 |
|                eh-branch                 |       199 |       199 |       199 |       199 |       199 |       199 |       199 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        84 |        84 |        84 |        84 |        84 |        84 |        84 |         1 |
|                eh-branch                 |        84 |        84 |        84 |        84 |        84 |        84 |        84 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### box_seed.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       232 |       232 |       233 |       233 |       241 |       241 |       241 |         5 |
|                eh-branch                 |       231 |       231 |       231 |       231 |       231 |       231 |       231 |         5 |
|                    Δ                     |        -1 |        -1 |        -2 |        -2 |       -10 |       -10 |       -10 |         0 |
|              Improvement %               |         0 |         0 |         1 |         1 |         4 |         4 |         4 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       232 |       232 |       233 |       233 |       234 |       234 |       234 |         5 |
|                eh-branch                 |       231 |       231 |       231 |       231 |       231 |       231 |       231 |         5 |
|                    Δ                     |        -1 |        -1 |        -2 |        -2 |        -3 |        -3 |        -3 |         0 |
|              Improvement %               |         0 |         0 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         5 |
|                eh-branch                 |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         5 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         5 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         5 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        71 |        71 |        71 |        71 |        71 |        71 |        71 |         5 |
|                eh-branch                 |        71 |        71 |        71 |        71 |        71 |        71 |        71 |         5 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2759 |      2760 |      2760 |      2760 |      2760 |      2760 |      2760 |         5 |
|                eh-branch                 |      2759 |      2760 |      2760 |      2760 |      2760 |      2760 |      2760 |         5 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### chacha20.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2185 |      2185 |      2185 |      2185 |      2185 |      2185 |      2185 |         1 |
|                eh-branch                 |      2183 |      2183 |      2183 |      2183 |      2183 |      2183 |      2183 |         1 |
|                    Δ                     |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |        -2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2186 |      2186 |      2186 |      2186 |      2186 |      2186 |      2186 |         1 |
|                eh-branch                 |      2183 |      2183 |      2183 |      2183 |      2183 |      2183 |      2183 |         1 |
|                    Δ                     |        -3 |        -3 |        -3 |        -3 |        -3 |        -3 |        -3 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                eh-branch                 |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        48 |        48 |        48 |        48 |        48 |        48 |        48 |         1 |
|                eh-branch                 |        48 |        48 |        48 |        48 |        48 |        48 |        48 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        20 |        20 |        20 |        20 |        20 |        20 |        20 |         1 |
|                eh-branch                 |        20 |        20 |        20 |        20 |        20 |        20 |        20 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### codecs.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      3435 |      3435 |      3435 |      3435 |      3435 |      3435 |      3435 |         1 |
|                eh-branch                 |      3435 |      3435 |      3435 |      3435 |      3435 |      3435 |      3435 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      3436 |      3436 |      3436 |      3436 |      3436 |      3436 |      3436 |         1 |
|                eh-branch                 |      3436 |      3436 |      3436 |      3436 |      3436 |      3436 |      3436 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                eh-branch                 |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       560 |       560 |       560 |       560 |       560 |       560 |       560 |         1 |
|                eh-branch                 |       561 |       561 |       561 |       561 |       561 |       561 |       561 |         1 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        37 |        37 |        37 |        37 |        37 |        37 |        37 |         1 |
|                eh-branch                 |        37 |        37 |        37 |        37 |        37 |        37 |        37 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### generichash.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1771 |      1771 |      1771 |      1771 |      1771 |      1771 |      1771 |         1 |
|                eh-branch                 |      1760 |      1760 |      1760 |      1760 |      1760 |      1760 |      1760 |         1 |
|                    Δ                     |       -11 |       -11 |       -11 |       -11 |       -11 |       -11 |       -11 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1771 |      1771 |      1771 |      1771 |      1771 |      1771 |      1771 |         1 |
|                eh-branch                 |      1760 |      1760 |      1760 |      1760 |      1760 |      1760 |      1760 |         1 |
|                    Δ                     |       -11 |       -11 |       -11 |       -11 |       -11 |       -11 |       -11 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        14 |        14 |        14 |        14 |        14 |        14 |        14 |         1 |
|                eh-branch                 |        14 |        14 |        14 |        14 |        14 |        14 |        14 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       224 |       224 |       224 |       224 |       224 |       224 |       224 |         1 |
|                eh-branch                 |       224 |       224 |       224 |       224 |       224 |       224 |       224 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        19 |        19 |        19 |        19 |        19 |        19 |        19 |         1 |
|                eh-branch                 |        19 |        19 |        19 |        19 |        19 |        19 |        19 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### generichash2.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       127 |       127 |       127 |       127 |       127 |       127 |       127 |         8 |
|                eh-branch                 |       127 |       127 |       127 |       127 |       128 |       128 |       128 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         1 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       127 |       127 |       127 |       127 |       128 |       128 |       128 |         8 |
|                eh-branch                 |       127 |       127 |       127 |       127 |       128 |       128 |       128 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         8 |         8 |         8 |         8 |         8 |         8 |         8 |         8 |
|                eh-branch                 |         8 |         8 |         8 |         8 |         8 |         8 |         8 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        13 |        13 |        13 |         8 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        70 |        70 |        70 |        70 |        70 |        70 |        70 |         8 |
|                eh-branch                 |        70 |        70 |        70 |        70 |        70 |        70 |        70 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1370 |      1370 |      1370 |      1370 |      1370 |      1370 |      1370 |         8 |
|                eh-branch                 |      1370 |      1370 |      1370 |      1370 |      1370 |      1370 |      1370 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### generichash3.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       127 |       127 |       127 |       127 |       128 |       128 |       128 |         8 |
|                eh-branch                 |       126 |       126 |       127 |       127 |       127 |       127 |       127 |         8 |
|                    Δ                     |        -1 |        -1 |         0 |         0 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         1 |         1 |         0 |         0 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       127 |       127 |       127 |       127 |       128 |       128 |       128 |         8 |
|                eh-branch                 |       126 |       126 |       127 |       127 |       127 |       127 |       127 |         8 |
|                    Δ                     |        -1 |        -1 |         0 |         0 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         1 |         1 |         0 |         0 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         8 |         8 |         8 |         8 |         8 |         8 |         8 |         8 |
|                eh-branch                 |         8 |         8 |         8 |         8 |         8 |         8 |         8 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        13 |        13 |        13 |         8 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        74 |        74 |        74 |        74 |        74 |        74 |        74 |         8 |
|                eh-branch                 |        74 |        74 |        74 |        74 |        74 |        74 |        74 |         8 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1408 |      1409 |      1409 |      1409 |      1409 |      1409 |      1409 |         8 |
|                eh-branch                 |      1408 |      1408 |      1408 |      1408 |      1409 |      1409 |      1409 |         8 |
|                    Δ                     |         0 |        -1 |        -1 |        -1 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### hash.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        14 |        14 |        14 |        14 |        14 |        14 |        14 |        72 |
|                eh-branch                 |        14 |        14 |        14 |        14 |        14 |        14 |        14 |        72 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        14 |        14 |        14 |        14 |        14 |        14 |        14 |        72 |
|                eh-branch                 |        14 |        14 |        14 |        14 |        14 |        14 |        14 |        72 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        72 |        72 |        72 |        72 |        72 |        70 |        70 |        72 |
|                eh-branch                 |        72 |        72 |        72 |        72 |        72 |        71 |        71 |        72 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         1 |         1 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        14 |        14 |        14 |        72 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        72 |
|                    Δ                     |         0 |         0 |         0 |         0 |        -1 |        -1 |        -1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         7 |         7 |         7 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        29 |        29 |        29 |        29 |        29 |        29 |        29 |        72 |
|                eh-branch                 |        29 |        29 |        29 |        29 |        29 |        29 |        29 |        72 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       210 |       210 |       210 |       210 |       210 |       212 |       212 |        72 |
|                eh-branch                 |       210 |       210 |       210 |       210 |       210 |       212 |       212 |        72 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### hash3.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4673 |      4698 |      4714 |      4739 |      4796 |      4977 |      5032 |       210 |
|                eh-branch                 |      4760 |      4788 |      4809 |      4829 |      4862 |      5059 |      5088 |       206 |
|                    Δ                     |        87 |        90 |        95 |        90 |        66 |        82 |        56 |        -4 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -1 |        -2 |        -1 |        -4 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4674 |      4698 |      4714 |      4739 |      4805 |      4973 |      5031 |       210 |
|                eh-branch                 |      4761 |      4792 |      4809 |      4833 |      4862 |      5063 |      5069 |       206 |
|                    Δ                     |        87 |        94 |        95 |        94 |        57 |        90 |        38 |        -4 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -1 |        -2 |        -1 |        -4 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       214 |       213 |       212 |       211 |       209 |       201 |       199 |       210 |
|                eh-branch                 |       210 |       209 |       208 |       207 |       206 |       198 |       197 |       206 |
|                    Δ                     |        -4 |        -4 |        -4 |        -4 |        -3 |        -3 |        -2 |        -4 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -1 |        -1 |        -1 |        -4 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        14 |        14 |        14 |        14 |        14 |       210 |
|                eh-branch                 |        11 |        13 |        14 |        14 |        14 |        14 |        14 |       206 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -4 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -4 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        23 |        23 |        23 |        23 |        23 |        23 |        23 |       210 |
|                eh-branch                 |        23 |        23 |        23 |        23 |        23 |        23 |        23 |       206 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -4 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -4 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        72 |        72 |        72 |        72 |        72 |        73 |        74 |       210 |
|                eh-branch                 |        73 |        73 |        73 |        73 |        73 |        75 |        76 |       206 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         2 |         2 |        -4 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -1 |        -3 |        -3 |        -4 |

<p>
</details>

### kdf.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        85 |        86 |        86 |        86 |        86 |        86 |        86 |        12 |
|                eh-branch                 |        85 |        86 |        86 |        86 |        86 |        87 |        87 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        85 |        86 |        86 |        86 |        86 |        86 |        86 |        12 |
|                eh-branch                 |        85 |        86 |        86 |        86 |        86 |        87 |        87 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        12 |        12 |        12 |        12 |        12 |        12 |
|                eh-branch                 |        12 |        12 |        12 |        12 |        12 |        12 |        12 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        12 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        67 |        67 |        67 |        67 |        67 |        67 |        67 |        12 |
|                eh-branch                 |        67 |        67 |        67 |        67 |        67 |        67 |        67 |        12 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1066 |      1066 |      1066 |      1066 |      1066 |      1066 |      1066 |        12 |
|                eh-branch                 |      1066 |      1067 |      1067 |      1067 |      1067 |      1067 |      1067 |        12 |
|                    Δ                     |         0 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### kdf_hkdf.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2389 |      2389 |      2389 |      2389 |      2389 |      2389 |      2389 |         1 |
|                eh-branch                 |      2393 |      2393 |      2393 |      2393 |      2393 |      2393 |      2393 |         1 |
|                    Δ                     |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2390 |      2390 |      2390 |      2390 |      2390 |      2390 |      2390 |         1 |
|                eh-branch                 |      2394 |      2394 |      2394 |      2394 |      2394 |      2394 |      2394 |         1 |
|                    Δ                     |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                eh-branch                 |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        91 |        91 |        91 |        91 |        91 |        91 |        91 |         1 |
|                eh-branch                 |        91 |        91 |        91 |        91 |        91 |        91 |        91 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        37 |        37 |        37 |        37 |        37 |        37 |        37 |         1 |
|                eh-branch                 |        37 |        37 |        37 |        37 |        37 |        37 |        37 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### keygen.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        35 |        35 |        35 |        35 |        35 |        36 |        36 |        29 |
|                eh-branch                 |        35 |        35 |        35 |        36 |        36 |        36 |        36 |        29 |
|                    Δ                     |         0 |         0 |         0 |         1 |         1 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |        -3 |        -3 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        35 |        35 |        35 |        35 |        36 |        36 |        36 |        29 |
|                eh-branch                 |        35 |        35 |        35 |        36 |        36 |        36 |        36 |        29 |
|                    Δ                     |         0 |         0 |         0 |         1 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |        -3 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        28 |        28 |        28 |        28 |        28 |        28 |        28 |        29 |
|                eh-branch                 |        28 |        28 |        28 |        28 |        28 |        28 |        28 |        29 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        29 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        29 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        28 |        28 |        28 |        28 |        28 |        28 |        28 |        29 |
|                eh-branch                 |        28 |        28 |        28 |        28 |        28 |        28 |        28 |        29 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       376 |       377 |       377 |       377 |       377 |       378 |       378 |        29 |
|                eh-branch                 |       377 |       377 |       377 |       377 |       378 |       378 |       378 |        29 |
|                    Δ                     |         1 |         0 |         0 |         0 |         1 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### onetimeauth.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4828 |      4846 |      4862 |      4887 |      4944 |      5087 |      5124 |       204 |
|                eh-branch                 |      4819 |      4837 |      4850 |      4870 |      4891 |      5059 |      5104 |       204 |
|                    Δ                     |        -9 |        -9 |       -12 |       -17 |       -53 |       -28 |       -20 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         1 |         1 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4831 |      4850 |      4866 |      4887 |      4944 |      5083 |      5127 |       204 |
|                eh-branch                 |      4821 |      4841 |      4854 |      4870 |      4891 |      5059 |      5107 |       204 |
|                    Δ                     |       -10 |        -9 |       -12 |       -17 |       -53 |       -24 |       -20 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         1 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       207 |       206 |       206 |       205 |       202 |       197 |       195 |       204 |
|                eh-branch                 |       208 |       207 |       206 |       205 |       204 |       198 |       196 |       204 |
|                    Δ                     |         1 |         1 |         0 |         0 |         2 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         1 |         1 |         1 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       204 |
|                eh-branch                 |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       204 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        21 |        21 |        21 |        21 |        21 |        21 |        21 |       204 |
|                eh-branch                 |        21 |        21 |        21 |        21 |        21 |        21 |        21 |       204 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        65 |        66 |        66 |        66 |        66 |        67 |        68 |       204 |
|                eh-branch                 |        66 |        66 |        66 |        66 |        66 |        66 |        68 |       204 |
|                    Δ                     |         1 |         0 |         0 |         0 |         0 |        -1 |         0 |         0 |
|              Improvement %               |        -2 |         0 |         0 |         0 |         0 |         1 |         0 |         0 |

<p>
</details>

### onetimeauth2.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2245 |      2257 |      2265 |      2279 |      2306 |      2417 |      2544 |       432 |
|                eh-branch                 |      2235 |      2243 |      2249 |      2261 |      2275 |      2382 |      2574 |       435 |
|                    Δ                     |       -10 |       -14 |       -16 |       -18 |       -31 |       -35 |        30 |         3 |
|              Improvement %               |         0 |         1 |         1 |         1 |         1 |         1 |        -1 |         3 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2247 |      2259 |      2267 |      2281 |      2308 |      2421 |      2544 |       432 |
|                eh-branch                 |      2237 |      2245 |      2251 |      2263 |      2277 |      2384 |      2547 |       435 |
|                    Δ                     |       -10 |       -14 |       -16 |       -18 |       -31 |       -37 |         3 |         3 |
|              Improvement %               |         0 |         1 |         1 |         1 |         1 |         2 |         0 |         3 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       445 |       443 |       442 |       439 |       434 |       414 |       393 |       432 |
|                eh-branch                 |       447 |       446 |       445 |       443 |       440 |       420 |       389 |       435 |
|                    Δ                     |         2 |         3 |         3 |         4 |         6 |         6 |        -4 |         3 |
|              Improvement %               |         0 |         1 |         1 |         1 |         1 |         1 |        -1 |         3 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       432 |
|                eh-branch                 |        11 |        13 |        13 |        13 |        13 |        14 |        14 |       435 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         1 |         1 |         3 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |        -8 |        -8 |         3 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        17 |        17 |        17 |        17 |        17 |        17 |        17 |       432 |
|                eh-branch                 |        17 |        17 |        17 |        17 |        17 |        17 |        17 |       435 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        34 |        34 |        34 |        34 |        34 |        35 |        36 |       432 |
|                eh-branch                 |        34 |        34 |        34 |        34 |        34 |        35 |        36 |       435 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |

<p>
</details>

### randombytes.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7980 |      7980 |      7980 |      7980 |      7980 |      7980 |      7980 |         1 |
|                eh-branch                 |      7968 |      7968 |      7968 |      7968 |      7968 |      7968 |      7968 |         1 |
|                    Δ                     |       -12 |       -12 |       -12 |       -12 |       -12 |       -12 |       -12 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7983 |      7983 |      7983 |      7983 |      7983 |      7983 |      7983 |         1 |
|                eh-branch                 |      7970 |      7970 |      7970 |      7970 |      7970 |      7970 |      7970 |         1 |
|                    Δ                     |       -13 |       -13 |       -13 |       -13 |       -13 |       -13 |       -13 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                eh-branch                 |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       254 |       254 |       254 |       254 |       254 |       254 |       254 |         1 |
|                eh-branch                 |       254 |       254 |       254 |       254 |       254 |       254 |       254 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        79 |        79 |        79 |        79 |        79 |        79 |        79 |         1 |
|                eh-branch                 |        79 |        79 |        79 |        79 |        79 |        79 |        79 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### scalarmult.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2715 |      2715 |      2715 |      2715 |      2715 |      2715 |      2715 |         1 |
|                eh-branch                 |      2524 |      2524 |      2524 |      2524 |      2524 |      2524 |      2524 |         1 |
|                    Δ                     |      -191 |      -191 |      -191 |      -191 |      -191 |      -191 |      -191 |         0 |
|              Improvement %               |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2716 |      2716 |      2716 |      2716 |      2716 |      2716 |      2716 |         1 |
|                eh-branch                 |      2525 |      2525 |      2525 |      2525 |      2525 |      2525 |      2525 |         1 |
|                    Δ                     |      -191 |      -191 |      -191 |      -191 |      -191 |      -191 |      -191 |         0 |
|              Improvement %               |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        91 |        91 |        91 |        91 |        91 |        91 |        91 |         1 |
|                eh-branch                 |        91 |        91 |        91 |        91 |        91 |        91 |        91 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        29 |        29 |        29 |        29 |        29 |        29 |        29 |         1 |
|                eh-branch                 |        29 |        29 |        29 |        29 |        29 |        29 |        29 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### scalarmult2.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       230 |       231 |       231 |       231 |       231 |       231 |       231 |         5 |
|                eh-branch                 |       229 |       230 |       230 |       231 |       237 |       237 |       237 |         5 |
|                    Δ                     |        -1 |        -1 |        -1 |         0 |         6 |         6 |         6 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -3 |        -3 |        -3 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       230 |       231 |       231 |       231 |       231 |       231 |       231 |         5 |
|                eh-branch                 |       229 |       230 |       230 |       231 |       233 |       233 |       233 |         5 |
|                    Δ                     |        -1 |        -1 |        -1 |         0 |         2 |         2 |         2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         5 |
|                eh-branch                 |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         5 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         5 |
|                eh-branch                 |        13 |        13 |        13 |        14 |        14 |        14 |        14 |         5 |
|                    Δ                     |         0 |         0 |         0 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |        -8 |        -8 |        -8 |        -8 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        66 |        66 |        66 |        66 |        66 |        66 |        66 |         5 |
|                eh-branch                 |        66 |        66 |        66 |        66 |        66 |        66 |        66 |         5 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      2721 |      2722 |      2722 |      2722 |      2722 |      2722 |      2722 |         5 |
|                eh-branch                 |      2721 |      2722 |      2722 |      2722 |      2722 |      2722 |      2722 |         5 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### scalarmult5.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       700 |       700 |       700 |       700 |       700 |       700 |       700 |         2 |
|                eh-branch                 |       695 |       695 |       695 |       706 |       706 |       706 |       706 |         2 |
|                    Δ                     |        -5 |        -5 |        -5 |         6 |         6 |         6 |         6 |         0 |
|              Improvement %               |         1 |         1 |         1 |        -1 |        -1 |        -1 |        -1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       700 |       700 |       700 |       700 |       700 |       700 |       700 |         2 |
|                eh-branch                 |       695 |       695 |       695 |       702 |       702 |       702 |       702 |         2 |
|                    Δ                     |        -5 |        -5 |        -5 |         2 |         2 |         2 |         2 |         0 |
|              Improvement %               |         1 |         1 |         1 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         2 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        51 |        51 |        51 |        51 |        51 |        51 |        51 |         2 |
|                eh-branch                 |        51 |        51 |        51 |        51 |        51 |        51 |        51 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7822 |      7823 |      7823 |      7823 |      7823 |      7823 |      7823 |         2 |
|                eh-branch                 |      7823 |      7825 |      7825 |      7825 |      7825 |      7825 |      7825 |         2 |
|                    Δ                     |         1 |         2 |         2 |         2 |         2 |         2 |         2 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### scalarmult6.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       704 |       705 |       705 |       805 |       805 |       805 |       805 |         2 |
|                eh-branch                 |       697 |       697 |       697 |       697 |       697 |       697 |       697 |         2 |
|                    Δ                     |        -7 |        -8 |        -8 |      -108 |      -108 |      -108 |      -108 |         0 |
|              Improvement %               |         1 |         1 |         1 |        13 |        13 |        13 |        13 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       705 |       705 |       705 |       722 |       722 |       722 |       722 |         2 |
|                eh-branch                 |       697 |       697 |       697 |       698 |       698 |       698 |       698 |         2 |
|                    Δ                     |        -8 |        -8 |        -8 |       -24 |       -24 |       -24 |       -24 |         0 |
|              Improvement %               |         1 |         1 |         1 |         3 |         3 |         3 |         3 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         2 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        54 |        54 |        54 |        54 |        54 |        54 |        54 |         2 |
|                eh-branch                 |        54 |        54 |        54 |        54 |        54 |        54 |        54 |         2 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7825 |      7827 |      7827 |      7829 |      7829 |      7829 |      7829 |         2 |
|                eh-branch                 |      7824 |      7825 |      7825 |      7825 |      7825 |      7825 |      7825 |         2 |
|                    Δ                     |        -1 |        -2 |        -2 |        -4 |        -4 |        -4 |        -4 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### scalarmult7.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1406 |      1406 |      1406 |      1406 |      1406 |      1406 |      1406 |         1 |
|                eh-branch                 |      1389 |      1389 |      1389 |      1389 |      1389 |      1389 |      1389 |         1 |
|                    Δ                     |       -17 |       -17 |       -17 |       -17 |       -17 |       -17 |       -17 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      1403 |      1403 |      1403 |      1403 |      1403 |      1403 |      1403 |         1 |
|                eh-branch                 |      1389 |      1389 |      1389 |      1389 |      1389 |      1389 |      1389 |         1 |
|                    Δ                     |       -14 |       -14 |       -14 |       -14 |       -14 |       -14 |       -14 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                eh-branch                 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        51 |        51 |        51 |        51 |        51 |        51 |        51 |         1 |
|                eh-branch                 |        51 |        51 |        51 |        51 |        51 |        51 |        51 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        16 |        16 |        16 |        16 |        16 |        16 |        16 |         1 |
|                eh-branch                 |        16 |        16 |        16 |        16 |        16 |        16 |        16 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### secretbox.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      9788 |      9822 |      9847 |      9871 |      9904 |     10863 |     17942 |       101 |
|                eh-branch                 |      9797 |      9822 |      9839 |      9871 |      9904 |     10600 |     17836 |       101 |
|                    Δ                     |         9 |         0 |        -8 |         0 |         0 |      -263 |      -106 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         2 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      9793 |      9822 |      9847 |      9871 |      9912 |     10625 |     10871 |       101 |
|                eh-branch                 |      9801 |      9830 |      9847 |      9880 |      9904 |     10519 |     10601 |       101 |
|                    Δ                     |         8 |         8 |         0 |         9 |        -8 |      -106 |      -270 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         1 |         2 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       102 |       102 |       102 |       101 |       101 |        92 |        56 |       101 |
|                eh-branch                 |       102 |       102 |       102 |       101 |       101 |        94 |        56 |       101 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         2 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         2 |         0 |         0 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        13 |        13 |        13 |       101 |
|                eh-branch                 |        12 |        13 |        13 |        13 |        13 |        13 |        13 |       101 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        23 |        23 |        23 |        23 |        23 |        23 |        23 |       101 |
|                eh-branch                 |        23 |        23 |        23 |        23 |        23 |        23 |        23 |       101 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       112 |       112 |       112 |       112 |       112 |       112 |       112 |       101 |
|                eh-branch                 |       111 |       111 |       111 |       111 |       112 |       112 |       112 |       101 |
|                    Δ                     |        -1 |        -1 |        -1 |        -1 |         0 |         0 |         0 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         0 |         0 |         0 |         0 |

<p>
</details>

### secretbox2.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7537 |      7565 |      7586 |      7614 |      7651 |      8245 |      8607 |       130 |
|                eh-branch                 |      7615 |      7643 |      7668 |      7700 |      7844 |      8155 |      8573 |       129 |
|                    Δ                     |        78 |        78 |        82 |        86 |       193 |       -90 |       -34 |        -1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -3 |         1 |         0 |        -1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7538 |      7569 |      7590 |      7614 |      7651 |      8249 |      8611 |       130 |
|                eh-branch                 |      7620 |      7651 |      7672 |      7709 |      7832 |      8151 |      8583 |       129 |
|                    Δ                     |        82 |        82 |        82 |        95 |       181 |       -98 |       -28 |        -1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -2 |         1 |         0 |        -1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       133 |       132 |       132 |       131 |       130 |       121 |       116 |       130 |
|                eh-branch                 |       131 |       131 |       130 |       130 |       128 |       123 |       117 |       129 |
|                    Δ                     |        -2 |        -1 |        -2 |        -1 |        -2 |         2 |         1 |        -1 |
|              Improvement %               |        -2 |        -1 |        -2 |        -1 |        -2 |         2 |         1 |        -1 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       130 |
|                eh-branch                 |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       129 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        24 |        24 |        24 |        24 |        24 |        24 |        24 |       130 |
|                eh-branch                 |        24 |        24 |        24 |        24 |        24 |        24 |        24 |       129 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        89 |        89 |        89 |        89 |        89 |        89 |        90 |       130 |
|                eh-branch                 |        90 |        90 |        90 |        90 |        90 |        91 |        92 |       129 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         2 |         2 |        -1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -1 |        -2 |        -2 |        -1 |

<p>
</details>

### secretbox_easy.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        33 |        33 |        33 |        33 |        33 |        33 |        33 |        31 |
|                eh-branch                 |        33 |        33 |        33 |        33 |        33 |        36 |        36 |        30 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         3 |         3 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |        -9 |        -9 |        -1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        33 |        33 |        33 |        33 |        33 |        33 |        33 |        31 |
|                eh-branch                 |        33 |        33 |        33 |        33 |        33 |        34 |        34 |        30 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         1 |         1 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |        -3 |        -3 |        -1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        30 |        30 |        30 |        30 |        30 |        30 |        30 |        31 |
|                eh-branch                 |        30 |        30 |        30 |        30 |        29 |        27 |        27 |        30 |
|                    Δ                     |         0 |         0 |         0 |         0 |        -1 |        -3 |        -3 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -3 |       -10 |       -10 |        -1 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        13 |        13 |        13 |        13 |        31 |
|                eh-branch                 |        12 |        13 |        13 |        14 |        14 |        14 |        14 |        30 |
|                    Δ                     |         0 |         0 |         0 |         1 |         1 |         1 |         1 |        -1 |
|              Improvement %               |         0 |         0 |         0 |        -8 |        -8 |        -8 |        -8 |        -1 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        31 |        31 |        31 |        31 |        31 |        31 |        31 |        31 |
|                eh-branch                 |        31 |        31 |        31 |        31 |        31 |        31 |        31 |        30 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       374 |       374 |       374 |       374 |       374 |       374 |       374 |        31 |
|                eh-branch                 |       374 |       374 |       374 |       374 |       374 |       375 |       375 |        30 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         1 |         1 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |

<p>
</details>

### secretstream_xchacha20poly1305.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       303 |       303 |       303 |       306 |       313 |       313 |       313 |         4 |
|                eh-branch                 |       302 |       303 |       307 |       308 |       310 |       310 |       310 |         4 |
|                    Δ                     |        -1 |         0 |         4 |         2 |        -3 |        -3 |        -3 |         0 |
|              Improvement %               |         0 |         0 |        -1 |        -1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       303 |       303 |       303 |       306 |       313 |       313 |       313 |         4 |
|                eh-branch                 |       302 |       303 |       308 |       308 |       310 |       310 |       310 |         4 |
|                    Δ                     |        -1 |         0 |         5 |         2 |        -3 |        -3 |        -3 |         0 |
|              Improvement %               |         0 |         0 |        -2 |        -1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         4 |
|                eh-branch                 |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         4 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        14 |        14 |        15 |        16 |        16 |        16 |        16 |         4 |
|                eh-branch                 |        14 |        14 |        15 |        16 |        16 |        16 |        16 |         4 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        49 |        49 |        49 |        49 |        49 |        49 |        49 |         4 |
|                eh-branch                 |        49 |        49 |        49 |        49 |        49 |        49 |        49 |         4 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      3025 |      3026 |      3035 |      3056 |      3117 |      3117 |      3117 |         4 |
|                eh-branch                 |      3028 |      3028 |      3081 |      3087 |      3101 |      3101 |      3101 |         4 |
|                    Δ                     |         3 |         2 |        46 |        31 |       -16 |       -16 |       -16 |         0 |
|              Improvement %               |         0 |         0 |        -2 |        -1 |         1 |         1 |         1 |         0 |

<p>
</details>

### shorthash.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7262 |      7299 |      7315 |      7336 |      7365 |      7574 |      7611 |       136 |
|                eh-branch                 |      7318 |      7348 |      7369 |      7397 |      7479 |      7639 |      7639 |       135 |
|                    Δ                     |        56 |        49 |        54 |        61 |       114 |        65 |        28 |        -1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -2 |        -1 |         0 |        -1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      7264 |      7303 |      7320 |      7336 |      7365 |      7565 |      7616 |       136 |
|                eh-branch                 |      7319 |      7356 |      7373 |      7397 |      7483 |      7623 |      7635 |       135 |
|                    Δ                     |        55 |        53 |        53 |        61 |       118 |        58 |        19 |        -1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -2 |        -1 |         0 |        -1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       138 |       137 |       137 |       136 |       136 |       132 |       131 |       136 |
|                eh-branch                 |       137 |       136 |       136 |       135 |       134 |       131 |       131 |       135 |
|                    Δ                     |        -1 |        -1 |        -1 |        -1 |        -2 |        -1 |         0 |        -1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |         0 |        -1 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       136 |
|                eh-branch                 |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       135 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        19 |        19 |        19 |        19 |        19 |        19 |        19 |       136 |
|                eh-branch                 |        19 |        19 |        19 |        19 |        19 |        19 |        19 |       135 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        82 |        82 |        82 |        82 |        82 |        83 |        84 |       136 |
|                eh-branch                 |        83 |        83 |        83 |        83 |        83 |        84 |        85 |       135 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        -1 |
|              Improvement %               |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |        -1 |

<p>
</details>

### sign2.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (ms) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4150 |      4150 |      4150 |      4150 |      4150 |      4150 |      4150 |         1 |
|                eh-branch                 |      4123 |      4123 |      4123 |      4123 |      4123 |      4123 |      4123 |         1 |
|                    Δ                     |       -27 |       -27 |       -27 |       -27 |       -27 |       -27 |       -27 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (ms) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4151 |      4151 |      4151 |      4151 |      4151 |      4151 |      4151 |         1 |
|                eh-branch                 |      4124 |      4124 |      4124 |      4124 |      4124 |      4124 |      4124 |         1 |
|                    Δ                     |       -27 |       -27 |       -27 |       -27 |       -27 |       -27 |       -27 |         0 |
|              Improvement %               |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                eh-branch                 |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       113 |       113 |       113 |       113 |       113 |       113 |       113 |         1 |
|                eh-branch                 |       113 |       113 |       113 |       113 |       113 |       113 |       113 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (G) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        46 |        46 |        46 |        46 |        46 |        46 |        46 |         1 |
|                eh-branch                 |        46 |        46 |        46 |        46 |        46 |        46 |        46 |         1 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### siphashx24.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      8739 |      8774 |      8798 |      8831 |      8905 |      9617 |     16842 |       112 |
|                eh-branch                 |      8739 |      8790 |      8806 |      8856 |      8995 |      9077 |      9085 |       113 |
|                    Δ                     |         0 |        16 |         8 |        25 |        90 |      -540 |     -7757 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -1 |         6 |        46 |         1 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      8745 |      8782 |      8806 |      8839 |      8913 |      9593 |      9621 |       112 |
|                eh-branch                 |      8741 |      8790 |      8815 |      8856 |      8995 |      9077 |      9095 |       113 |
|                    Δ                     |        -4 |         8 |         9 |        17 |        82 |      -516 |      -526 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -1 |         5 |         5 |         1 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       114 |       114 |       114 |       113 |       112 |       104 |        59 |       112 |
|                eh-branch                 |       114 |       114 |       114 |       113 |       111 |       110 |       110 |       113 |
|                    Δ                     |         0 |         0 |         0 |         0 |        -1 |         6 |        51 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |        -1 |         6 |        86 |         1 |

<p>
</details>

<details><summary>Memory (resident peak): results within specified thresholds, fold down for details.</summary>
<p>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        12 |        13 |        13 |        14 |        14 |        14 |        14 |       112 |
|                eh-branch                 |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       113 |
|                    Δ                     |        -1 |         0 |         0 |        -1 |        -1 |        -1 |        -1 |         1 |
|              Improvement %               |         8 |         0 |         0 |         7 |         7 |         7 |         7 |         1 |

<p>
</details>

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        19 |        19 |        19 |        19 |        19 |        19 |        19 |       112 |
|                eh-branch                 |        19 |        19 |        19 |        19 |        19 |        19 |        19 |       113 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        95 |        95 |        95 |        95 |        95 |        95 |        95 |       112 |
|                eh-branch                 |        94 |        94 |        94 |        94 |        95 |        95 |        96 |       113 |
|                    Δ                     |        -1 |        -1 |        -1 |        -1 |         0 |         0 |         1 |         1 |
|              Improvement %               |         1 |         1 |         1 |         1 |         0 |         0 |        -1 |         1 |

<p>
</details>

### stream3.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      3655 |      3672 |      3684 |      3705 |      3744 |      3936 |      4038 |       268 |
|                eh-branch                 |      3652 |      3670 |      3678 |      3695 |      3719 |      3877 |      4022 |       268 |
|                    Δ                     |        -3 |        -2 |        -6 |       -10 |       -25 |       -59 |       -16 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         1 |         1 |         0 |         0 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      3657 |      3674 |      3688 |      3707 |      3744 |      3928 |      4015 |       268 |
|                eh-branch                 |      3654 |      3674 |      3682 |      3697 |      3719 |      3883 |      3986 |       268 |
|                    Δ                     |        -3 |         0 |        -6 |       -10 |       -25 |       -45 |       -29 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         1 |         1 |         1 |         0 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       274 |       272 |       272 |       270 |       267 |       254 |       248 |       268 |
|                eh-branch                 |       274 |       272 |       272 |       271 |       269 |       258 |       249 |       268 |
|                    Δ                     |         0 |         0 |         0 |         1 |         2 |         4 |         1 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         1 |         2 |         0 |         0 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        13 |        14 |        14 |        14 |        14 |       268 |
|                eh-branch                 |        11 |        15 |        15 |        15 |        15 |        15 |        15 |       268 |
|                    Δ                     |         0 |         2 |         2 |         1 |         1 |         1 |         1 |         0 |
|              Improvement %               |         0 |       -15 |       -15 |        -7 |        -7 |        -7 |        -7 |         0 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        20 |        20 |        20 |        20 |        20 |        20 |        20 |       268 |
|                eh-branch                 |        20 |        20 |        20 |        20 |        20 |        20 |        20 |       268 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        48 |        48 |        48 |        48 |        48 |        50 |        50 |       268 |
|                eh-branch                 |        48 |        48 |        48 |        48 |        48 |        50 |        50 |       268 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         0 |

<p>
</details>

### stream4.wasm metrics

<details><summary>Time (wall clock): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (wall clock) (μs) *         |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4903 |      4923 |      4940 |      4960 |      4993 |      5157 |      5213 |       201 |
|                eh-branch                 |      5004 |      5022 |      5034 |      5050 |      5087 |      5333 |      5363 |       197 |
|                    Δ                     |       101 |        99 |        94 |        90 |        94 |       176 |       150 |        -4 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -2 |        -3 |        -3 |        -4 |

<p>
</details>

<details><summary>Time (total CPU): results within specified thresholds, fold down for details.</summary>
<p>

|         Time (total CPU) (μs) *          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |      4907 |      4927 |      4944 |      4964 |      4989 |      5161 |      5198 |       201 |
|                eh-branch                 |      5005 |      5026 |      5038 |      5054 |      5087 |      5337 |      5366 |       197 |
|                    Δ                     |        98 |        99 |        94 |        90 |        98 |       176 |       168 |        -4 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -2 |        -3 |        -3 |        -4 |

<p>
</details>

<details><summary>Throughput (# / s): results within specified thresholds, fold down for details.</summary>
<p>

|          Throughput (# / s) (#)          |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |       204 |       203 |       203 |       202 |       200 |       194 |       192 |       201 |
|                eh-branch                 |       200 |       199 |       199 |       198 |       197 |       188 |       186 |       197 |
|                    Δ                     |        -4 |        -4 |        -4 |        -4 |        -3 |        -6 |        -6 |        -4 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -2 |        -3 |        -3 |        -4 |

<p>
</details>

|        Memory (resident peak) (M)        |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        11 |        13 |        13 |        13 |        13 |        13 |        13 |       201 |
|                eh-branch                 |        11 |        13 |        13 |        13 |        13 |        14 |        14 |       197 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         1 |         1 |        -4 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |        -8 |        -8 |        -4 |

<details><summary>Malloc (total): results within specified thresholds, fold down for details.</summary>
<p>

|           Malloc (total) (K) *           |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        20 |        20 |        20 |        20 |        20 |        20 |        20 |       201 |
|                eh-branch                 |        20 |        20 |        20 |        20 |        20 |        20 |        20 |       197 |
|                    Δ                     |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -4 |
|              Improvement %               |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        -4 |

<p>
</details>

<details><summary>Instructions: results within specified thresholds, fold down for details.</summary>
<p>

|            Instructions (M) *            |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:----------------------------------------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
|                   main                   |        60 |        60 |        60 |        60 |        60 |        61 |        62 |       201 |
|                eh-branch                 |        61 |        61 |        61 |        61 |        61 |        63 |        63 |       197 |
|                    Δ                     |         1 |         1 |         1 |         1 |         1 |         2 |         1 |        -4 |
|              Improvement %               |        -2 |        -2 |        -2 |        -2 |        -2 |        -3 |        -2 |        -4 |

<p>
</details>

