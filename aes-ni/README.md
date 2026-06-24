# AES-NI: Hardware-Accelerated AES in C, OCaml, and OxCaml SIMD

## Project Overview

This project benchmarks AES-128 using Intel's AES-NI hardware instruction set across three implementations:

1. **Pure C** — direct inline AES-NI intrinsics, zero overhead
2. **OCaml + C bindings** — OCaml drives a per-block C stub (Cryptokit pattern by Xavier Leroy, INRIA)
3. **OxCaml SIMD** — key expansion rewritten using OxCaml's native SIMD builtins; AES round functions still via C stubs (not yet builtins in OxCaml)

The central question is: **how much overhead does OCaml introduce when acting as a driver over AES-NI hardware instructions, and can OxCaml's native SIMD close that gap?**

---

## Why OCaml Uses C Bindings — and What OxCaml SIMD Changed

OxCaml (Jane Street's performance-focused OCaml fork) exposes native SIMD types and `[@@builtin]` intrinsics that compile to single machine instructions with no function call overhead. We used these for **key expansion**:

| OxCaml builtin                      | x86 instruction | Used for        |
| ------------------------------------ | --------------- | --------------- |
| `caml_sse_vec128_xor`                | `PXOR`          | Key XOR         |
| `caml_sse_vec128_shuffle_32`         | `SHUFPS`        | Key rotation    |
| `caml_sse2_vec128_shift_left_bytes`  | `PSLLDQ`        | Key shift       |
| `caml_sse2_vec128_shuffle_64`        | `SHUFPD`        | 192-bit key mix |
| `%caml_bytes_getu128u` / `setu128u`  | inline load/store | Block I/O     |

However, the six AES-specific round instructions are **not yet builtins** in OxCaml:

| Missing from OxCaml         | x86 instruction   | Purpose                |
| ---------------------------- | ----------------- | ---------------------- |
| `AESENC`                     | encryption round  | Hot path — 10×/block   |
| `AESENCLAST`                 | final enc round   | Hot path — 1×/block    |
| `AESDEC`                     | decryption round  | Hot path — 10×/block   |
| `AESDECLAST`                 | final dec round   | Hot path — 1×/block    |
| `AESIMC`                     | inv. mix columns  | Key setup only         |
| `AESKEYGENASSIST`            | key schedule      | Key setup only         |

These were exposed as `[@@noalloc]` C stubs. The result: for AES-128, `encrypt_block` makes **11 C function calls per 16-byte block** instead of 1, totalling 72 million stub calls for 100 MB — making OxCaml SIMD ~10× slower than C and even slower than plain OCaml C-bindings. See BENCHMARK.md section 6 for the full analysis.

---

## What Was Built

### C Benchmark (`c/`)

- `aesni.c` / `aesni.h` — AES-NI implementation from the Cryptokit library (Xavier Leroy, INRIA)
- `benchmark_aesni.c` — standalone benchmark: reads a file, encrypts block-by-block, decrypts, verifies, reports timing

### OxCaml Benchmark (`oxcaml/`)

- `aesni_stubs.c` — C stub layer:
  - High-level stubs (Cryptokit pattern): `caml_aes_cook_encrypt_key`, `caml_aes_cook_decrypt_key`, `caml_aes_encrypt`, `caml_aes_decrypt`, `caml_aesni_check`
  - Raw AES-NI round stubs for OxCaml: `caml_aesni_aesenc`, `caml_aesni_aesenclast`, `caml_aesni_aesdec`, `caml_aesni_aesdeclast`, `caml_aesni_aesimc`, `caml_aesni_keygenassist`
  - `[@@builtin]` linker stubs: `caml_sse_vec128_xor`, `caml_sse_vec128_shuffle_32`, `caml_sse2_vec128_shift_left_bytes`, `caml_sse2_vec128_shuffle_64`
- `aesni.ml` — full OxCaml SIMD implementation:
  - Key expansion (`cook_encrypt_key`, `cook_decrypt_key`) using OxCaml SIMD builtins — fully inlined, no C calls
  - Block encrypt/decrypt using C stubs for AES round instructions
  - Supports AES-128, AES-192, AES-256 (dispatches on `nr`)
- `dune` — build file with `-extension simd_beta` flag for OxCaml SIMD types
- `benchmark_aesni.ml` — benchmark driver: reads a file, drives block loop from OCaml

### Scripts (`scripts/`)

- `run_aesni_c.sh` — runs the C benchmark, writes `benchmarks/results/c_results.csv`
- `run_aesni_ocaml.sh` — builds and runs the OCaml C-bindings benchmark, writes `benchmarks/results/ocaml_results.csv`
- `run_aesni_oxcaml_simd.sh` — builds and runs the OxCaml SIMD benchmark, writes `benchmarks/results/oxcaml_simd_results.csv`

### Benchmarks (`benchmarks/`)

- `results/c_results.csv` — C benchmark results
- `results/ocaml_results.csv` — OCaml C-bindings results
- `results/oxcaml_simd_results.csv` — OxCaml SIMD results
- `results/graphs.py` — generates 4 comparison plots across all 3 implementations

---

## Project Structure

```text
aes-ni/
├── c/
│   ├── aesni.c                      # AES-NI implementation (Cryptokit / Xavier Leroy)
│   ├── aesni.h
│   ├── benchmark_aesni.c            # Standalone C benchmark
│   └── benchmark_aesni              # Compiled binary
│
├── oxcaml/
│   ├── aesni_stubs.c                # C stubs: high-level + raw AES-NI + builtin symbols
│   ├── aesni.ml                     # OxCaml SIMD AES implementation
│   ├── benchmark_aesni.ml           # Benchmark driver
│   ├── dune                         # Build file (-extension simd_beta)
│   └── dune-project
│
├── scripts/
│   ├── run_aesni_c.sh               # Run C benchmark
│   ├── run_aesni_ocaml.sh           # Run OCaml C-bindings benchmark
│   └── run_aesni_oxcaml_simd.sh     # Run OxCaml SIMD benchmark
│
└── benchmarks/
    ├── input_1mb.txt
    ├── input_10mb.txt
    ├── input_30mb.txt
    ├── input_50mb.txt
    ├── input_75mb.txt
    ├── input_100mb.txt
    ├── generate_inputs.py
    └── results/
        ├── c_results.csv
        ├── ocaml_results.csv
        ├── oxcaml_simd_results.csv
        ├── graphs.py
        ├── encryption_time_comparison.png
        ├── decryption_time_comparison.png
        ├── encryption_speed_comparison.png
        └── decryption_speed_comparison.png
```

---

## Running Benchmarks

All scripts must be run from the `scripts/` directory.

### C Benchmark

```bash
cd scripts
./run_aesni_c.sh
```

Output: `benchmarks/results/c_results.csv`

---

### OCaml C-Bindings Benchmark

```bash
cd scripts
./run_aesni_ocaml.sh
```

Output: `benchmarks/results/ocaml_results.csv`

> The script calls `dune build` automatically before running.

---

### OxCaml SIMD Benchmark

Requires OxCaml installed at `~/.local/oxcaml/` and `dune` available via opam.

```bash
cd scripts
./run_aesni_oxcaml_simd.sh
```

Output: `benchmarks/results/oxcaml_simd_results.csv`

> The script sets `PATH` to use OxCaml's `ocamlopt` and calls `dune build` with `-extension simd_beta`.

To run a single file manually:

```bash
eval $(opam env)
export PATH=$HOME/.local/oxcaml/bin:$PATH
cd oxcaml
dune build
./_build/default/benchmark_aesni.exe ../benchmarks/input_10mb.txt
```

---

### Build OCaml manually

```bash
cd oxcaml
dune build
./_build/default/benchmark_aesni.exe ../benchmarks/input_100mb.txt
```

---

### Recompile the C benchmark binary

```bash
cd c
gcc -O3 -maes -o benchmark_aesni benchmark_aesni.c aesni.c
```

> The `-maes` flag is required to enable AES-NI instruction emission.

---

## Generating Graphs

```bash
cd benchmarks/results
python3 graphs.py
```

Generated outputs (all 3 implementations):

- `encryption_time_comparison.png`
- `decryption_time_comparison.png`
- `encryption_speed_comparison.png`
- `decryption_speed_comparison.png`

---

## Generating Benchmark Inputs

```bash
python3 benchmarks/generate_inputs.py
```

Generates input files from 1 MB to 100 MB.

---

## Verification

Correctness is verified in all implementations by:

- Encrypting the padded input
- Decrypting the ciphertext
- Comparing the decrypted output byte-for-byte against the original input

All benchmarks exit with an error if verification fails.

---

## Results Summary

Full benchmark results, analysis, and reasoning are in [BENCHMARK.md](BENCHMARK.md).

| Input (MB) | C Enc (MB/s) | OCaml Enc (MB/s) | OxCaml SIMD Enc (MB/s) | C Dec (MB/s) | OCaml Dec (MB/s) | OxCaml SIMD Dec (MB/s) |
| ---------- | -----------: | ----------------: | ----------------------: | -----------: | ----------------: | ----------------------: |
| 1          | 1694         | 984               | 96                      | 1346         | 1093              | 130                     |
| 10         | 1239         | 1176              | 146                     | 1510         | 1082              | 139                     |
| 30         | 1159         | 1149              | 146                     | 856          | 578               | 139                     |
| 50         | 1466         | 1125              | 141                     | 1046         | 751               | 144                     |
| 75         | 782          | 1337              | 141                     | 955          | 673               | 144                     |
| 100        | 1953         | 1288              | 145                     | 1262         | 729               | 139                     |

**Average throughput:**

| Implementation     | Avg Enc (MB/s) | Avg Dec (MB/s) |
| ------------------ | -------------: | -------------: |
| C (AES-NI)         | ~1382          | ~1162          |
| OCaml + C bindings | ~1177          | ~818           |
| OxCaml SIMD        | ~142           | ~139           |

OxCaml SIMD is slower than plain OCaml C-bindings because the original OCaml calls C once per block (all rounds inside C), while the OxCaml version calls C once per round (11 calls per block). See BENCHMARK.md section 6 for the full analysis.

---

## References

- AES-NI implementation: [Cryptokit by Xavier Leroy (INRIA)](https://github.com/xavierleroy/cryptokit)
- OCaml C stub structure: `stubs-aes.c` from Cryptokit
- OxCaml SIMD documentation: [oxcaml.org/documentation](https://oxcaml.org/documentation/)
- Intel AES-NI reference: Intel® Advanced Encryption Standard (AES) New Instructions Set
