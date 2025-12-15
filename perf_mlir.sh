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
