#!/bin/bash

OUTPUT="../benchmarks/results_final_opt/ocaml_results.csv"

echo "InputSizeMB,EncryptTime,DecryptTime,EncryptSpeed,DecryptSpeed,MinorCollections,MajorCollections,MinorWords,PromotedWords,MajorWords" > "$OUTPUT"

for f in \
../benchmarks/input_1mb.txt \
../benchmarks/input_10mb.txt \
../benchmarks/input_30mb.txt \
../benchmarks/input_50mb.txt \
../benchmarks/input_75mb.txt \
../benchmarks/input_100mb.txt
do
    ../ocaml/_build/default/benchmark_rijndael_opt.exe "$f" | awk '
        NR == 1 { csv = $0 }
        /Minor collections/  { minor_col = $NF }
        /Major collections/  { major_col = $NF }
        /Minor words/        { minor_w   = $NF }
        /Promoted words/     { prom_w    = $NF }
        /Major words/        { print csv "," minor_col "," major_col "," minor_w "," prom_w "," $NF }
    ' >> "$OUTPUT"
done