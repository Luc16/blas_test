#!/bin/bash
set -e  # Exit immediately if compilation or objcopy fails

# 1. Prepare
echo "--- Preparing Kernel ---"
./run_mlir.sh  # Run your generation script
objcopy --redefine-sym main=mlir_kernel kernel.o

# 2. Build
echo "--- Building Binary ---"
clang++ driver.cpp kernel.o -o benchmark_bin \
  -L../../llvm-project/build/lib -lmlir_c_runner_utils \
  -L. -lmy_runner_utils \
  -Wl,-rpath,../../llvm-project/build/lib -Wl,-rpath,.


echo "=== Performance Counters (L1, L2, L3) ==="
# -ddd requests L2 cache statistics in addition to L1 and LLC (L3)
sudo perf stat -ddd ./benchmark_bin

# 3. Measure
if [ "$1" == "--record" ]; then
    echo "=== Recording Call Graph ==="
    # Record stack traces (-g) to find exactly WHO is calling the slow functions
    sudo perf record -g ./benchmark_bin
    
    echo -e "\n=== Report ==="
    sudo perf report --stdio
fi

matrix_size=2048

if [ "$1" == "--compare" ]; then
	echo "1. OpenBLAS:"
	gcc openblas_s.c -o openblas -lopenblas -O3 -march=native && sudo perf stat -ddd env OPENBLAS_NUM_THREADS=1 ./openblas -N $matrix_size -M $matrix_size -K $matrix_size

	echo ""
	echo "2. BLIS:"
	gcc blis_s.c -o blis -fopenmp -lblis -lm -O3 -march=native && sudo perf stat -ddd env OPENBLAS_NUM_THREADS=1 ./blis -N $matrix_size -M $matrix_size -K $matrix_size

	echo ""
	echo "3. Intel MKL:"
	gcc mkl_s.c -o mkl -O3 -march=native -fopenmp -I/usr/include/mkl -lmkl_rt -lpthread -lm -ldl && sudo perf stat -ddd env MKL_NUM_THREADS=1 ./mkl -N $matrix_size -M $matrix_size -K $matrix_size

fi

if [ "$1" == "--dump-asm" ]; then
# 1. Run Perf Record for all
echo "=== Recording Performance Data ==="
sudo perf record -o perf.openblas.data env OPENBLAS_NUM_THREADS=1 ./openblas -N $matrix_size -M $matrix_size -K $matrix_size
sudo perf record -o perf.blis.data env OPENBLAS_NUM_THREADS=1 ./blis -N $matrix_size -M $matrix_size -K $matrix_size
sudo perf record -o perf.mkl.data env MKL_NUM_THREADS=1 ./mkl -N $matrix_size -M $matrix_size -K $matrix_size

# 2. Dump Assembly (You must identify the symbol name first from 'perf report')
# Note: These symbol names are EXAMPLES. Use the ones you see in your report.

echo "=== Dumping Assembly ==="
# OpenBLAS
sudo perf annotate -i perf.openblas.data -M intel --stdio > openblas.asm

# BLIS
sudo perf annotate -i perf.blis.data -M intel --stdio > blis.asm

# MKL
sudo perf annotate -i perf.mkl.data -M intel --stdio > mkl.asm

echo "Assembly dumped to openblas.asm, blis.asm, and mkl.asm"
fi
