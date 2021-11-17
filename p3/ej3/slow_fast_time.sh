#!/bin/bash

#inicializar variables
Ninicio=$((256 + 256 * 2))
Npaso=32
Nfinal=$((256 + 256 * 3))
fDAT=mult.dat
fPNG_Cache=mult_cache.png
fPNG_Time=mult_time.png

Niter=5

rm -f $fDAT $fPNG_Cache $fPNG_Time

touch $fDAT

# Anadir valgrind y gnuplot al path
export PATH=$PATH:/share/apps/tools/valgrind/bin:/share/apps/tools/gnuplot/bin
# Indicar ruta librerías valgrind
export VALGRIND_LIB=/share/apps/tools/valgrind/lib/valgrind

echo "Running normal mult and transpose mult..."
#Calculo del tamanio del array de tiempos
N=$(((Nfinal - Ninicio)/Npaso))
#Inicializacion de arrays de tiempos
for ((j=0; j <= N; j+=1)); do
    normalTime_t[$j]=0
    transTime_t[$j]=0
done

for i in $(seq 1 1 $Niter); do
    echo "Iteracion: $i"
    for ((j=0, N=Ninicio ; N<=Nfinal ; N+=Npaso, j+=1)); do
        echo "N: $N / $Nfinal..."
        # ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
        # para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
        # tercera columna (el valor del tiempo). Dejar los valores en variables
        # para poder imprimirlos en la misma línea del fichero de datos
        normalTime=$(./normal "$N" | grep 'time' | awk '{print $3}')
        transTime=$(./traspuesta "$N" | grep 'time' | awk '{print $3}')

        normalTime_t[$j]=$(echo "${normalTime_t[$j]}" "$normalTime" | awk '{print $1 + $2}')
        transTime_t[$j]=$(echo "${transTime_t[$j]}" "$transTime" | awk '{print $1 + $2}')
    done
done

echo "Computing the average and cache errors..."
for ((j = 0, N = Ninicio ; N <= Nfinal ; N += Npaso, j += 1)); do
    echo "N: $N / $Nfinal..."

    normalTime=$(echo "${normalTime_t[$j]}" "$Niter" | awk '{print $1 / $2}')
    transTime=$(echo "${transTime_t[$j]}" "$Niter" | awk '{print $1 / $2}')

    valgrind --tool=cachegrind --cachegrind-out-file=normal.out ./normal "$N"
    valgrind --tool=cachegrind --cachegrind-out-file=trans.out ./traspuesta "$N"

    normalD1mr=$(cg_annotate normal.out | grep PROGRAM | awk '{print $5}' | tr -d ',')
    normalD1mw=$(cg_annotate normal.out | grep PROGRAM | awk '{print $8}' | tr -d ',')
    transD1mr=$(cg_annotate trans.out | grep PROGRAM | awk '{print $5}' | tr -d ',')
    transD1mw=$(cg_annotate trans.out | grep PROGRAM | awk '{print $8}' | tr -d ',')

    echo "$N $normalTime $normalD1mr $normalD1mw $transTime $transD1mr $transD1mw" >> $fDAT
done

rm ./*.out

echo "Generating plot..."

gnuplot << END_GNUPLOT
set title "Normal-Trans Execution Time"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png
set output "$fPNG_Time"
plot "$fDAT" using 1:2 with lines lw 2 title "normal", \
     "$fDAT" using 1:5 with lines lw 2 title "trans"
replot
set title "Data Cache Errors"
set output "$fPNG_Cache"
plot "$fDAT" using 1:3 with lines lw 2 title "normalD1mr", \
    "$fDAT" using 1:4 with lines lw 2 title "normalD1mw", \
    "$fDAT" using 1:6 with lines lw 2 title "transD1mr", \
    "$fDAT" using 1:7 with lines lw 2 title "transD1mw"
replot
quit
END_GNUPLOT
