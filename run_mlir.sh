#!/bin/bash

mkdir -p /tmp

../build/bin/transform-opt -transform=../test/sgem.mlir matmul_run.mlir > tmp/matmul_transformed.mlir

# check if the file was ran with the --transform flag and if so, don't lower
if [ "$1" == "--transform" ]; then
	exit 0
fi

mlir-opt \
	-one-shot-bufferize="bufferize-function-boundaries" \
	-cse -canonicalize \
    -convert-linalg-to-loops \
	-convert-vector-to-scf \
	-normalize-memrefs \
	-expand-strided-metadata \
	-lower-affine \
	-memref-expand \
	-cse -canonicalize \
	-loop-invariant-code-motion \
	-convert-vector-to-llvm \
	-convert-math-to-llvm \
	-convert-scf-to-cf \
	-convert-cf-to-llvm \
	-convert-arith-to-llvm \
	-finalize-memref-to-llvm \
	-convert-func-to-llvm \
	-reconcile-unrealized-casts \
	-canonicalize \
	tmp/matmul_transformed.mlir > tmp/matmul_lowered.mlir

# mlir-runner -O3 -e main -shared-libs=libmlir_runner_utils.so tmp/matmul_lowered.mlir
# mlir-runner -O3 -e main -entry-point-result=void -shared-libs=libmy_runner_utils.so,../../llvm-project/build/lib/libmlir_c_runner_utils.so tmp/matmul_lowered.mlir
# echo "Running MLIR with mlir-runner..."
mlir-runner -O3 -e main -entry-point-result=void -shared-libs=libmy_runner_utils.so,../../llvm-project/build/lib/libmlir_c_runner_utils.so  -dump-object-file -object-filename=kernel.o tmp/matmul_lowered.mlir
# | mlir-runner -O3 -e main -entry-point-result=void -shared-libs=libmlir_runner_utils.so


