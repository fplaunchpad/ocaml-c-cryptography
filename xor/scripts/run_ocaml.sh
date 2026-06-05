#!/bin/bash

cd "$(dirname "$0")/../ocaml" || exit

dune build

for file in \
../benchmarks/input_1mb.txt \
../benchmarks/input_10mb.txt \
../benchmarks/input_100mb.txt
do
    echo "================================="
    echo "Testing: $file"
    dune exec ./benchmark.exe -- "$file"
    echo
done