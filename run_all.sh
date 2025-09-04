
echo "Running all BLAS implementations..."
echo "-----------------------------------"
echo ""
echo "1. OpenBLAS:"
gcc openblas.c -o openblas -lopenblas -O3 -march=native && env OPENBLAS_NUM_THREADS=1 ./openblas

echo ""
echo "2. BLIS:"
gcc blis.c -o blis -fopenmp -lblis -lm -O3 -march=native && env OPENBLAS_NUM_THREADS=1 ./blis

echo ""
echo "3. Intel MKL:"
gcc mkl.c -o mkl -O3 -march=native -fopenmp -I/usr/include/mkl -lmkl_rt -lpthread -lm -ldl && env MKL_NUM_THREADS=1 ./mkl
