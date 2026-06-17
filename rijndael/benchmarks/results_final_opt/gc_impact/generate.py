import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("../ocaml_results.csv")

sizes = df["InputSizeMB"]

# 1. Minor collections vs input size
plt.figure(figsize=(8, 5))
plt.plot(sizes, df["MinorCollections"], marker="o", color="steelblue")
plt.xlabel("Input Size (MB)")
plt.ylabel("Minor Collections")
plt.title("OCaml GC — Minor Collections vs Input Size")
plt.grid(True)
plt.tight_layout()
plt.savefig("minor_collections.png")
plt.close()

# 2. Minor words allocated vs input size
plt.figure(figsize=(8, 5))
plt.plot(sizes, df["MinorWords"], marker="o", color="darkorange")
plt.xlabel("Input Size (MB)")
plt.ylabel("Minor Words Allocated")
plt.title("OCaml GC — Minor Words Allocated vs Input Size")
plt.grid(True)
plt.tight_layout()
plt.savefig("minor_words.png")
plt.close()

print("Graphs generated successfully")
