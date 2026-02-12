#!/bin/bash

echo "Running all BLAS implementations..."
echo "-----------------------------------"
echo ""

# Defaults
USE_SGEMM=0
PRECISION="f64"
M=""
N=""
K=""

# -------------------------
# Argument Parsing
# -------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --M)
            M="$2"
            shift 2
            ;;
        --N)
            N="$2"
            shift 2
            ;;
        --K)
            K="$2"
            shift 2
            ;;
        --sgemm)
            USE_SGEMM=1
            PRECISION="f32"
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --M <val> --N <val> --K <val> [--sgemm]"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$M" || -z "$N" || -z "$K" ]]; then
    echo "Error: You must provide --M, --N and --K."
    echo "Usage: $0 --M <val> --N <val> --K <val> [--sgemm]"
    exit 1
fi

echo "Matrix sizes: M=$M N=$N K=$K"
if [[ $USE_SGEMM -eq 1 ]]; then
    echo "Using single-precision (SGEMM)"
else
    echo "Using double-precision (DGEMM)"
fi
echo ""

# -------------------------
# Single Precision
# -------------------------
if [[ $USE_SGEMM -eq 1 ]]; then

    echo "1. OpenBLAS:"
    gcc openblas_s.c -o openblas -lopenblas -O3 -march=native && \
    OPENBLAS_NUM_THREADS=1 ./openblas -M $M -N $N -K $K

    echo ""
    echo "2. BLIS:"
    gcc blis_s.c -o blis -fopenmp -lblis -lm -O3 -march=native && \
    OPENBLAS_NUM_THREADS=1 ./blis -M $M -N $N -K $K

    echo ""
    echo "3. Intel MKL:"
    gcc mkl_s.c -o mkl -O3 -march=native -fopenmp -I/usr/include/mkl \
        -lmkl_rt -lpthread -lm -ldl && \
    MKL_NUM_THREADS=1 ./mkl -M $M -N $N -K $K

    echo ""
    echo "4. MLIR"
    python3 generate_mlir.py $M $N $K f32 > matmul_run.mlir
    ./run_mlir.sh

# -------------------------
# Double Precision
# -------------------------
else

    echo "1. OpenBLAS:"
    gcc openblas.c -o openblas -lopenblas -O3 -march=native && \
    OPENBLAS_NUM_THREADS=1 ./openblas -M $M -N $N -K $K

    echo ""
    echo "2. BLIS:"
    gcc blis.c -o blis -fopenmp -lblis -lm -O3 -march=native && \
    OPENBLAS_NUM_THREADS=1 ./blis -M $M -N $N -K $K

    echo ""
    echo "3. Intel MKL:"
    gcc mkl.c -o mkl -O3 -march=native -fopenmp -I/usr/include/mkl \
        -lmkl_rt -lpthread -lm -ldl && \
    MKL_NUM_THREADS=1 ./mkl -M $M -N $N -K $K

    # echo ""
    # echo "4. gcc:"
    # gcc standard.c -o gcc-matmul -ffast-math -lm -O3 -march=native && \
    # ./gcc-matmul -M $M -N $N -K $K
    #
    # echo ""
    # echo "5. clang:"
    # clang standard.c -o clang-matmul -ffast-math -lm -O3 -march=native && \
    # ./clang-matmul -M $M -N $N -K $K

    echo ""
    echo "6. MLIR"
    python3 generate_mlir.py $M $N $K f64 > matmul_run.mlir
    ./run_mlir.sh

fi
