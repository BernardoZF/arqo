#!/bin/bash


# Anadir valgrind y gnuplot al path
export PATH=$PATH:/share/apps/tools/valgrind/bin:/share/apps/tools/gnuplot/bin
# Indicar ruta librerías valgrind
export VALGRIND_LIB=/share/apps/tools/valgrind/lib/valgrind

# inicializar variables
Ninicio=$((1024))
Npaso=1024
Nfinal=$((16384))
fDAT=slow_fast_time.dat
fPNG=slow_fast_time.png
Iter=13


# generar el fichero DAT vacío
touch $fDAT

echo "Running slow and fast..."
#for N in $(seq $Ninicio $Npaso $Nfinal);
for i in $(seq 1 1 $Iter); do
	echo "Iteracion: $i"
	for ((j=0, N=Ninicio ; N<=Nfinal ; N+=Npaso, j+=1)); do
		if [ "$i" = "0" ]; then
			slowTime_t[$j]=0
			fastTime_t[$j]=0
		fi

		echo "N: $N / $Nfinal..."
		# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
		# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
		# tercera columna (el valor del tiempo). Dejar los valores en variables
		# para poder imprimirlos en la misma línea del fichero de datos
		slowTime=$(./slow "$N" | grep 'time' | awk '{print $3}')
		fastTime=$(./fast "$N" | grep 'time' | awk '{print $3}')

		slowTime_t[$j]=$(echo "${slowTime_t[$j]}" "$slowTime" | awk '{print $1 + $2}')
		fastTime_t[$j]=$(echo "${fastTime_t[$j]}" "$fastTime" | awk '{print $1 + $2}')
	done
done

echo "Computing the average..."
for ((j = 0, N = Ninicio ; N <= Nfinal ; N += Npaso, j += 1)); do
	echo "N: $N / $Nfinal..."

	slowTime=$(echo "${slowTime_t[$j]}" "$Iter" | awk '{print $1 / $2}')
	fastTime=$(echo "${fastTime_t[$j]}" "$Iter" | awk '{print $1 / $2}')

	echo "$N	$slowTime	$fastTime" >> $fDAT
done

echo "Generating plot..."
gnuplot << END_GNUPLOT
set title "Slow-Fast Execution Time"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png
set output "$fPNG"
plot "$fDAT" using 1:2 with lines lw 2 title "slow", \
     "$fDAT" using 1:3 with lines lw 2 title "fast"
replot
quit
END_GNUPLOT
