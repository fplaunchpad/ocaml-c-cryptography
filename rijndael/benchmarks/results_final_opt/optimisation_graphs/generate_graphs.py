import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("optimisation_results.csv")

steps = df["Optimization"]
x = range(len(steps))

# 1. Encryption throughput progression
plt.figure(figsize=(10, 6))
plt.bar(x, df["EncryptSpeed"], color="steelblue")
plt.xticks(x, steps, rotation=30, ha="right")
plt.ylabel("Throughput (MB/s)")
plt.title("OCaml Rijndael AES-128 — Encryption Optimisation Progress")
plt.grid(axis="y")
plt.tight_layout()
plt.savefig("optimisation_encrypt.png")
plt.close()

# 2. Decryption throughput progression
plt.figure(figsize=(10, 6))
plt.bar(x, df["DecryptSpeed"], color="darkorange")
plt.xticks(x, steps, rotation=30, ha="right")
plt.ylabel("Throughput (MB/s)")
plt.title("OCaml Rijndael AES-128 — Decryption Optimisation Progress")
plt.grid(axis="y")
plt.tight_layout()
plt.savefig("optimisation_decrypt.png")
plt.close()

print("Graphs generated successfully")
