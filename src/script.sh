#!/usr/bin/env bash

seeds=("1111" "2222" "3333")
num_data=("100" "1000" "10000")

for num in "${num_data[@]}"
do
  for seed in "${seeds[@]}"
  do
    echo "===================="
    echo "Experiment for num_data $num for seed $seed"
    echo "===================="
    $JULIABIN run_code.jl 4 $num f1 $seed 2 2 summary
  done
done


