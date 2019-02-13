#!/usr/bin/env bash

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "===================="
    echo "Experiment for parameters ${line}"
    echo "===================="
    $JULIABIN run_code.jl $line
done < "$1"
#$JULIABIN run_code.jl 4 $num f1 $seed 2 2 summary


