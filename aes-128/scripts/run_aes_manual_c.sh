#!/bin/bash

for file in \
../benchmarks/input_1mb.txt \
../benchmarks/input_10mb.txt \
../benchmarks/input_30mb.txt \
../benchmarks/input_50mb.txt \
../benchmarks/input_75mb.txt \
../benchmarks/input_100mb.txt
do
    echo "================================="
    echo "Testing: $file"

    ../c/benchmark_manual "$file"

    echo
done