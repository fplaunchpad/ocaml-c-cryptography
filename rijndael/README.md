# Crypto Comparison: Rijndael AES-128 in C and OCaml

## Project Overview

This project compares implementations of cryptographic primitives across different languages, with a focus on performance and implementation techniques.

The current phase focuses on Rijndael AES-128.

The repository contains:

* Reference C implementation
* Manually translated OCaml implementation
* Benchmark automation scripts
* Result generation
* Performance analysis

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
│   ├── benchmark_rijndael.ml
│   └── dune
│
├── scripts/
│   ├── run_rijndael_c.sh
│   └── run_rijndael_ocaml.sh
│
├── benchmarks/
│   ├── generate_inputs.py
│   └── results/
│       ├── results_rijndael_c.csv
│       ├── results_rijndael_ocaml.csv
│       └── graphs.py
│
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

## Generating Graphs

```bash
python3 generate_graphs.py
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

---

## Verification

Correctness is verified using:

* AES-128 test vectors
* Cross-validation against the C implementation
* Encryption/decryption round-trip testing

---

## Current Status

Completed:

* AES-128 translation
* Key schedule
* Encryption
* Decryption
* Benchmark automation
* Result generation

Planned:

* AES-192 support
* AES-256 support
* Additional cryptographic primitives
* Further optimization studies

---

## Key Result

Average throughput observed:

| Implementation | Encryption Throughput |
| -------------- | --------------------- |
| C              | ~164 MB/s             |
| OCaml          | ~34 MB/s              |

The OCaml implementation achieves approximately 20-25% of the throughput of the optimized C implementation while preserving functional correctness.
