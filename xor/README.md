# XOR Cryptography: C vs OCaml Comparison

## Overview

This project implements the XOR cipher in both C and OCaml and compares their performance using identical benchmark inputs.

The project evaluates:

* Encryption correctness
* Decryption correctness
* Execution time
* Throughput (MB/s)

## Project Structure

```text
xor/
├── benchmarks/
│   ├── generate_inputs.py
│   ├── BENCHMARK.md
│   └── results/
│
├── c/
│   ├── benchmark.c
│   ├── xor.c
│   └── xor.h
│
├── ocaml/
│   ├── benchmark.ml
│   ├── xor.ml
│   ├── dune
│   └── dune-project
│
├── scripts/
│   ├── run_c.sh
│   └── run_ocaml.sh
│
└── README.md
```

## Generate Benchmark Inputs

```bash
cd benchmarks
python3 generate_inputs.py
```

This generates:

* input_1mb.txt
* input_10mb.txt
* input_100mb.txt
* key.txt

## Run C Benchmark

```bash
./scripts/run_c.sh
```

## Run OCaml Benchmark

```bash
./scripts/run_ocaml.sh
```

## Benchmark Results

Detailed benchmark methodology, results, graphs, and observations are available in:

```text
benchmarks/BENCHMARK.md
```
