#!/bin/bash
# Benchmark the OxCaml SIMD AES-NI implementation.
# Key expansion uses OxCaml SIMD builtins (xor/shuffle/shift inlined).
# AES round functions go through C stubs (not yet builtins in OxCaml).

set -e

eval $(opam env)
export PATH="$HOME/.local/oxcaml/bin:$PATH"

cd "$(dirname "$0")/../oxcaml" || exit 1
dune build 2>/dev/null

OUTPUT="../benchmarks/results/oxcaml_simd_results.csv"

echo "InputSizeMB,EncryptTime,DecryptTime,EncryptSpeed,DecryptSpeed" > "$OUTPUT"

for f in \
  ../benchmarks/input_1mb.txt \
  ../benchmarks/input_10mb.txt \
  ../benchmarks/input_30mb.txt \
  ../benchmarks/input_50mb.txt \
  ../benchmarks/input_75mb.txt \
  ../benchmarks/input_100mb.txt
do
  ./_build/default/benchmark_aesni.exe "$f" >> "$OUTPUT"
done

echo "Results written to $OUTPUT"
