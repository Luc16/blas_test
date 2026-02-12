// Wrap everything in a single module
!a_t = tensor<3984x3984xf64>    // A: M=3984, K=3984
!b_t = tensor<3984x3984xf64>    // B: K=3984, N=3984
!c_t = tensor<3984x3984xf64>    // C: M=3984, N=3984

module {
    func.func private @timestamp() -> i64
    func.func private @print_gflops(f64, f64)
    func.func private @print_f64(f64)

    // CHECK-LABEL: func @main
    // CHECK-NOT:   memref.alloc
    // CHECK:       %C_result = linalg.matmul
    func.func @main() {
        %c0 = arith.constant 0 : index

        // 1. Create the tensors initialized with 1.0 (or 0.0 for C)
        %A_val = arith.constant dense<1.0> : !a_t
        %B_val = arith.constant dense<2.0> : !b_t
        %C_val = arith.constant dense<3.0> : !c_t

        %C_result0 = linalg.matmul
          ins(%A_val, %B_val : !a_t, !b_t)
          outs(%C_val : !c_t) -> !c_t


        // 2. Time the linalg.matmul operation
        %start_time = func.call @timestamp() : () -> i64
        
        // Use correct typed tensors for A, B, and C_init
        %C_result = linalg.matmul
          ins(%A_val, %B_val : !a_t, !b_t)
          outs(%C_val : !c_t) -> !c_t

        %end_time = func.call @timestamp() : () -> i64

        // 3. Calculate GFLOP/s for specific M, N, K
        // Formula: 2 * M * N * K
        // M=3984, N=3984, K=3984
        // 3984 * 3984 * 3984 * 2 = 126,470,135,808 FLOPs
        
        %total_flops = arith.constant 126470135808.0 : f64
        %billion = arith.constant 1000000000.0 : f64

        // Calculate elapsed time in nanoseconds
        %elapsed_ns_i = arith.subi %end_time, %start_time : i64
        // Convert elapsed time to a double
        %elapsed_ns_f = arith.uitofp %elapsed_ns_i : i64 to f64

        // Calculate elapsed time in seconds
        %elapsed_s = arith.divf %elapsed_ns_f, %billion : f64
        
        // Calculate GFLOP/s (Gigaflops = Total Flops / Nanoseconds)
        // Note: dividing Flops directly by ns is equivalent to (Flops / 1e9) / (ns / 1e9) * 1e9 ???
        // Standard way: GFLOPS = (Total Ops / 1e9) / Time_in_Seconds
        // Or simply: Flops / Nanoseconds
        %gflops = arith.divf %total_flops, %elapsed_ns_f : f64

        // 4. Print the final result
        call @print_gflops(%gflops, %elapsed_s) : (f64, f64) -> ()


        // Verify result (print first element)
        %first_element_C_result = tensor.extract %C_result[%c0, %c0] : !c_t
        call @print_f64(%first_element_C_result) : (f64) -> ()
        

        // Verify result (print first element)
        %first_element_C_result0 = tensor.extract %C_result0[%c0, %c0] : !c_t
        call @print_f64(%first_element_C_result0) : (f64) -> ()
        

    return
    }
}

