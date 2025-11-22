#!/bin/bash



matrix_size=2048

echo "Running all BLAS implementations..."
echo "-----------------------------------"
echo ""

# if has flag --sgemm use it to compile _s versions
if [[ "$1" == "--sgemm" ]]; then
	echo "Using single-precision SGEMM versions."


echo "1. OpenBLAS:"
gcc openblas_s.c -o openblas -lopenblas -O3 -march=native && env OPENBLAS_NUM_THREADS=1 ./openblas -N $matrix_size -M $matrix_size -K $matrix_size

echo ""
echo "2. BLIS:"
gcc blis_s.c -o blis -fopenmp -lblis -lm -O3 -march=native && env OPENBLAS_NUM_THREADS=1 ./blis -N $matrix_size -M $matrix_size -K $matrix_size

echo ""
echo "3. Intel MKL:"
gcc mkl_s.c -o mkl -O3 -march=native -fopenmp -I/usr/include/mkl -lmkl_rt -lpthread -lm -ldl && env MKL_NUM_THREADS=1 ./mkl -N $matrix_size -M $matrix_size -K $matrix_size

else

echo "1. OpenBLAS:"
gcc openblas.c -o openblas -lopenblas -O3 -march=native && env OPENBLAS_NUM_THREADS=1 ./openblas -N $matrix_size -M $matrix_size -K $matrix_size

echo ""
echo "2. BLIS:"
gcc blis.c -o blis -fopenmp -lblis -lm -O3 -march=native && env OPENBLAS_NUM_THREADS=1 ./blis -N $matrix_size -M $matrix_size -K $matrix_size

echo ""
echo "3. Intel MKL:"
gcc mkl.c -o mkl -O3 -march=native -fopenmp -I/usr/include/mkl -lmkl_rt -lpthread -lm -ldl && env MKL_NUM_THREADS=1 ./mkl -N $matrix_size -M $matrix_size -K $matrix_size

echo ""
echo "4. gcc:"
gcc standard.c -o gcc-matmul -ffast-math -lm -O3 -march=native && ./gcc-matmul -N $matrix_size -M $matrix_size -K $matrix_size

echo ""
echo "5. clang:"
clang standard.c -o clang-matmul -ffast-math -lm -O3 -march=native && ./clang-matmul -N $matrix_size -M $matrix_size -K $matrix_size

echo ""
echo "6. MLIR"

./run_mlir.sh


fi
