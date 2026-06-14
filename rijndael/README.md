# Crypto Comparison: Rijndael AES-128 in C and OCaml

## Project Overview

This project compares implementations of cryptographic primitives across different languages, with a focus on performance and implementation techniques.

The current phase focuses on Rijndael AES-128, including implementation, benchmarking, correctness validation, and performance optimization of an OCaml translation of the reference C implementation.

The repository contains:

* Reference C implementation
* Manually translated OCaml implementation
* Benchmark automation scripts
* Result generation
* Performance analysis
* Optimized OCaml implementation
* Optimization benchmark results

---

## Objectives

* Understand low-level cryptographic implementations
* Translate optimized C cryptographic code into OCaml
* Verify correctness using standard test vectors
* Compare performance characteristics
* Analyze runtime overhead between languages

---

## Implemented Features

### AES-128 Key Expansion

* Encryption key schedule
* Decryption key schedule

### AES-128 Encryption

* T-table based implementation
* Initial AddRoundKey
* Full AES rounds
* Final round

### AES-128 Decryption

* Inverse T-table implementation
* Inverse key schedule processing
* Final inverse round

### Benchmarking

Benchmark execution for:

* 1 MB
* 10 MB
* 30 MB
* 50 MB
* 75 MB
* 100 MB

Metrics collected:

* Encryption time
* Decryption time
* Encryption throughput
* Decryption throughput

---

## Project Structure

```text
rijndael/
├── c/
│   ├── rijndael-alg-fst.c
│   ├── benchmark_rijndael.c
│   └── rijndael-alg-fst.h
│
├── ocaml/
│   ├── rijndael_fst.ml
│   ├── rijndael_fst_opt.ml
│   ├── benchmark_rijndael.ml
│   ├── benchmark_rijndael_opt.ml
│   └── dune
│
├── scripts/
│   ├── run_rijndael_c.sh
│   └── run_rijndael_ocaml.sh
│   └── scripts_opt/
│       ├── run_rijndael_c.sh
│       ├── run_rijndael_ocaml.sh
│       └── run_rijndael_ocaml_opt.sh
│
├── benchmarks/
│   ├── generate_inputs.py
│   ├── results/
│   └── results_opt/
│
├── BENCHMARK.md
├── BENCHMARK_OPT.md
└── README.md
```

---

## Running Benchmarks

### C

```bash
cd scripts
./run_rijndael_c.sh
```

Results:

```text
benchmarks/results/results_rijndael_c.csv
```

---

### OCaml

```bash
cd scripts
./run_rijndael_ocaml.sh
```

Results:

```text
benchmarks/results/results_rijndael_ocaml.csv
```

---

### Optimized Benchmark Suite

```bash
cd scripts/scripts_opt

./run_rijndael_c.sh
./run_rijndael_ocaml.sh
./run_rijndael_ocaml_opt.sh
```

Results:

```text
benchmarks/results_opt/
```

---

## Generating Graphs

```bash
python3 graphs.py
```

Generated outputs:

* encryption_time_comparison.png
* decryption_time_comparison.png
* encryption_speed_comparison.png
* decryption_speed_comparison.png

---

## Generating Benchmark Inputs

Benchmark input files can be generated using:

```bash
python3 benchmarks/generate_inputs.py
```

---

## Verification

Correctness is verified using:

* AES-128 test vectors
* Cross-validation against the C implementation
* Encryption/decryption round-trip validation on benchmark inputs
* Verification of inputs whose lengths are not multiples of 16 bytes using temporary padding-based tests
* Cross-validation between original and optimized OCaml implementations

---

## Benchmark Reports

- BENCHMARK.md – Baseline comparison between the reference C implementation and the original OCaml implementation.
- BENCHMARK_OPT.md – Optimization study documenting performance improvements, validation methodology, and final comparison between C, original OCaml, and optimized OCaml implementations.

---

## Current Status

Completed:

* AES-128 translation from C to OCaml
* Encryption and decryption support
* Key expansion
* AES test vector validation
* Cross-validation against C implementation
* Benchmark automation
* Performance analysis
* OCaml optimization study
* Result and graph generation

Planned:

* AES-192 support
* AES-256 support
* Additional cryptographic primitives
* Further optimization studies

---

## Results Summary

Detailed benchmark results, optimization history, graphs, and analysis are available in:

- BENCHMARK.md
- BENCHMARK_OPT.md
