FLAGS = -g -Wall -D_GNU_SOURCE

.PHONY: clean all

all: normal traspuesta

normal: normal.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

traspuesta: traspuesta.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

clean:
	rm -f *.o 
                                         