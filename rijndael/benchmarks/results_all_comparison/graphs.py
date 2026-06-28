import pandas as pd
import matplotlib.pyplot as plt
import os

base = os.path.dirname(os.path.abspath(__file__))

c         = pd.read_csv(os.path.join(base, "../results_final_opt/c_results.csv"))
ocaml     = pd.read_csv(os.path.join(base, "../results/results_rijndael_ocaml.csv"))
ocaml_opt = pd.read_csv(os.path.join(base, "../results_opt/results_rijndael_ocaml_opt.csv"))
ocaml_fo  = pd.read_csv(os.path.join(base, "../results_final_opt/ocaml_results.csv"))

sizes = c["InputSizeMB"]

LABELS = [
    ("C (Final Opt)",          c,         "InputSizeMB", "#1f77b4", "o"),
    ("OCaml (Baseline)",       ocaml,     "size_mb",     "#ff7f0e", "s"),
    ("OCaml (Opt)",            ocaml_opt, "size_mb",     "#2ca02c", "^"),
    ("OCaml (Final Opt)",      ocaml_fo,  "InputSizeMB", "#d62728", "D"),
]

def col(df, camel, snake):
    return df[camel] if camel in df.columns else df[snake]

def make_graph(title, ylabel, camel, snake, filename):
    plt.figure(figsize=(9, 5))
    for label, df, size_col, color, marker in LABELS:
        plt.plot(df[size_col], col(df, camel, snake),
                 marker=marker, color=color, label=label, linewidth=1.8)
    plt.xlabel("Input Size (MB)")
    plt.ylabel(ylabel)
    plt.title(title)
    plt.legend()
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.tight_layout()
    plt.savefig(os.path.join(base, filename), dpi=150)
    plt.close()
    print(f"  {filename}")

print("Generating graphs...")
make_graph("Rijndael — Encryption Time (all optimisations)",
           "Time (s)", "EncryptTime", "enc_time",
           "encryption_time_comparison.png")

make_graph("Rijndael — Decryption Time (all optimisations)",
           "Time (s)", "DecryptTime", "dec_time",
           "decryption_time_comparison.png")

make_graph("Rijndael — Encryption Throughput (all optimisations)",
           "Throughput (MB/s)", "EncryptSpeed", "enc_speed",
           "encryption_speed_comparison.png")

make_graph("Rijndael — Decryption Throughput (all optimisations)",
           "Throughput (MB/s)", "DecryptSpeed", "dec_speed",
           "decryption_speed_comparison.png")

print("Done.")
