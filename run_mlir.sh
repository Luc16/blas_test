#!/bin/bash

mkdir -p /tmp

../build/bin/transform-opt -transform=../test/sgem.mlir matmul_run.mlir > tmp/matmul_transformed.mlir

# check if the file was ran with the --transform flag and if so, don't lower
if [ "$1" == "--transform" ]; then
	exit 0
fi

mlir-opt \
	-one-shot-bufferize \
    -convert-linalg-to-loops \
	-convert-vector-to-scf \
	-convert-vector-to-llvm \
	-convert-scf-to-cf \
	-expand-strided-metadata \
	-cse \
	-loop-invariant-code-motion \
	-memref-expand \
	-normalize-memrefs \
	-lower-affine \
	-convert-math-to-llvm \
	-convert-arith-to-llvm \
	-convert-cf-to-llvm \
	-finalize-memref-to-llvm \
	-convert-func-to-llvm \
	-reconcile-unrealized-casts \
	-canonicalize \
	tmp/matmul_transformed.mlir > tmp/matmul_lowered.mlir

# mlir-runner -O3 -e main -shared-libs=libmlir_runner_utils.so tmp/matmul_lowered.mlir
mlir-runner -O3 -e main -entry-point-result=void -shared-libs=libmy_runner_utils.so,../../llvm-project/build/lib/libmlir_c_runner_utils.so tmp/matmul_lowered.mlir
# | mlir-runner -O3 -e main -entry-point-result=void -shared-libs=libmlir_runner_utils.so


