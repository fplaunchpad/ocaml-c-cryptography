import pandas as pd
import matplotlib.pyplot as plt

enc = pd.read_csv("optimization_progress_encryption.csv")
dec = pd.read_csv("optimization_progress_decryption.csv")

plt.figure(figsize=(10,5))
plt.plot(enc["optimization"], enc["enc_speed"], marker="o")
plt.xticks(rotation=30, ha="right")
plt.xlabel("Optimization Stage")
plt.ylabel("Encryption Throughput (MB/s)")
plt.title("Encryption Throughput Improvement During Optimization")
plt.grid(True)
plt.tight_layout()
plt.savefig("optimization_progress_encryption.png")
plt.close()

plt.figure(figsize=(10,5))
plt.plot(dec["optimization"], dec["dec_speed"], marker="o")
plt.xticks(rotation=30, ha="right")
plt.xlabel("Optimization Stage")
plt.ylabel("Decryption Throughput (MB/s)")
plt.title("Decryption Throughput Improvement During Optimization")
plt.grid(True)
plt.tight_layout()
plt.savefig("optimization_progress_decryption.png")
plt.close()

print("Optimization graphs generated successfully")