import pandas as pd
import matplotlib.pyplot as plt

c     = pd.read_csv("c_results.csv")
ocaml = pd.read_csv("ocaml_results.csv")

sizes = c["InputSizeMB"]

# 1. Encryption time
plt.figure(figsize=(8, 5))
plt.plot(sizes, c["EncryptTime"],     marker="o", label="C (AES-NI)")
plt.plot(sizes, ocaml["EncryptTime"], marker="o", label="OCaml + C bindings (AES-NI)")
plt.xlabel("Input Size (MB)")
plt.ylabel("Encryption Time (s)")
plt.title("AES-NI Encryption Time: C vs OCaml C-bindings")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("encryption_time_comparison.png")
plt.close()

# 2. Decryption time
plt.figure(figsize=(8, 5))
plt.plot(sizes, c["DecryptTime"],     marker="o", label="C (AES-NI)")
plt.plot(sizes, ocaml["DecryptTime"], marker="o", label="OCaml + C bindings (AES-NI)")
plt.xlabel("Input Size (MB)")
plt.ylabel("Decryption Time (s)")
plt.title("AES-NI Decryption Time: C vs OCaml C-bindings")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("decryption_time_comparison.png")
plt.close()

# 3. Encryption throughput
plt.figure(figsize=(8, 5))
plt.plot(sizes, c["EncryptSpeed"],     marker="o", label="C (AES-NI)")
plt.plot(sizes, ocaml["EncryptSpeed"], marker="o", label="OCaml + C bindings (AES-NI)")
plt.xlabel("Input Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.title("AES-NI Encryption Throughput: C vs OCaml C-bindings")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("encryption_speed_comparison.png")
plt.close()

# 4. Decryption throughput
plt.figure(figsize=(8, 5))
plt.plot(sizes, c["DecryptSpeed"],     marker="o", label="C (AES-NI)")
plt.plot(sizes, ocaml["DecryptSpeed"], marker="o", label="OCaml + C bindings (AES-NI)")
plt.xlabel("Input Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.title("AES-NI Decryption Throughput: C vs OCaml C-bindings")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("decryption_speed_comparison.png")
plt.close()

print("Graphs generated successfully")
