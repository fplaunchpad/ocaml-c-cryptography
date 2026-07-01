import pandas as pd
import matplotlib.pyplot as plt

c        = pd.read_csv("c_results.csv")
c_simd   = pd.read_csv("c_simd_results.csv")
ocaml    = pd.read_csv("ocaml_results.csv")
oxcaml   = pd.read_csv("oxcaml_simd_results.csv")

sizes = c["InputSizeMB"]

LABELS = {
    "c":      "C (scalar)",
    "c_simd": "C (SSE2/SSSE3 SIMD)",
    "ocaml":  "OCaml (scalar)",
    "oxcaml": "OxCaml SIMD",
}
MARKERS = {"c": "o", "c_simd": "D", "ocaml": "s", "oxcaml": "^"}

def plot4(field, ylabel, title, outfile):
    plt.figure(figsize=(10, 5))
    plt.plot(sizes, c[field],      marker=MARKERS["c"],      label=LABELS["c"])
    plt.plot(sizes, c_simd[field], marker=MARKERS["c_simd"], label=LABELS["c_simd"])
    plt.plot(sizes, ocaml[field],  marker=MARKERS["ocaml"],  label=LABELS["ocaml"])
    plt.plot(sizes, oxcaml[field], marker=MARKERS["oxcaml"], label=LABELS["oxcaml"])
    plt.xlabel("Input Size (MB)")
    plt.ylabel(ylabel)
    plt.title(title)
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(outfile)
    plt.close()

plot4("EncryptTime", "Encryption Time (s)",
      "ChaCha20 Encryption Time: C scalar vs C SIMD vs OCaml vs OxCaml SIMD",
      "encryption_time_comparison.png")

plot4("DecryptTime", "Decryption Time (s)",
      "ChaCha20 Decryption Time: C scalar vs C SIMD vs OCaml vs OxCaml SIMD",
      "decryption_time_comparison.png")

plot4("EncryptSpeed", "Throughput (MB/s)",
      "ChaCha20 Encryption Throughput: C scalar vs C SIMD vs OCaml vs OxCaml SIMD",
      "encryption_speed_comparison.png")

plot4("DecryptSpeed", "Throughput (MB/s)",
      "ChaCha20 Decryption Throughput: C scalar vs C SIMD vs OCaml vs OxCaml SIMD",
      "decryption_speed_comparison.png")

print("All 4 graphs generated.")

# Print summary table at 100 MB
row_c      = c[c["InputSizeMB"] == 100].iloc[0]
row_csimd  = c_simd[c_simd["InputSizeMB"] == 100].iloc[0]
row_ocaml  = ocaml[ocaml["InputSizeMB"] == 100].iloc[0]
row_oxcaml = oxcaml[oxcaml["InputSizeMB"] == 100].iloc[0]

print("\n100 MB throughput summary:")
print(f"  {'Implementation':<26} {'Enc (MB/s)':>12} {'Dec (MB/s)':>12}")
print(f"  {'-'*52}")
for label, row in [
    (LABELS["c"],      row_c),
    (LABELS["c_simd"], row_csimd),
    (LABELS["ocaml"],  row_ocaml),
    (LABELS["oxcaml"], row_oxcaml),
]:
    print(f"  {label:<26} {row['EncryptSpeed']:>12.1f} {row['DecryptSpeed']:>12.1f}")
