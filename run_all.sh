#!/bin/bash

matrix_size=2048

echo "Running all BLAS implementations..."
echo "-----------------------------------"
echo ""
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

mlir-opt --blir-matmul-to-func \
                  -convert-linalg-to-loops \
                  -lower-affine \
                  -convert-scf-to-cf \
                  -expand-strided-metadata \
                  -memref-expand \
                  -normalize-memrefs \
                  -convert-math-to-llvm \
                  -convert-func-to-llvm \
                  -convert-arith-to-llvm \
                  -convert-cf-to-llvm \
                  -finalize-memref-to-llvm \
                  -reconcile-unrealized-casts \
                  -canonicalize \
                  ../mlir/test/Dialect/BLIR/matmul_run.mlir \
         | mlir-runner -O3 -e main -entry-point-result=void -shared-libs=libmlir_runner_utils.so
