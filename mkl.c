#include <mkl.h> 
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>


void fillMatrix(double value, double *matrix, int32_t rows, int32_t cols) {
    for (int32_t i = 0; i < rows; i++) {
        for (int32_t j = 0; j < cols; j++) {
            matrix[i * cols + j] = value;
        }
    }
}


int main(int argc, char *argv[]) {
    int32_t N = 2048;
    int32_t M = N;
    int32_t K = N;

    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], "-N") == 0) {
            N = atoi(argv[i + 1]);
            i++;
        } else if (strcmp(argv[i], "-M") == 0) {
            M = atoi(argv[i + 1]);
            i++;
        } else if (strcmp(argv[i], "-K") == 0) {
            K = atoi(argv[i + 1]);
            i++;
        }
    }
    
    double flops = 2.0 * N * M * K;
    
    // Use MKL's fast memory allocation for better alignment (optional but recommended)
    double *A = (double *)mkl_malloc(N * K * sizeof(double), 64);
    double *B = (double *)mkl_malloc(K * M * sizeof(double), 64);
    double *C = (double *)mkl_malloc(N * M * sizeof(double), 64);

    if (A == NULL || B == NULL || C == NULL) {
        printf("Error: Memory allocation failed!\n");
        return 1;
    }

    fillMatrix(1.0, A, N, K);
    fillMatrix(2.0, B, K, M);
    fillMatrix(3.0, C, N, M);

    // Perform timed gemm
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    // The function call is identical to the one in OpenBLAS
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                N, M, K,
                1.0, A, K,
                B, M,
                1.0, C, M);

    clock_gettime(CLOCK_MONOTONIC, &end);


    double elapsed_time = (end.tv_sec - start.tv_sec) + 
                          (end.tv_nsec - start.tv_nsec) / 1e9;

    double gflops = (flops / elapsed_time) / 1e9;

    printf("Elapsed time: %f seconds\n", elapsed_time);
    printf("Performance: %f GFLOPs\n", gflops);

    // Free memory using MKL's function
    mkl_free(A);
    mkl_free(B);
    mkl_free(C);

    return 0;
}
