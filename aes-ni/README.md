# AES-NI: Hardware-Accelerated AES-128 in C and OCaml

## Project Overview

This project benchmarks AES-128 using Intel's AES-NI hardware instruction set, comparing a pure C implementation against an OCaml implementation that calls into C via FFI bindings.

Unlike the Rijndael directory (which translates the AES algorithm into OCaml in software), this directory targets the hardware acceleration path. The central question is: **how much overhead does OCaml introduce when acting as a driver over AES-NI hardware instructions?**

The OCaml bindings are structured after the [Cryptokit library](https://github.com/xavierleroy/cryptokit) by Xavier Leroy (INRIA), the canonical OCaml cryptography library.

---

## Why OCaml Uses C Bindings Here

A natural question is: why not translate the AES-NI operations directly into OCaml, as was done for Rijndael?

The answer is that **OxCaml's SIMD library does not expose AES-NI instructions**.

OxCaml's `ocaml_simd_sse` library provides general-purpose SSE/AVX2 vector types (`Int8x16`, `Int32x4`, `Float64x2`, etc.) with general operations such as `lxor`, `land`, `add`, `shuffle`. However, the six AES-specific hardware instructions:

| Instruction                   | Purpose                          |
| ----------------------------- | -------------------------------- |
| `_mm_aesenc_si128`            | AES encryption round             |
| `_mm_aesenclast_si128`        | AES encryption final round       |
| `_mm_aesdec_si128`            | AES decryption round             |
| `_mm_aesdeclast_si128`        | AES decryption final round       |
| `_mm_aeskeygenassist_si128`   | Key schedule generation          |
| `_mm_aesimc_si128`            | Inverse mix columns              |

are not present in OxCaml. These belong to the AES-NI CPU extension (`wmmintrin.h`), which is separate from SSE/AVX2 and is not yet covered by OxCaml's intrinsics library.

A pure OCaml translation without AES-NI would simply reproduce the software Rijndael implementation, already benchmarked in the `rijndael/` directory. That comparison is already done and is very slow (~34 MB/s unoptimized).

Therefore, OCaml C bindings are the only meaningful path for benchmarking AES-NI from OCaml.

---

## What Was Built

### C Benchmark (`c/`)

* `aesni.c` / `aesni.h` — AES-NI implementation from the Cryptokit library (Xavier Leroy, INRIA)
* `benchmark_aesni.c` — standalone benchmark: reads a file, encrypts block-by-block using AES-NI, decrypts, verifies, reports timing

### OCaml Benchmark (`oxcaml/`)

* `aesni_stubs.c` — C stub layer following the Cryptokit convention:
  * `caml_aes_cook_encrypt_key` / `caml_aes_cook_decrypt_key` — expand the raw key into a 241-byte OCaml string (240 bytes of AES round keys + 1 byte storing `nr`)
  * `caml_aes_encrypt` / `caml_aes_decrypt` — encrypt or decrypt one 16-byte block per call (5 arguments, no GC allocation)
* `aesni.ml` — OCaml `external` declarations
* `benchmark_aesni.ml` — OCaml driver: reads a file, drives the block loop from OCaml, calls C for each 16-byte block, reports timing

### Scripts (`scripts/`)

* `run_aesni_c.sh` — runs the C benchmark across all input sizes, writes `benchmarks/results/c_results.csv`
* `run_aesni_ocaml.sh` — builds the OCaml project and runs it across all input sizes, writes `benchmarks/results/ocaml_results.csv`

### Benchmarks (`benchmarks/`)

* `results/c_results.csv` — C benchmark results
* `results/ocaml_results.csv` — OCaml benchmark results
* `results/graphs.py` — generates comparison plots

---

## Project Structure

```text
aes-ni/
├── c/
│   ├── aesni.c                  # AES-NI implementation (Cryptokit / Xavier Leroy)
│   ├── aesni.h                  # AES-NI header
│   ├── benchmark_aesni.c        # Standalone C benchmark
│   └── benchmark_aesni          # Compiled binary
│
├── oxcaml/
│   ├── aesni_stubs.c            # OCaml C bindings (Cryptokit pattern)
│   ├── aesni.ml                 # OCaml external declarations
│   ├── benchmark_aesni.ml       # OCaml benchmark driver
│   ├── dune                     # Build file
│   └── dune-project
│
├── scripts/
│   ├── run_aesni_c.sh           # Run C benchmark
│   └── run_aesni_ocaml.sh       # Build and run OCaml benchmark
│
└── benchmarks/
    ├── input_1mb.txt
    ├── input_10mb.txt
    ├── input_30mb.txt
    ├── input_50mb.txt
    ├── input_75mb.txt
    ├── input_100mb.txt
    ├── key.txt
    ├── generate_inputs.py
    └── results/
        ├── c_results.csv
        ├── ocaml_results.csv
        └── graphs.py
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

### OCaml Benchmark

```bash
cd scripts
./run_aesni_ocaml.sh
```

Output: `benchmarks/results/ocaml_results.csv`

> The script calls `dune build` automatically before running.

---

### Build OCaml manually

```bash
cd oxcaml
dune build
```

Run a single file directly:

```bash
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

Generated outputs:

* `encryption_time_comparison.png`
* `decryption_time_comparison.png`
* `encryption_speed_comparison.png`
* `decryption_speed_comparison.png`

---

## Generating Benchmark Inputs

```bash
python3 benchmarks/generate_inputs.py
```

Generates input files from 1 MB to 100 MB.

---

## Verification

Correctness is verified in both implementations by:

* Encrypting the padded input
* Decrypting the ciphertext
* Comparing the decrypted output byte-for-byte against the original input

Both C and OCaml benchmarks exit with an error if verification fails.

---

## Results Summary

Full benchmark results, analysis, and reasoning are in [BENCHMARK.md](BENCHMARK.md).

| Input (MB) | C Enc (MB/s) | OCaml Enc (MB/s) | C Dec (MB/s) | OCaml Dec (MB/s) |
| ---------- | -----------: | ----------------: | -----------: | ----------------: |
| 1          | 1694         | 984               | 1346         | 1093              |
| 10         | 1239         | 1176              | 1510         | 1082              |
| 30         | 1159         | 1149              | 856          | 578               |
| 50         | 1466         | 1125              | 1046         | 751               |
| 75         | 782          | 1337              | 955          | 673               |
| 100        | 1953         | 1288              | 1262         | 729               |

C is faster overall: ~1382 MB/s vs ~1177 MB/s average encryption, ~1162 MB/s vs ~818 MB/s average decryption. The gap comes from OCaml's per-block FFI call overhead — see BENCHMARK.md for the full analysis.

---

## References

* AES-NI implementation: [Cryptokit by Xavier Leroy (INRIA)](https://github.com/xavierleroy/cryptokit)
* OCaml C stub structure: `stubs-aes.c` from Cryptokit
* OxCaml SIMD documentation: [oxcaml.org/documentation/simd/intro](https://oxcaml.org/documentation/simd/intro/)
* Intel AES-NI reference: Intel® Advanced Encryption Standard (AES) New Instructions Set
