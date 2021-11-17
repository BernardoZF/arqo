#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "arqo3.h"

void compute(tipo **a, tipo **b, tipo **c, int n);
void transpose(tipo **a, tipo **at, int n);

int main(int argc, char *argv[]) {
  int n;
  int i, j;
  tipo **m = NULL;
  tipo **p = NULL;
  tipo **pt = NULL;
  tipo **c = NULL;
  struct timeval fin, ini;

  printf("Word size: %ld bits\n", 8 * sizeof(tipo));

  if (argc != 2) {
    printf("Error: ./%s <matrix size>\n", argv[0]);
    return -1;
  }
  n = atoi(argv[1]);
  m = generateMatrix(n);
  p = generateMatrix(n);
  pt = generateEmptyMatrix(n);
  c = generateEmptyMatrix(n);
  if (!m | !p | !c) {
    return -1;
  }

  gettimeofday(&ini, NULL);

  /* Main computation */
  transpose(p, pt, n);
  compute(m, pt, c, n);
  /* End of computation */

  gettimeofday(&fin, NULL);
  printf("Execution time: %f\n", ((fin.tv_sec * 1000000 + fin.tv_usec) -
                                  (ini.tv_sec * 1000000 + ini.tv_usec)) *
                                     1.0 / 1000000.0);

  printf("Resultado:\n");
  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      printf("%f ", c[i][j]);
    }
    printf("\n");
  }

  freeMatrix(m);
  freeMatrix(p);
  freeMatrix(pt);
  freeMatrix(c);

  return 0;
}

void compute(tipo **a, tipo **b, tipo **c, int n) {
  int i, j, k;

  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      for (k = 0; k < n; k++) {
        c[i][j] += a[i][k] * b[j][k];
      }
    }
  }
}

void transpose(tipo **a, tipo **at, int n) {
  int i, j;

  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      at[i][j] = a[j][i];
    }
  }
}