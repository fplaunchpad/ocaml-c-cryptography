#!/bin/bash
set -e
cd "$(dirname "$0")/../ocaml"
opam exec -- dune build 2>/dev/null

OUTPUT="../benchmarks/results/ocaml_results.csv"

echo "InputSizeMB,EncryptTime,DecryptTime,EncryptSpeed,DecryptSpeed" > "$OUTPUT"

for f in \
  ../benchmarks/input_1mb.txt \
  ../benchmarks/input_10mb.txt \
  ../benchmarks/input_30mb.txt \
  ../benchmarks/input_50mb.txt \
  ../benchmarks/input_75mb.txt \
  ../benchmarks/input_100mb.txt
do
    ./_build/default/benchmark_chacha20.exe "$f" ../benchmarks/key.txt ../benchmarks/nonce.txt | awk '
        /Message length/   { mb = $4 / (1024*1024) }
        /Encryption time/  { enc_t = $4 }
        /Decryption time/  { dec_t = $4 }
        /Encryption speed/ { enc_s = $4 }
        /Decryption speed/ { dec_s = $4 }
        /Correctness/      { printf "%.0f,%.6f,%.6f,%.2f,%.2f\n", mb, enc_t, dec_t, enc_s, dec_s }
    ' >> "$OUTPUT"
done

echo "Results written to $OUTPUT"
