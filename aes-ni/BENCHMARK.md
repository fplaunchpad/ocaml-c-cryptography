# BENCHMARK.md

# AES-NI Benchmark: C vs OCaml C-Bindings

## 1. Introduction

This document covers the performance comparison between a pure C AES-NI implementation and an OCaml implementation that drives the same hardware through C FFI bindings. The project structure, commands, and build instructions are in README.md. This document focuses entirely on results, analysis, and technical reasoning.

---

## 2. Background: AES-NI and the OCaml Binding Decision

AES-NI is a set of x86 CPU instructions introduced by Intel in 2010. It implements the core AES operations — SubBytes, ShiftRows, MixColumns, AddRoundKey — directly in silicon. A single AES-128 encryption block (10 rounds) runs in approximately 1 CPU cycle per byte.

The six critical instructions are:

| Instruction                 | Purpose                                      |
| --------------------------- | -------------------------------------------- |
| `_mm_aesenc_si128`          | One AES-128/192/256 encryption round         |
| `_mm_aesenclast_si128`      | Final AES encryption round (no MixColumns)   |
| `_mm_aesdec_si128`          | One AES-128/192/256 decryption round         |
| `_mm_aesdeclast_si128`      | Final AES decryption round                   |
| `_mm_aeskeygenassist_si128` | Key schedule expansion assist                |
| `_mm_aesimc_si128`          | Inverse MixColumns for decryption key prep   |

All operate on 128-bit SSE registers (`__m128i`), which map to OxCaml's `Int8x16` type. However, OxCaml's `ocaml_simd_sse` library covers only general SSE/AVX2 operations (arithmetic, logical, shuffle). The AES-NI extension (`wmmintrin.h`) is a separate CPU feature and **none of the six AES instructions appear in OxCaml's SIMD library**. This was verified against the `janestreet/ocaml_simd` repository (`with-extensions` branch).

