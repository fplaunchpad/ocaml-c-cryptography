import matplotlib.pyplot as plt

# -------------------------
# Graph 1
# -------------------------

labels = ["XOR C", "XOR OCaml", "AES C", "AES Cryptokit"]
times = [0.031, 0.038, 0.286647, 0.066431]

plt.figure(figsize=(8,5))
plt.bar(labels, times)
plt.ylabel("Time (seconds)")
plt.title("Encryption Time Comparison")
plt.tight_layout()
plt.savefig("encryption_time_comparison.png")
plt.close()

# -------------------------
# Graph 2
# -------------------------

labels = ["AES C", "AES Cryptokit"]
encrypt = [0.286647, 0.066431]
decrypt = [0.868854, 0.052843]

x = range(len(labels))
width = 0.35

plt.figure(figsize=(8,5))
plt.bar([i - width/2 for i in x], encrypt, width, label="Encrypt")
plt.bar([i + width/2 for i in x], decrypt, width, label="Decrypt")

plt.xticks(list(x), labels)
plt.ylabel("Time (seconds)")
plt.title("AES Encryption vs Decryption")
plt.legend()
plt.tight_layout()
plt.savefig("aes_encrypt_decrypt.png")
plt.close()

# -------------------------
# Graph 3
# -------------------------

labels = [
    "AES C Enc",
    "AES C Dec",
    "Cryptokit Enc",
    "Cryptokit Dec"
]

throughput = [
    55.8,
    18.4,
    240.9,
    302.8
]

plt.figure(figsize=(8,5))
plt.bar(labels, throughput)
plt.ylabel("MB/s")
plt.title("AES Throughput Comparison")
plt.tight_layout()
plt.savefig("throughput_comparison.png")
plt.close()

print("Graphs generated successfully.")