#!/bin/bash

cd ../c || exit 1

echo "size_mb,enc_time,dec_time,enc_speed,dec_speed" \
> ../benchmarks/results/results_rijndael_c.csv

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

    output=$(./benchmark_rijndael "$file")

    echo "$output"

    size=$(echo "$file" | grep -o '[0-9]\+' | head -1)

    enc_time=$(echo "$output" | grep "Encryption time" | awk '{print $4}')
    dec_time=$(echo "$output" | grep "Decryption time" | awk '{print $4}')
    enc_speed=$(echo "$output" | grep "Encryption speed" | awk '{print $4}')
    dec_speed=$(echo "$output" | grep "Decryption speed" | awk '{print $4}')

    echo "$size,$enc_time,$dec_time,$enc_speed,$dec_speed" \
    >> ../benchmarks/results/results_rijndael_c.csv

    echo
done