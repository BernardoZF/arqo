#!/bin/bash

fDAT="ejercicio3.dat"
fPNG="ejercicio3.png"

rm -f ./ej3.png

echo "Generating plot..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Serie-Paralelo tiempo ejecucion"
set ylabel "Tiempo ejecucion (s)"
set xlabel "Tamanio matriz"
set key right bottom
set grid
set term png
set output "$fPNG"
plot "$fDAT" using 1:2 with lines lw 2 title "serie", \
     "$fDAT" using 1:3 with lines lw 2 title "paralelo",
replot
quit
END_GNUPLOT