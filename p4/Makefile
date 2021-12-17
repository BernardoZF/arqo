CC = gcc
LIBS = -lgomp -lm
LIB_DIR =  
FLAGS = -g -Wall -D_GNU_SOURCE -fopenmp

.PHONY: clean all

all: omp1 omp2 pescalar_serie pescalar_par1 pescalar_par2 pescalar_par3 edgeDetector clear pi_serie pi_par1 pi_par4 pi_par3 pi_par2 pi_par5 pi_par6 pi_par7 normal_serie normal_par1 normal_par2 normal_par3

omp1: omp1.c
	$(CC) $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

omp2: omp2.c
	$(CC) $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

pescalar_serie: pescalar_serie.c arqo4.c
	$(CC) $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

pescalar_par1: pescalar_par1.c arqo4.c
	$(CC) $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

pescalar_par2: pescalar_par2.c arqo4.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

pescalar_par3: pescalar_par3.c arqo4.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

normal_serie: normal_serie.c arqo4.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

normal_par1: normal_par1.c arqo4.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

normal_par2: normal_par2.c arqo4.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

normal_par3: normal_par3.c arqo4.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

edgeDetector: edgeDetector.c stb_image_write.h stb_image.h
	$(CC) $(FLAGS) -std=gnu99 $(LIB_DIR) -o $@ edgeDetector.c $(LIBS)

stb_image.h:
	@echo "Los ficheros de cabecera de stb se deberían descarga automáticamente"
	@echo "En caso de fallo, descargadlo de https://raw.githubusercontent.com/nothings/stb/master/stb_image.h"
	wget --no-check-certificate https://raw.githubusercontent.com/nothings/stb/master/stb_image.h

stb_image_write.h:
	@echo "Los ficheros de cabecera de stb se deberían descarga automáticamente"
	@echo "En caso de fallo, descargadlo de https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h"
	wget --no-check-certificate https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h

clean:
	rm -f *.o *~ omp1 omp2 pescalar_serie pescalar_par1 pescalar_par2 edgeDetector pescalar_par3 pi_serie pi_par1 pi_par2 pi_par3 pi_par4 pi_par5 pi_par6 pi_par7 normal_serie normal_par1 normal_par2 normal_par3
	
clear:
	rm -f *.o *~
