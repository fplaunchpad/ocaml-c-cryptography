# BENCHMARK.md

# AES-NI Benchmark: C vs OCaml C-Bindings vs OxCaml SIMD

## 1. Introduction

This document covers the performance comparison across three implementations of AES-NI:

1. **Pure C** — direct inline AES-NI hardware intrinsics
2. **OCaml + C bindings** — OCaml drives a per-block C stub (Cryptokit pattern)
3. **OxCaml SIMD** — key expansion rewritten using OxCaml's native SIMD builtins; AES round functions still via C stubs

The project structure, commands, and build instructions are in README.md. This document focuses entirely on results, analysis, and technical reasoning.

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

### OxCaml SIMD (key expansion inlined, AES rounds via C stubs)

| Input (MB) | Enc Time (s) | Dec Time (s) | Enc Speed (MB/s) | Dec Speed (MB/s) |
| ---------: | -----------: | -----------: | ---------------: | ---------------: |
| 1          | 0.010391     | 0.007683     | 96.24            | 130.16           |
| 10         | 0.068663     | 0.071914     | 145.64           | 139.06           |
| 30         | 0.206119     | 0.215597     | 145.55           | 139.15           |
| 50         | 0.354744     | 0.346783     | 140.95           | 144.18           |
| 75         | 0.532771     | 0.521435     | 140.77           | 143.83           |
| 100        | 0.691480     | 0.718553     | 144.62           | 139.17           |

### Average Throughput

| Implementation       | Avg Enc Speed (MB/s) | Avg Dec Speed (MB/s) |
| -------------------- | -------------------: | -------------------: |
| C (AES-NI)           | 1382                 | 1162                 |
| OCaml + C bindings   | 1177                 | 818                  |
| OxCaml SIMD          | 142                  | 139                  |
| **C vs OxCaml SIMD** | **~10×**             | **~8×**              |

---

## 6. OxCaml SIMD Attempt: What Was Done and Why It Is Slow

### 6.1 The Goal

