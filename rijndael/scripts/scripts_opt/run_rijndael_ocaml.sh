#!/bin/bash

ROOT=$(realpath "$(dirname "$0")/../..")

OUTPUT="$ROOT/benchmarks/results_opt/results_rijndael_ocaml.csv"

echo "size_mb,enc_time,dec_time,enc_speed,dec_speed" > "$OUTPUT"

cd "$ROOT/ocaml" || exit

for size in 1 10 30 50 75 100
do
    dune exec ./benchmark_rijndael.exe \
      "$ROOT/benchmarks/input_${size}mb.txt" \
      >> "$OUTPUT"
done