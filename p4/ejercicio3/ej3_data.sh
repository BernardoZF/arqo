#!/bin/bash

Ninicio=512+3
Npaso=64
Nfinal=$((Ninicio + 1024))

echo "Running normal_serie and normal_par..."

for((N=Ninicio; N<= Nfinal; N+=Npaso)); do
    echo "Damos una vuelta"
    normalserieTime=$(../normal_serie "$N" | grep 'time' | awk '{print $3}')
    normalparalelTime=$(../normal_par3 "$N" 4 | grep 'time' | awk '{print $3}')

    echo "$N $normalserieTime $normalparalelTime" >> ej3.dat
done

