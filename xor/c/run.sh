#!/bin/bash

gcc -O3 -march=native benchmark.c xor.c -o benchmark

for file in \
../benchmarks/input_1mb.txt \
../benchmarks/input_10mb.txt \
../benchmarks/input_100mb.txt
do
    echo "================================="
    echo "Testing: $file"
    ./benchmark "$file"
    echo
done