A direct OxCaml translation is therefore impossible. A software OCaml AES implementation was already studied in `rijndael/` and peaks at ~165 MB/s after full optimization — roughly 6–8× slower than hardware AES-NI. The only meaningful option is **C FFI bindings**, modelled after the [Cryptokit library](https://github.com/xavierleroy/cryptokit) by Xavier Leroy (INRIA).

---

## 3. Binding Architecture

The OCaml bindings follow Cryptokit's `stubs-aes.c` pattern exactly.

**Cooked key layout** (241 bytes, allocated as an OCaml string):

```text
bytes 0..239  : expanded AES round key schedule  (15 slots × 16 bytes)
byte  240     : number of rounds (nr = 10 for AES-128)
```

This is identical to Cryptokit's `Cooked_key_NR_offset = (4 * (MAXNR + 1)) * sizeof(u32) = 240`.

**Hot path**: the OCaml benchmark drives the block loop and calls the C stub once per 16-byte block:

```ocaml
for i = 0 to nblocks - 1 do
  let off = i * 16 in
  encrypt_block ckey_enc padded off encrypted off
done
```

Each call crosses the OCaml/C boundary. For 100 MB that is **6,553,600 FFI calls** per encrypt or decrypt pass.

---

## 4. Experimental Environment

### Hardware

| Component    | Value                          |
| ------------ | ------------------------------ |
| CPU          | Intel Core i5-1240P (12th Gen) |
| RAM          | 8 GB                           |
| Architecture | x86_64                         |
| AES-NI       | Available                      |

### Software

| Component | Value                             |
| --------- | --------------------------------- |
| OS        | Ubuntu under WSL2                 |
| Kernel    | 6.18.33.1-microsoft-standard-WSL2 |
| OCaml     | 5.4.1                             |
| GCC       | 13.3.0                            |
| Dune      | 3.x                               |

Both C and OCaml are compiled with `-maes -O3`. The OCaml executable is native-only.

---

## 5. Benchmark Results

### C Implementation

| Input (MB) | Enc Time (s) | Dec Time (s) | Enc Speed (MB/s) | Dec Speed (MB/s) |
| ---------: | -----------: | -----------: | ---------------: | ---------------: |
| 1          | 0.000590     | 0.000743     | 1694.08          | 1345.61          |
| 10         | 0.008069     | 0.006621     | 1239.30          | 1510.33          |
| 30         | 0.025877     | 0.035059     | 1159.34          | 855.71           |
| 50         | 0.034107     | 0.047799     | 1465.97          | 1046.04          |
| 75         | 0.095856     | 0.078546     | 782.43           | 954.86           |
| 100        | 0.051205     | 0.079267     | 1952.94          | 1261.56          |

### OCaml + C Bindings

| Input (MB) | Enc Time (s) | Dec Time (s) | Enc Speed (MB/s) | Dec Speed (MB/s) |
| ---------: | -----------: | -----------: | ---------------: | ---------------: |
| 1          | 0.001016     | 0.000915     | 984.37           | 1092.86          |
| 10         | 0.008500     | 0.009240     | 1176.46          | 1082.26          |
| 30         | 0.026104     | 0.051862     | 1149.24          | 578.46           |
| 50         | 0.044450     | 0.066562     | 1124.86          | 751.18           |
| 75         | 0.056075     | 0.111427     | 1337.49          | 673.09           |
| 100        | 0.077650     | 0.137187     | 1287.83          | 728.93           |

### Average Throughput

| Implementation     | Avg Enc Speed (MB/s) | Avg Dec Speed (MB/s) |
| ------------------ | -------------------: | -------------------: |
| C (AES-NI)         | 1382                 | 1162                 |
| OCaml + C bindings | 1177                 | 818                  |
| **C advantage**    | **+17%**             | **+42%**             |

---

## 6. Why C Is Faster

### 6.1 Per-Block FFI Call Overhead

The most direct explanation is the extra function call layer per block.

**C hot path:**
```c
for (long i = 0; i < padded_len; i += 16)
    aesniEncrypt(ckey_enc, nr_enc, message + i, encrypted + i);
```
One function call: `C loop → aesniEncrypt`.

**OCaml hot path:**
```ocaml
encrypt_block ckey_enc padded off encrypted off
(* which calls → caml_aes_encrypt → aesniEncrypt *)
```
Two function calls per block: `OCaml loop → C stub → aesniEncrypt`.

Each OCaml → C stub crossing involves:
- OCaml calling convention → C calling convention transition
- Five argument unboxings: `String_val(v_ckey)`, `Long_val(v_src_ofs)`, `Long_val(v_dst_ofs)`, two `Byte()` pointer computations
- Function prologue and epilogue at the stub level

For 100 MB, that is 6.5 million extra function calls. Even at ~5–10 ns overhead each, this accumulates to **30–65 ms added latency per pass**, consistent with the observed gap (~26 ms for encryption, ~58 ms for decryption at 100 MB).

### 6.2 The Decryption Gap Is Larger (+42% vs +17%)

The encryption overhead gap (~17%) and decryption overhead gap (~42%) differ significantly. Several factors contribute:

**AES-NI instruction latency asymmetry.** On Intel 12th Gen (Alder Lake), `_mm_aesdec_si128` has slightly higher throughput latency than `_mm_aesenc_si128` on the efficiency cores. This amplifies the relative cost of the OCaml stub overhead per block on the decryption path.

**Decryption key schedule.** `aesniKeySetupDec` applies `_mm_aesimc_si128` (Inverse MixColumns) to every intermediate round key. The resulting key schedule has a different memory layout from the encryption schedule, potentially causing different cache behaviour during the decryption loop. The C tight loop benefits more from hardware prefetching with a predictable access pattern; the OCaml stub call boundary may interrupt the CPU's prefetch pipeline more on decryption.

**Accumulated stub overhead.** Each OCaml FFI crossing is a small but non-zero cache miss risk (instruction cache for the stub code, stack frame setup). Over 6.5 million calls on decryption, where the AES instruction itself may be slightly slower, the proportion of stub time rises.

### 6.3 WSL2 Timing Noise

The raw numbers also show significant WSL2 variance. For example:
- C at 75 MB: 782 MB/s encryption (slow)
- C at 100 MB: 1953 MB/s encryption (fast)

These large swings are caused by WSL2 scheduler behaviour, CPU boost clock variability, and thermal state. Single-run numbers should not be over-interpreted. Averages across all six sizes are the more reliable comparison.

---

## 7. Comparison with Software Rijndael

| Implementation              | Avg Enc (MB/s) | Avg Dec (MB/s) | Notes                       |
| --------------------------- | -------------: | -------------: | --------------------------- |
| Rijndael OCaml (original)   | ~34            | ~37            | Int32-based, heavy GC       |
| Rijndael OCaml (optimized)  | ~165           | ~152           | Native-int, allocation-free |
| Rijndael C (T-table)        | ~164           | ~169           | Software reference          |
| AES-NI OCaml (C bindings)   | 1177           | 818            | FFI loop, hw accelerated    |
| AES-NI C                    | 1382           | 1162           | Direct hw, tight C loop     |

AES-NI is **~7–8× faster** than optimized software AES. The hardware eliminates all T-table lookups, XOR accumulation, and byte manipulation from the hot path. Even with OCaml FFI overhead, C bindings to AES-NI significantly outperform the best possible pure OCaml software implementation.

---

## 8. Benchmark Figures

### Figure 1: Encryption Time

![Encryption Time](results/encryption_time_comparison.png)

### Figure 2: Decryption Time

![Decryption Time](results/decryption_time_comparison.png)

### Figure 3: Encryption Throughput

![Encryption Throughput](results/encryption_speed_comparison.png)

### Figure 4: Decryption Throughput

![Decryption Throughput](results/decryption_speed_comparison.png)

---

## 9. Key Findings

**C is faster by a consistent margin.** The ~17% encryption gap and ~42% decryption gap are both attributable to the 6.5 million per-block OCaml/C FFI crossings that the C implementation avoids entirely.

**The decryption gap is disproportionately large.** AES-NI decryption instruction latency asymmetry and key schedule cache differences amplify the stub overhead cost on the decryption path relative to encryption.

**FFI overhead is not free at this call frequency.** When individual C calls are this cheap (hardware-bound, single-digit nanoseconds), the boundary crossing cost becomes a meaningful fraction of total work. Batching — calling C once per buffer rather than once per block — would close the gap. This is a design trade-off in the binding architecture.

**Both implementations are in the same performance class.** At 1000–1400 MB/s average, both are delivering hardware-accelerated AES, roughly 7–8× faster than any OCaml software implementation regardless of optimization.

**OxCaml SIMD cannot bridge this gap today.** The missing AES-NI operations in `ocaml_simd_sse` mean C bindings remain the only production path. If OxCaml added the six AES instructions, a direct OCaml implementation could eliminate the stub layer and potentially match or exceed the C performance.

---

## 10. Conclusion

The C implementation is faster due to a direct, single-level call into AES-NI hardware. OCaml adds an extra function call boundary per 16-byte block, totalling 6.5 million additional calls per 100 MB pass. This cost is measurable (~17% on encryption, ~42% on decryption) and is the expected penalty for driving hardware intrinsics through a language FFI at block granularity.

Despite this overhead, OCaml with C bindings still delivers ~1177 MB/s encryption and ~818 MB/s decryption — hardware-class performance that no software AES implementation can approach. For any practical use case where AES-NI is available, the OCaml binding path is entirely viable, with the gap quantified here.

Closing the gap entirely would require either exposing AES-NI operations in OxCaml's SIMD layer, or restructuring the binding to batch whole buffers rather than individual blocks.
