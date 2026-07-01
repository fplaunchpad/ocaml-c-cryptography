import pandas as pd
import matplotlib.pyplot as plt

c      = pd.read_csv("c_results.csv")
ocaml  = pd.read_csv("ocaml_results.csv")
oxcaml = pd.read_csv("oxcaml_simd_results.csv")

sizes = c["InputSizeMB"]

LABELS = {
    "c":      "C (scalar)",
    "ocaml":  "OCaml (scalar)",
    "oxcaml": "OxCaml SIMD",
}

# 1. Encryption time
plt.figure(figsize=(9, 5))
plt.plot(sizes, c["EncryptTime"],      marker="o", label=LABELS["c"])
plt.plot(sizes, ocaml["EncryptTime"],  marker="s", label=LABELS["ocaml"])
plt.plot(sizes, oxcaml["EncryptTime"], marker="^", label=LABELS["oxcaml"])
plt.xlabel("Input Size (MB)")
plt.ylabel("Encryption Time (s)")
plt.title("ChaCha20 Encryption Time: C vs OCaml vs OxCaml SIMD")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("encryption_time_comparison.png")
plt.close()

# 2. Decryption time
plt.figure(figsize=(9, 5))
plt.plot(sizes, c["DecryptTime"],      marker="o", label=LABELS["c"])
plt.plot(sizes, ocaml["DecryptTime"],  marker="s", label=LABELS["ocaml"])
plt.plot(sizes, oxcaml["DecryptTime"], marker="^", label=LABELS["oxcaml"])
plt.xlabel("Input Size (MB)")
plt.ylabel("Decryption Time (s)")
plt.title("ChaCha20 Decryption Time: C vs OCaml vs OxCaml SIMD")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("decryption_time_comparison.png")
plt.close()

# 3. Encryption throughput
plt.figure(figsize=(9, 5))
plt.plot(sizes, c["EncryptSpeed"],      marker="o", label=LABELS["c"])
plt.plot(sizes, ocaml["EncryptSpeed"],  marker="s", label=LABELS["ocaml"])
plt.plot(sizes, oxcaml["EncryptSpeed"], marker="^", label=LABELS["oxcaml"])
plt.xlabel("Input Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.title("ChaCha20 Encryption Throughput: C vs OCaml vs OxCaml SIMD")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("encryption_speed_comparison.png")
plt.close()

# 4. Decryption throughput
plt.figure(figsize=(9, 5))
plt.plot(sizes, c["DecryptSpeed"],      marker="o", label=LABELS["c"])
plt.plot(sizes, ocaml["DecryptSpeed"],  marker="s", label=LABELS["ocaml"])
plt.plot(sizes, oxcaml["DecryptSpeed"], marker="^", label=LABELS["oxcaml"])
plt.xlabel("Input Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.title("ChaCha20 Decryption Throughput: C vs OCaml vs OxCaml SIMD")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("decryption_speed_comparison.png")
plt.close()

print("All 4 graphs generated.")
