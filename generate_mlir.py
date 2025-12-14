import sys

def get_verification_code(dtype):
    """
    Generates the verification code block.
    If f32, we must extend to f64 before printing.
    If f64, we print directly.
    """
    if dtype == "f32":
        return f"""
        // Verify result (print first element)
        %c0 = arith.constant 0 : index
        %first_element_raw = tensor.extract %C_result[%c0, %c0] : !c_t
        %first_element = arith.extf %first_element_raw : {dtype} to f64
        call @print_f64(%first_element) : (f64) -> ()
        """
    elif dtype == "f64":
        return f"""
        // Verify result (print first element)
        %c0 = arith.constant 0 : index
        %first_element = tensor.extract %C_result[%c0, %c0] : !c_t
        call @print_f64(%first_element) : (f64) -> ()
        """
    else:
        # Fallback for other types if needed
        return f"""
        // Verification skipped for non-float types
        """

def generate_mlir(M, N, K, dtype="f32"):
    # Calculate Total FLOPs: 2 * M * N * K
    total_flops = 2.0 * M * N * K
    
    # Generate the verification block based on dtype
    verification_block = get_verification_code(dtype)

    mlir_code = f"""// Wrap everything in a single module
!a_t = tensor<{M}x{K}x{dtype}>    // A: M={M}, K={K}
!b_t = tensor<{K}x{N}x{dtype}>    // B: K={K}, N={N}
!c_t = tensor<{M}x{N}x{dtype}>    // C: M={M}, N={N}

module {{
    func.func private @timestamp() -> i64
    func.func private @print_gflops(f64, f64)
    func.func private @print_f64(f64)

    // CHECK-LABEL: func @main
    // CHECK-NOT:   memref.alloc
    // CHECK:       %C_result = linalg.matmul
    func.func @main() {{
        // 1. Create the tensors initialized with 1.0 (or 0.0 for C)
        %A_val = arith.constant dense<1.0> : !a_t
        %B_val = arith.constant dense<1.0> : !b_t
        %C_val = arith.constant dense<0.0> : !c_t

        // 2. Time the linalg.matmul operation
        %start_time = func.call @timestamp() : () -> i64
        
        // Use correct typed tensors for A, B, and C_init
        %C_result = linalg.matmul
          ins(%A_val, %B_val : !a_t, !b_t)
          outs(%C_val : !c_t) -> !c_t

        %end_time = func.call @timestamp() : () -> i64

        // 3. Calculate GFLOP/s for specific M, N, K
        // Formula: 2 * M * N * K
        // M={M}, N={N}, K={K}
        // {M} * {N} * {K} * 2 = {int(total_flops):,} FLOPs
        
        %total_flops = arith.constant {total_flops} : f64
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

{verification_block}

    return
    }}
}}
"""
    print(mlir_code)

if __name__ == "__main__":
    # Default values or parse from args
    # Usage: python3 generate_matmul.py [M] [N] [K] [dtype]
    M = int(sys.argv[1]) if len(sys.argv) > 1 else 192
    N = int(sys.argv[2]) if len(sys.argv) > 2 else 64
    K = int(sys.argv[3]) if len(sys.argv) > 3 else 256
    d_type = sys.argv[4] if len(sys.argv) > 4 else "f32"
    
    generate_mlir(M, N, K, dtype=d_type)