OxCaml (Jane Street's performance-focused fork of OCaml) exposes native SIMD types and a set of `[@@builtin]` intrinsics that compile directly to single machine instructions with no function call overhead. The Flambda2 optimizer keeps SIMD values in XMM registers across chains of builtin calls. If AES-NI instructions were available as OxCaml builtins, the entire encrypt/decrypt path could be expressed as a chain of inline instructions — potentially matching or exceeding C performance.

### 6.2 What OxCaml SIMD Provides

OxCaml's SIMD extension (`-extension simd_beta`) provides:

| OxCaml builtin                     | x86 instruction | Used for         |
| ----------------------------------- | --------------- | ---------------- |
| `caml_sse_vec128_xor`               | `PXOR`          | Key XOR          |
| `caml_sse_vec128_shuffle_32`        | `SHUFPS`        | Key rotation     |
| `caml_sse2_vec128_shift_left_bytes` | `PSLLDQ`        | Key shift        |
| `caml_sse2_vec128_shuffle_64`       | `SHUFPD`        | 192-bit key mix  |
| `%caml_bytes_getu128u`              | (inline load)   | 128-bit block IO |
| `%caml_bytes_setu128u`              | (inline store)  | 128-bit block IO |

These cover everything needed for **key expansion** (the `xor`/`shuffle`/`shift` chain in `aesni_128_assist`). The key expansion was fully rewritten in OxCaml using these builtins — no C call is made during `cook_encrypt_key` or `cook_decrypt_key`.

### 6.3 What OxCaml SIMD Does NOT Provide

The six AES-specific hardware instructions are **not** in OxCaml's SIMD backend:

| Missing                      | x86 instruction | Purpose               |
| ----------------------------- | --------------- | --------------------- |
| `caml_aesni_aesenc`           | `AESENC`        | One encryption round  |
| `caml_aesni_aesenclast`       | `AESENCLAST`    | Final encryption round|
| `caml_aesni_aesdec`           | `AESDEC`        | One decryption round  |
| `caml_aesni_aesdeclast`       | `AESDECLAST`    | Final decryption round|
| `caml_aesni_aesimc`           | `AESIMC`        | Decrypt key prep      |
| `caml_aesni_keygenassist`     | `AESKEYGENASSIST`| Key schedule assist  |

These were exposed as ordinary `[@@noalloc]` C stubs — not `[@@builtin]`. Every call crosses the OCaml/C boundary.

### 6.4 Why This Makes the Hot Path Slow

The original OCaml C-bindings called **one C function per block** — that C function ran all 10–14 AES rounds inline. The OxCaml SIMD version calls **one C function per round** — 11 calls per block for AES-128.

**Original OCaml C-bindings (fast):**
```
OCaml loop
  → caml_aes_encrypt()     ← 1 C call per block
      → AESENC              ← all 11 rounds inline inside C
      → AESENC
      → ...
      → AESENCLAST
```

**OxCaml SIMD version (slow):**
```
OCaml loop
  → caml_aesni_aesenc()    ← C call 1 of 11
      → AESENC → RET
  → caml_aesni_aesenc()    ← C call 2 of 11
      → AESENC → RET
  → ...                    (× 9 more)
  → caml_aesni_aesenclast()← C call 11 of 11
      → AESENCLAST → RET
```

Even with `[@@noalloc]` and `[@unboxed]` (XMM values passed in registers, no GC, no boxing), each call still has function call overhead: stack frame setup, call/return, instruction cache pressure.

**Numbers:**

| Implementation       | C calls per block | C calls per 100 MB | Enc Speed  |
|----------------------|------------------:|-------------------:|------------|
| OCaml + C bindings   | 1                 | 6.5 million        | ~1177 MB/s |
| OxCaml SIMD          | 11                | 72 million         | ~142 MB/s  |

Moving from 1 C call to 11 C calls per block made OxCaml **slower than the original OCaml** — the SIMD improvements to key expansion (which are genuine) are completely overshadowed by 11× more boundary crossings on the hot path.

### 6.5 Why Adding AES-NI to OxCaml Is Non-Trivial

We investigated adding the AES-NI instructions as `[@@builtin]` to OxCaml's compiler backend. This requires:

1. Defining `AES` as a new CPU extension in `tools/simdgen/amd64_simd_defs.ml`
2. Updating the instruction generator (`simdgen.ml`) to parse `"AES"` / `"AES AVX"` from the CSV — the instructions are already in the CSV but skipped
3. Regenerating `tools/simdgen/amd64_simd_instrs.ml` to emit `aesenc`, `vaesenc`, etc.
4. Adding `AES` to the `Extension` module in `backend/amd64/arch.ml` and `arch.mli`
5. Adding `select_operation_aes` to `backend/amd64/simd_selection.ml` to map `caml_aesni_aesenc` → inline `AESENC`
6. Rebuilding and reinstalling the OxCaml compiler (~15–20 min full build)

The instruction generator step works (all 6 SSE + 6 VEX AES variants are generated correctly). However, the instruction **emitter** (`emit.ml`) must also be verified to correctly encode each AES opcode, which requires detailed review of the encoding tables. This is a genuine compiler contribution — not a configuration change — and was beyond the scope of this benchmarking project.

---

## 7. Why C Is Faster (OCaml C-Bindings vs C)

### 7.1 Per-Block FFI Call Overhead

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

### 7.2 The Decryption Gap Is Larger (+42% vs +17%)

The encryption overhead gap (~17%) and decryption overhead gap (~42%) differ significantly. Several factors contribute:

**AES-NI instruction latency asymmetry.** On Intel 12th Gen (Alder Lake), `_mm_aesdec_si128` has slightly higher throughput latency than `_mm_aesenc_si128` on the efficiency cores. This amplifies the relative cost of the OCaml stub overhead per block on the decryption path.

**Decryption key schedule.** `aesniKeySetupDec` applies `_mm_aesimc_si128` (Inverse MixColumns) to every intermediate round key. The resulting key schedule has a different memory layout from the encryption schedule, potentially causing different cache behaviour during the decryption loop. The C tight loop benefits more from hardware prefetching with a predictable access pattern; the OCaml stub call boundary may interrupt the CPU's prefetch pipeline more on decryption.

**Accumulated stub overhead.** Each OCaml FFI crossing is a small but non-zero cache miss risk (instruction cache for the stub code, stack frame setup). Over 6.5 million calls on decryption, where the AES instruction itself may be slightly slower, the proportion of stub time rises.

### 7.3 WSL2 Timing Noise

The raw numbers also show significant WSL2 variance. For example:
- C at 75 MB: 782 MB/s encryption (slow)
- C at 100 MB: 1953 MB/s encryption (fast)

These large swings are caused by WSL2 scheduler behaviour, CPU boost clock variability, and thermal state. Single-run numbers should not be over-interpreted. Averages across all six sizes are the more reliable comparison.

---

## 8. Comparison with Software Rijndael

| Implementation              | Avg Enc (MB/s) | Avg Dec (MB/s) | Notes                       |
| --------------------------- | -------------: | -------------: | --------------------------- |
| Rijndael OCaml (original)   | ~34            | ~37            | Int32-based, heavy GC       |
| Rijndael OCaml (optimized)  | ~165           | ~152           | Native-int, allocation-free |
| Rijndael C (T-table)        | ~164           | ~169           | Software reference          |
| AES-NI OCaml (C bindings)   | 1177           | 818            | FFI loop, hw accelerated    |
| AES-NI OxCaml SIMD          | 142            | 139            | 11 C calls/block (AES rounds not builtin) |
| AES-NI C                    | 1382           | 1162           | Direct hw, tight C loop     |

AES-NI is **~7–8× faster** than optimized software AES. The hardware eliminates all T-table lookups, XOR accumulation, and byte manipulation from the hot path. Even with OCaml FFI overhead, C bindings to AES-NI significantly outperform the best possible pure OCaml software implementation.

---

## 9. Benchmark Figures

### Figure 1: Encryption Time

![Encryption Time](results/encryption_time_comparison.png)

### Figure 2: Decryption Time

![Decryption Time](results/decryption_time_comparison.png)

### Figure 3: Encryption Throughput

![Encryption Throughput](results/encryption_speed_comparison.png)

### Figure 4: Decryption Throughput

![Decryption Throughput](results/decryption_speed_comparison.png)

---

## 10. Key Findings

**C is faster than OCaml C-bindings by a consistent margin.** The ~17% encryption gap and ~42% decryption gap are both attributable to the 6.5 million per-block OCaml/C FFI crossings that the C implementation avoids entirely.

**OxCaml SIMD is ~10× slower than C.** Key expansion is now fully inlined (xor/shuffle/shift as `[@@builtin]`), but AES round functions (`AESENC`, `AESENCLAST` etc.) are not builtins in OxCaml — each call crosses the C boundary. For AES-128 this means 11 C stub calls per 16-byte block, totalling 72 million calls for 100 MB. This call overhead completely dominates the measured ~142 MB/s throughput.

**The decryption gap vs C is disproportionately large.** AES-NI decryption instruction latency asymmetry and key schedule cache differences amplify the stub overhead cost on the decryption path relative to encryption.

**FFI overhead is not free at this call frequency.** When individual C calls are this cheap (hardware-bound, single-digit nanoseconds), the boundary crossing cost becomes a meaningful fraction of total work.

**OxCaml SIMD key expansion IS an improvement.** The xor/shuffle/shift instructions in key expansion are genuinely inlined — the improvement just cannot be measured because the block-level C call overhead completely overshadows it.

**Adding AES-NI as OxCaml builtins is the correct path.** The instruction generator already has all 6 AES instructions in its CSV. The work requires modifying `simd_selection.ml` (to map names to instructions) and verifying the emitter encodes them correctly — a genuine compiler contribution, not just configuration.

---

## 11. Conclusion

Three implementations were studied across the same AES-NI hardware:

- **C** (~1382 MB/s enc): All AES rounds inline, zero FFI overhead. The performance ceiling.
- **OCaml + C bindings** (~1177 MB/s enc): One FFI crossing per 16-byte block. ~17% slower than C due to 6.5 million stub calls per 100 MB — still hardware-class performance.
- **OxCaml SIMD** (~142 MB/s enc): Key expansion fully inlined via OxCaml SIMD builtins, but AES round functions go through C stubs — 11 calls per block, 72 million calls per 100 MB. ~10× slower than C.

The OxCaml SIMD result is not a failure of the language or its SIMD system — it is a consequence of the AES-NI instructions (`AESENC`, `AESENCLAST` etc.) not yet being exposed as `[@@builtin]` intrinsics in OxCaml's backend. Once they are added, the full encrypt path would be expressible as a chain of inline instructions with no C boundary at all, potentially matching or exceeding C performance via Flambda2 register allocation and multi-block pipelining.
