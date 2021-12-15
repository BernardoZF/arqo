#!/bin/bash
#
#$ -S /bin/bash
#$ -cwd
#$ -o salida.out

#$ -j y
# Anadir valgrind y gnuplot al path
export PATH=$PATH:/share/apps/tools/valgrind/bin:/share/apps/tools/gnuplot/bin
# Indicar ruta librerías valgrind
export VALGRIND_LIB=/share/apps/tools/valgrind/lib/valgrind

# inicializar variables
Ninicio=$((1024 + 1024 * 2))
Npaso=256
Nfinal=$((1024 + 1024 * 3))
tamanios=(1024 2048 4096 8192)

rm -f ./*.dat ./*.png

echo "Running valgrind slow and fast..."
for ((N=Ninicio; N<=Nfinal; N+=Npaso)); do
    for i in "${tamanios[@]}"; do
        valgrind --tool=cachegrind --cachegrind-out-file=slow.out --I1="$i",1,64 --D1="$i",1,64 --LL=8388608,1,64 ./slow "$N"
        valgrind --tool=cachegrind --cachegrind-out-file=fast.out --I1="$i",1,64 --D1="$i",1,64 --LL=8388608,1,64 ./fast "$N"

        slowD1mr=$(cg_annotate slow.out | grep PROGRAM | awk '{print $5}' | tr -d ',')
        slowD1mw=$(cg_annotate slow.out | grep PROGRAM | awk '{print $8}' | tr -d ',')
        fastD1mr=$(cg_annotate fast.out | grep PROGRAM | awk '{print $5}' | tr -d ',')
        fastD1rw=$(cg_annotate fast.out | grep PROGRAM | awk '{print $8}' | tr -d ',')

        echo "$N $slowD1mr $slowD1mw $fastD1mr $fastD1rw" >> cache_"$i".dat
    done
done

rm ./*.out

echo "Generating plot..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Cache Data Read Errors"
set ylabel "Number of Errors"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png
set output "cache_lectura.png"
plot "cache_1024.dat" using 1:2 with lines lw 2 title "slow 1024", \
    "cache_1024.dat" using 1:4 with lines lw 2 title "fast 1024", \
    "cache_2048.dat" using 1:2 with lines lw 2 title "slow 2048", \
    "cache_2048.dat" using 1:4 with lines lw 2 title "fast 2048", \
    "cache_4096.dat" using 1:2 with lines lw 2 title "slow 4096", \
    "cache_4096.dat" using 1:4 with lines lw 2 title "fast 4096", \
    "cache_8192.dat" using 1:2 with lines lw 2 title "slow 8192", \
    "cache_8192.dat" using 1:4 with lines lw 2 title "fast 8192"
replot
set title "Cache Data Write Errors"
set output "cache_escritura.png"
plot "cache_1024.dat" using 1:3 with lines lw 2 title "slow 1024", \
     "cache_1024.dat" using 1:5 with lines lw 2 title "fast 1024", \
     "cache_2048.dat" using 1:3 with lines lw 2 title "slow 2048", \
     "cache_2048.dat" using 1:5 with lines lw 2 title "fast 2048", \
     "cache_4096.dat" using 1:3 with lines lw 2 title "slow 4096", \
     "cache_4096.dat" using 1:5 with lines lw 2 title "fast 4096", \
     "cache_8192.dat" using 1:3 with lines lw 2 title "slow 8192", \
     "cache_8192.dat" using 1:5 with lines lw 2 title "fast 8192"
replot
quit
END_GNUPLOT
