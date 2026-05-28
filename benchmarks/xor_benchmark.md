# XOR Cipher Benchmark

## Objective

The goal of this benchmark is to compare XOR cipher implementations in C and OCaml/OxCaml with respect to:

* Execution performance
* Correctness
* Binary data handling
* Memory safety
* Functional vs imperative implementation style

---

## Benchmark Setup

### Input

* Base string:
  `CryptographyAndFunctionalProgrammingResearch123`

* Repeated:
  `100000` times

* Total message length:
  `4700000` characters

* Key:
  `securekey`

---

## Compilation Commands

### C

```bash
gcc -O2 xor_cipher.c -o xor
```

### OCaml

```bash
ocamlopt xor_cipher.ml -o xor_ocaml
```

---

## Execution Commands

### C

```bash
time ./xor
```

### OCaml

```bash
time ./xor_ocaml
```

---

## Benchmark Results

| Language                | Execution Time | Correctness |
| ----------------------- | -------------- | ----------- |
| C                       | ~0.031s        | true        |
| OCaml (native compiled) | ~0.038s        | true        |

---

## Important Observations

### 1. Initial misleading benchmark results

Earlier benchmarks incorrectly suggested OCaml was significantly faster than C.

Investigation revealed that the C implementation used repeated `strcat()` operations inside a loop, leading to inefficient `O(n²)` string construction.

Replacing `strcat()` with `memcpy()` improved performance substantially.

---

### 2. Effect of native compilation

Running OCaml through the interpreter was significantly slower.

Using `ocamlopt` generated native machine code and improved execution speed dramatically.

---

### 3. Binary data handling differences

XOR encryption generates arbitrary binary bytes, including possible null (`'\0'`) bytes.

Initial C implementations incorrectly treated encrypted data as null-terminated strings, causing incorrect decryption validation.

Manual byte-by-byte comparison fixed the issue.

OCaml handled binary string data more safely and naturally due to higher-level string abstractions.

---

### 4. Performance comparison

After optimization and correctness fixes:

* C achieved slightly better raw performance
* OCaml performance remained surprisingly close to optimized C
* OCaml provided safer and cleaner handling of encrypted binary data

---

## Conclusion

This experiment demonstrates that native-compiled OCaml can achieve competitive performance for simple cryptographic workloads while also providing safer abstractions for binary data handling compared to low-level C implementations.
