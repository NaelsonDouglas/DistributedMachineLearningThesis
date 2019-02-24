#!/usr/bin/env bash

for i in {1..10}
do
   julia ugly_script.jl 8 1000 f1 1111 2 2 summary
done