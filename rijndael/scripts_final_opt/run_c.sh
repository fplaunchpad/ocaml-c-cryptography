#!/bin/bash

OUTPUT="../benchmarks/results_final_opt/c_results.csv"

echo "InputSizeMB,EncryptTime,DecryptTime,EncryptSpeed,DecryptSpeed" > "$OUTPUT"

for f in \
../benchmarks/input_1mb.txt \
../benchmarks/input_10mb.txt \
../benchmarks/input_30mb.txt \
../benchmarks/input_50mb.txt \
../benchmarks/input_75mb.txt \
../benchmarks/input_100mb.txt
do
    ../c/benchmark_rijndael "$f" | awk '
        /Message length/  { mb = $4 / (1024*1024) }
        /Encryption time/ { enc_t = $4 }
        /Decryption time/ { dec_t = $4 }
        /Encryption speed/{ enc_s = $4 }
        /Decryption speed/{ dec_s = $4 }
        /Verification/    { printf "%.0f,%.6f,%.6f,%.2f,%.2f\n", mb, enc_t, dec_t, enc_s, dec_s }
    ' >> "$OUTPUT"
done