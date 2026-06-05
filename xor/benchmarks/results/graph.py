import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("results.csv")

sizes = df["size_mb"]

# Encryption Speed
plt.figure(figsize=(8, 5))
plt.plot(sizes, df["c_enc_speed"], marker="o", label="C")
plt.plot(sizes, df["ocaml_enc_speed"], marker="o", label="OCaml")
plt.xlabel("Input Size (MB)")
plt.ylabel("Speed (MB/s)")
plt.title("XOR Encryption Throughput")
plt.legend()
plt.grid(True)
plt.savefig("encryption_speed.png")
plt.close()

# Decryption Speed
plt.figure(figsize=(8, 5))
plt.plot(sizes, df["c_dec_speed"], marker="o", label="C")
plt.plot(sizes, df["ocaml_dec_speed"], marker="o", label="OCaml")
plt.xlabel("Input Size (MB)")
plt.ylabel("Speed (MB/s)")
plt.title("XOR Decryption Throughput")
plt.legend()
plt.grid(True)
plt.savefig("decryption_speed.png")
plt.close()

# Execution Time
plt.figure(figsize=(8, 5))
plt.plot(sizes, df["c_enc_time"], marker="o", label="C Encrypt")
plt.plot(sizes, df["c_dec_time"], marker="o", label="C Decrypt")
plt.plot(sizes, df["ocaml_enc_time"], marker="o", label="OCaml Encrypt")
plt.plot(sizes, df["ocaml_dec_time"], marker="o", label="OCaml Decrypt")
plt.xlabel("Input Size (MB)")
plt.ylabel("Time (seconds)")
plt.title("XOR Execution Time")
plt.legend()
plt.grid(True)
plt.savefig("execution_time.png")
plt.close()

print("Graphs generated successfully.")