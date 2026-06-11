#!/bin/bash

files=(
  "../benchmarks/input_1mb.txt"
  "../benchmarks/input_10mb.txt"
  "../benchmarks/input_30mb.txt"
  "../benchmarks/input_50mb.txt"
  "../benchmarks/input_75mb.txt"
  "../benchmarks/input_100mb.txt"
)

cd ../ocaml || exit 1

for file in "${files[@]}"
do
    echo "================================="
    echo "Testing: $file"

    dune exec ./benchmark_manual.exe -- "$file"

    echo
done