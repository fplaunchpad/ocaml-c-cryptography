# Cryptographic Algorithm Comparison: C, OCaml, and Cryptokit

## Introduction

This project investigates the implementation and performance of cryptographic algorithms across different programming environments.

Two cryptographic schemes were studied:

1. XOR Cipher
2. AES-128

The project compares:

* XOR Cipher implemented in C
* XOR Cipher implemented in OCaml
* AES-128 implemented manually in C
* AES-128 implemented using the Cryptokit library

The objective is to evaluate correctness, performance, and implementation complexity while understanding the difference between educational implementations and optimized cryptographic libraries.

---

# XOR Cipher

## Overview

The XOR cipher is a simple symmetric encryption algorithm where each plaintext byte is XORed with a key byte.

Encryption:

```text
ciphertext = plaintext XOR key
```

Decryption:

```text
plaintext = ciphertext XOR key
```

Since XOR is its own inverse, the same operation is used for both encryption and decryption.

---

## Benchmark Results

| Language | Execution Time | Correctness |
| -------- | -------------- | ----------- |
| C        | 0.031 s        | True        |
| OCaml    | 0.038 s        | True        |

### Observations

* C achieved slightly better performance.
* OCaml performance remained close to optimized C.
* OCaml provided safer handling of binary data.
* Native compilation using `ocamlopt` significantly improved OCaml performance.

---

# AES-128

## Overview

AES (Advanced Encryption Standard) is a symmetric block cipher standardized by NIST.

AES-128 operates on:

* 128-bit blocks
* 128-bit keys
* 10 rounds

Each encryption round performs:

1. SubBytes
2. ShiftRows
3. MixColumns
4. AddRoundKey

The final round omits MixColumns.

---

## Manual AES Implementation

A complete AES-128 implementation was developed from scratch in C.

Implemented components:

* AddRoundKey
* SubBytes
* ShiftRows
* MixColumns
* Key Expansion
* AES Encryption
* AES Decryption

Correctness was verified by ensuring:

```text
Plaintext
    ↓
Encryption
    ↓
Ciphertext
    ↓
Decryption
    ↓
Original Plaintext
```

---

## AES Benchmark Results

| Implementation      | Encryption Time | Decryption Time |
| ------------------- | --------------- | --------------- |
| AES-128 (C)         | 0.286647 s      | 0.868854 s      |
| AES-128 (Cryptokit) | 0.066431 s      | 0.052843 s      |

---

## Throughput

| Implementation      | Encryption Throughput | Decryption Throughput |
| ------------------- | --------------------- | --------------------- |
| AES-128 (C)         | 55.8 MB/s             | 18.4 MB/s             |
| AES-128 (Cryptokit) | 240.9 MB/s            | 302.8 MB/s            |

---

# Graph 1: Encryption Time Comparison

Insert:

```text
encryption_time_comparison.png
```

This graph compares:

* XOR (C)
* XOR (OCaml)
* AES (C)
* AES (Cryptokit)

and highlights the higher computational cost of AES compared to XOR.

---

# Graph 2: AES Encryption vs Decryption

Insert:

```text
aes_encrypt_decrypt.png
```

This graph compares encryption and decryption performance for:

* Handwritten AES implementation
* Cryptokit AES implementation

The graph demonstrates the significant decryption overhead in the handwritten implementation.

---

# Graph 3: Throughput Comparison

Insert:

```text
throughput_comparison.png
```

This graph compares encryption and decryption throughput for both AES implementations.

---

# Discussion

The XOR cipher demonstrated that native-compiled OCaml can achieve performance comparable to optimized C while providing stronger safety guarantees.

The AES benchmark highlighted the difference between a manually implemented cryptographic algorithm and a production-quality cryptographic library.

The handwritten AES implementation successfully demonstrated the internal operations of AES, including finite-field arithmetic, key expansion, and inverse transformations.

Cryptokit achieved significantly higher performance due to implementation-level optimizations and efficient cryptographic routines.

---

# Conclusion

This project successfully implemented and benchmarked XOR and AES cryptographic algorithms across multiple environments.

Key findings include:

* XOR performance in OCaml is close to optimized C.
* AES is substantially more computationally intensive than XOR.
* Cryptokit encryption is approximately 4.3× faster than the handwritten AES implementation.
* Cryptokit decryption is approximately 16.4× faster than the handwritten AES implementation.
* Educational implementations are valuable for understanding cryptographic algorithms, while optimized libraries are preferable for real-world deployment.

The project demonstrates both the theoretical foundations of cryptography and the practical benefits of optimized cryptographic libraries.
