# AES-128 Benchmark

## Objective

The goal of this benchmark is to compare a handwritten AES-128 implementation in C with the AES implementation provided by the Cryptokit library in OCaml with respect to:

* Execution performance
* Correctness
* Encryption and decryption efficiency
* Educational versus production-quality implementations
* Practical cryptographic software development

---

## Benchmark Setup

### AES Configuration

* AES Variant:
  AES-128

* Block Size:
  16 bytes (128 bits)

* Number of Iterations:
  1,000,000

* Key:

```text
0123456789abcdef
```

---

## Compilation Commands

### C

```bash
gcc -O2 benchmark_aes.c aes.c -o benchmark_aes
```

### OCaml / Cryptokit

```bash
ocamlfind ocamlopt \
  -package cryptokit \
  -linkpkg \
  aes_cryptokit.ml \
  -o aes_cryptokit
```

---

## Execution Commands

### C

```bash
./benchmark_aes
```

### OCaml / Cryptokit

```bash
./aes_cryptokit
```

---

## Benchmark Results

| Implementation      | Encryption Time | Decryption Time |
| ------------------- | --------------- | --------------- |
| AES-128 (C)         | 0.286647 s      | 0.868854 s      |
| AES-128 (Cryptokit) | 0.066431 s      | 0.052843 s      |

---

## Throughput

A total of:

```text
1,000,000 × 16 bytes
= 16,000,000 bytes
```

were processed during each benchmark.

| Implementation      | Encryption Throughput | Decryption Throughput |
| ------------------- | --------------------- | --------------------- |
| AES-128 (C)         | 55.8 MB/s             | 18.4 MB/s             |
| AES-128 (Cryptokit) | 240.9 MB/s            | 302.8 MB/s            |

---

## Important Observations

### 1. Handwritten AES Implementation

The C implementation was developed entirely from scratch and includes:

* AddRoundKey
* SubBytes
* ShiftRows
* MixColumns
* Key Expansion
* AES Encryption
* AES Decryption

The implementation prioritizes clarity and educational value over raw performance.

---

### 2. Cryptokit Performance

The Cryptokit library significantly outperformed the handwritten implementation.

Measured speedups were approximately:

* 4.3× faster encryption
* 16.4× faster decryption

This demonstrates the benefit of highly optimized cryptographic libraries.

---

### 3. Encryption vs Decryption

The handwritten implementation showed noticeably slower decryption performance.

This is largely due to the complexity of the inverse MixColumns operation, which requires finite-field multiplications by:

```text
9, 11, 13, and 14
```

compared to the simpler multiplications by:

```text
2 and 3
```

used during encryption.

---

### 4. Library Optimization

Cryptokit maintains similar performance for both encryption and decryption.

This suggests the use of heavily optimized AES routines, lookup tables, and implementation techniques that reduce the cost of inverse operations.

---

## Correctness Verification

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

The decrypted output matched the original plaintext in both implementations.

---

## Conclusion

This benchmark demonstrates the difference between an educational cryptographic implementation and a production-quality cryptographic library.

The handwritten AES implementation provides valuable insight into the internal workings of AES-128, including key expansion, finite-field arithmetic, and round transformations.

Cryptokit, on the other hand, delivers substantially better performance and is more suitable for real-world applications where efficiency and reliability are critical.

The experiment highlights the importance of optimized cryptographic libraries while reinforcing a practical understanding of AES through manual implementation.
