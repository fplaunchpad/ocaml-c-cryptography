#!/bin/bash

cd ../oxcaml || exit 1
dune build 2>/dev/null

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
    ./_build/default/benchmark_aesni.exe "$f" >> "$OUTPUT"
done
