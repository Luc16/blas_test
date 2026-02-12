import sys
import subprocess
import re
import csv
import pandas as pd
import matplotlib.pyplot as plt

if len(sys.argv) != 4:
    print("Usage: python benchmark.py <first> <last> <step>")
    sys.exit(1)

first = int(sys.argv[1])
last = int(sys.argv[2])
step = int(sys.argv[3])

sizes = list(range(first, last + 1, step))

results = []

# Regex to capture GFLOPS values
gflops_pattern = re.compile(r"Performance[:\s]+([0-9.]+)[\s]*GFLOPS", re.IGNORECASE)

for size in sizes:
    print(f"\rRunning size {size}x{size}x{size}...", end='')

    cmd = [
        "./run_all.sh",
        "--M", str(size),
        "--N", str(size),
        "--K", str(size)
    ]

    completed = subprocess.run(cmd, capture_output=True, text=True)

    output = completed.stdout

    implementations = ["OpenBLAS", "BLIS", "Intel MKL", "MLIR"]
    current_impl = None
    gflops_values = {}

    for line in output.splitlines():
        for impl in implementations:
            if impl in line:
                current_impl = impl
                break

        match = gflops_pattern.search(line)
        if match and current_impl:
            gflops_values[current_impl] = float(match.group(1))
            current_impl = None

    row = {
        "Size": size,
        "OpenBLAS": gflops_values.get("OpenBLAS"),
        "BLIS": gflops_values.get("BLIS"),
        "Intel MKL": gflops_values.get("Intel MKL"),
        "MLIR": gflops_values.get("MLIR"),
    }
    if (not gflops_values.get("MLIR")):
        print(f"\nWarning: MLIR performance not found for size {size}")

    results.append(row)

# Save CSV
csv_file = "benchmark_results.csv"
with open(csv_file, "w", newline="") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=["Size", "OpenBLAS", "BLIS", "Intel MKL", "MLIR"]
    )
    writer.writeheader()
    writer.writerows(results)

print(f"\nResults saved to {csv_file}")

# Convert to DataFrame for plotting
df = pd.DataFrame(results)

# Plot
plt.figure()
plt.plot(df["Size"], df["OpenBLAS"], color="blue")
plt.plot(df["Size"], df["BLIS"], color="green")
plt.plot(df["Size"], df["Intel MKL"], color="yellow")
plt.plot(df["Size"], df["MLIR"], color="black")

plt.xlabel("Matrix Size (M=N=K)")
plt.ylabel("Performance (GFLOPS)")
plt.title("GFLOPS vs Matrix Size")
plt.legend(["OpenBLAS", "BLIS", "Intel MKL", "MLIR"])
plt.grid(True)

plt.savefig("performance_plot.png", dpi=300)
plt.savefig("performance_plot.pdf", dpi=300)
plt.show()
