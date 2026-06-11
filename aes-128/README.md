# AES-128 Implementation and Benchmarking

## Overview

This project implements the AES-128 encryption algorithm in both C and OCaml and compares their performance through benchmarking.

The implementation includes:

* AES-128 Key Expansion
* AES-128 Encryption
* AES-128 Decryption
* Verification of decrypted output
* Performance benchmarking on multiple input sizes

## Project Structure

```text
aes/
├── benchmarks/
│   ├── results/
│   ├── generate_inputs.py
│   ├── input_1mb.txt
│   ├── input_10mb.txt
│   ├── input_30mb.txt
│   ├── input_50mb.txt
│   ├── input_75mb.txt
│   ├── input_100mb.txt
│   └── key.txt
│
├── c/
│   ├── aes_manual.c
│   ├── aes_manual.h
│   ├── benchmark_manual.c
│   └── benchmark_manual
│
├── ocaml/
│   ├── aes_manual.ml
│   ├── aes_manual.mli
│   ├── benchmark_manual.ml
│   ├── dune
│   └── dune-project
│
├── scripts/
│   ├── run_aes_manual_c.sh
│   └── run_aes_manual_ocaml.sh
│
└── .gitignore
```

## Building

### C Implementation

```bash
cd c
gcc benchmark_manual.c aes_manual.c -o benchmark_manual
```

### OCaml Implementation

```bash
cd ocaml
dune build
```

## Running Benchmarks

### C

```bash
cd scripts
./run_aes_manual_c.sh
```

### OCaml

```bash
cd scripts
./run_aes_manual_ocaml.sh
```

## Benchmark Inputs

The following datasets are used:

* 1 MB
* 10 MB
* 30 MB
* 50 MB
* 75 MB
* 100 MB

## Metrics Collected

* Encryption Time (seconds)
* Decryption Time (seconds)
* Encryption Throughput (MB/s)
* Decryption Throughput (MB/s)

## Verification

For every benchmark:

1. Plaintext is encrypted.
2. Ciphertext is decrypted.
3. Original plaintext and decrypted plaintext are compared.
4. Benchmark is considered valid only if verification passes.

All benchmark runs completed successfully with verification status PASSED.
