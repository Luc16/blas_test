#include <chrono>
#include <cstdint>
#include <iostream>

// Use extern "C" to prevent C++ name mangling, so MLIR can find the functions.
extern "C" {

	// Returns the current time in nanoseconds.
	uint64_t timestamp() {
		auto now = std::chrono::high_resolution_clock::now();
		auto duration = now.time_since_epoch();
		return std::chrono::duration_cast<std::chrono::nanoseconds>(duration).count();
	}

	// Prints a double-precision float with a label.
	void print_gflops(double gflops, double time_sec) {
		std::cout << "Elapsed time: " << time_sec << " seconds" << std::endl;
		std::cout << "Performance: " << gflops << " GFLOPs" << std::endl;
	}

} // extern "C"
