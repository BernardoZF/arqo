#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "omp.h"
#include "arqo4.h"

void compute(float **a, float **b, float **c, int n);

int main(int argc, char *argv[]) {
  int n, nproc;
  float **m = NULL;
  float **p = NULL;
  float **c = NULL;
  struct timeval fin, ini;

  printf("Word size: %ld bits\n", 8 * sizeof(float));

  if (argc != 3) {
    printf("Error: ./%s <matrix size><number cores>\n", argv[0]);
    return -1;
  }
  n = atoi(argv[1]);
  m = generateMatrix(n);
  p = generateMatrix(n);
  c = generateEmptyMatrix(n);
  nproc = atoi(argv[2]);
  if (!m | !p | !c) {
    return -1;
  }

	omp_set_num_threads(nproc);

  gettimeofday(&ini, NULL);

  /* Main computation */
  compute(m, p, c, n);
  /* End of computation */

  gettimeofday(&fin, NULL);
  printf("Execution time: %f\n", ((fin.tv_sec * 1000000 + fin.tv_usec) -
                                  (ini.tv_sec * 1000000 + ini.tv_usec)) *
                                     1.0 / 1000000.0);

  freeMatrix(m);
  freeMatrix(p);
  freeMatrix(c);

  return 0;
}

void compute(float **a, float **b, float **c, int n) {
  int i, j, k;

#pragma omp parallel for private(j,k)
  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      for (k = 0; k < n; k++) {
        c[i][j] += a[i][k] * b[k][j];
      }
    }
  }

}