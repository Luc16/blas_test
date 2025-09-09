module {
  func.func private @blir_matmul_2048x2048xf64_2048x2048xf64_2048x2048xf64(%arg0: memref<2048x2048xf64>, %arg1: memref<2048x2048xf64>, %arg2: memref<2048x2048xf64>, %arg3: i1, %arg4: i1, %arg5: f32, %arg6: f32) {
    affine.for %arg7 = 0 to 2048 {
      affine.for %arg8 = 0 to 2048 {
        affine.for %arg9 = 0 to 2048 {
          %0 = affine.load %arg0[%arg7, %arg9] : memref<2048x2048xf64>
          %1 = affine.load %arg1[%arg9, %arg8] : memref<2048x2048xf64>
          %2 = affine.load %arg2[%arg7, %arg8] : memref<2048x2048xf64>
          %3 = arith.mulf %0, %1 : f64
          %4 = arith.addf %2, %3 : f64
          affine.store %4, %arg2[%arg7, %arg8] : memref<2048x2048xf64>
        }
      }
    }
    return
  }
  func.func @main() {
    %cst = arith.constant 0.000000e+00 : f32
    %cst_0 = arith.constant 1.000000e+00 : f32
    %false = arith.constant false
    %cst_1 = arith.constant 1.000000e+00 : f64
    %alloc = memref.alloc() : memref<2048x2048xf64>
    %alloc_2 = memref.alloc() : memref<2048x2048xf64>
    %alloc_3 = memref.alloc() : memref<2048x2048xf64>
    linalg.fill ins(%cst_1 : f64) outs(%alloc : memref<2048x2048xf64>)
    linalg.fill ins(%cst_1 : f64) outs(%alloc_2 : memref<2048x2048xf64>)
    linalg.fill ins(%cst_1 : f64) outs(%alloc_3 : memref<2048x2048xf64>)
    call @blir_matmul_2048x2048xf64_2048x2048xf64_2048x2048xf64(%alloc, %alloc_2, %alloc_3, %false, %false, %cst_0, %cst) : (memref<2048x2048xf64>, memref<2048x2048xf64>, memref<2048x2048xf64>, i1, i1, f32, f32) -> ()
    return
  }
}

