// ----------- Arqo P4-----------------------
// pescalar_par3
//
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include "arqo4.h"

int main(int argc, char** argv)
{
	float *A=NULL, *B=NULL;
	long long k=0;
	struct timeval fin,ini;
	double sum=0;
	int smatrix, nhilo;
       
    smatrix = atoi(argv[1]);
    nhilo = atoi(argv[2]);

	A = generateVectorOne(smatrix);
	B = generateVectorOne(smatrix);
	if ( !A || !B )
	{
		printf("Error when allocationg matrix\n");
		freeVector(A);
		freeVector(B);
		return -1;
	}

    /* nproc=omp_get_num_procs(); */
    omp_set_num_threads(nhilo);   
    
    printf("Se han lanzado %d hilos.\n", nhilo);

	gettimeofday(&ini,NULL);
	/* Bloque de computo */

#pragma omp parallel for reduction(+:sum) if (smatrix > 6000000)
    for(k=0;k<smatrix;k++)
    {
        sum += A[k]*B[k];
    }
	/* Fin del computo */
	gettimeofday(&fin,NULL);

	printf("Resultado: %f\n",sum);
	printf("Tiempo: %f\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);
	freeVector(A);
	freeVector(B);

	return 0;
}