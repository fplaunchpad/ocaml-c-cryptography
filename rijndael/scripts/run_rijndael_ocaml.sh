#!/bin/bash

cd ../ocaml || exit 1

dune build benchmark_rijndael.exe

CSV="../benchmarks/results/results_rijndael_ocaml.csv"

echo "size_mb,enc_time,dec_time,enc_speed,dec_speed" > "$CSV"

FILES=(
  "../benchmarks/input_1mb.txt"
  "../benchmarks/input_10mb.txt"
  "../benchmarks/input_30mb.txt"
  "../benchmarks/input_50mb.txt"
  "../benchmarks/input_75mb.txt"
  "../benchmarks/input_100mb.txt"
)

for file in "${FILES[@]}"
do
  dune exec ./benchmark_rijndael.exe "$file" >> "$CSV"
done

echo "Results written to $CSV"