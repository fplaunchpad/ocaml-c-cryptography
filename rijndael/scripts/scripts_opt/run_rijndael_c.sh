#!/bin/bash

ROOT=$(realpath "$(dirname "$0")/../..")

OUTPUT="$ROOT/benchmarks/results_opt/results_rijndael_c.csv"

echo "size_mb,enc_time,dec_time,enc_speed,dec_speed" > "$OUTPUT"

cd "$ROOT/c" || exit

for size in 1 10 30 50 75 100
do
    RESULT=$(./benchmark_rijndael "$ROOT/benchmarks/input_${size}mb.txt")

    ENC_TIME=$(echo "$RESULT" | grep "Encryption time" | awk '{print $4}')
    DEC_TIME=$(echo "$RESULT" | grep "Decryption time" | awk '{print $4}')
    ENC_SPEED=$(echo "$RESULT" | grep "Encryption speed" | awk '{print $4}')
    DEC_SPEED=$(echo "$RESULT" | grep "Decryption speed" | awk '{print $4}')

    echo "$size,$ENC_TIME,$DEC_TIME,$ENC_SPEED,$DEC_SPEED" >> "$OUTPUT"
done