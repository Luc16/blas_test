#include <blis.h>
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
	// printf("N=%d M=%d K=%d\n", N, M, K);
	
	double *A = (double *)malloc(N * K * sizeof(double));
	double *B = (double *)malloc(K * M * sizeof(double));
	double *C = (double *)malloc(N * M * sizeof(double));
	double *C2 = (double *)malloc(N * M * sizeof(double));

	fillMatrix(1.0, A, N, K);
	fillMatrix(2.0, B, K, M);
	fillMatrix(3.0, C, N, M);
	fillMatrix(3.0, C2, N, M);

	double alpha = 1.0;
    double beta = 1.0;
    
    inc_t rsa = K; inc_t csa = 1;
    inc_t rsb = M; inc_t csb = 1;
    inc_t rsc = M; inc_t csc = 1;

	// Perform timed gemm
	struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    bli_dgemm(
        BLIS_NO_TRANSPOSE,
        BLIS_NO_TRANSPOSE,
        N, M, K,
        &alpha,
        A, rsa, csa,
        B, rsb, csb,
        &beta,
        C, rsc, csc
    );
	
    clock_gettime(CLOCK_MONOTONIC, &end);

	// for (int i = 0; i < N; i++) {
	// 	for (int j = 0; j < M; j++) {
	// 		for (int k = 0; k < K; k++) {
	// 			C2[i*M + j] += A[i*K + k] * B[k*M + j];
	// 		}
	// 		if (C[i*M + j] - C2[i*M + j] > 1e-6) {
	// 			printf("Error at C[%d][%d]: %lf %lf\n", i, j, C[i*M + j], C2[i*M + j]);
	// 			return -1;
	// 		}
	// 	}
	// }

	double elapsed_time = (end.tv_sec - start.tv_sec) + 
                          (end.tv_nsec - start.tv_nsec) / 1e9;

    double flops = 2.0 * N * M * K;

    // Calculate GFLOPs (Giga-FLoating-point Operations Per Second).
    double gflops = (flops / elapsed_time) / 1e9;

    // printf("Matrix size: %d x %d\n", M, N);
    printf("Elapsed time: %f seconds\n", elapsed_time);
    printf("Performance: %f GFLOPs\n", gflops);


	free(A);
	free(B);
	free(C);



	return 0;
}
