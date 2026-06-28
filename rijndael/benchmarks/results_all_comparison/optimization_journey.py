import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# Full optimisation journey at 100 MB
# Phase 1: development-time measurements from BENCHMARK_OPT.md
# Phase 2: clean benchmark measurements from BENCHMARK_FINAL_OPT.md

stages = [
    # label                          enc_mb_s   dec_mb_s   phase
    ("OCaml\nBaseline",              32.89,     37.39,     1),
    ("Buffer\nReuse",                27.32,     26.04,     1),
    ("Inline\nround_word",           50.31,     27.67,     1),
    ("Inline\nfinal_round_word",     78.27,     39.68,     1),
    ("Inline\ninv_round_word",       51.84,     55.91,     1),
    ("Inline\ninv_final_round_word", 64.29,     65.64,     1),
    ("Remove\nBlock Copies",         73.92,     71.24,     1),
    # --- clean re-benchmark (BENCHMARK_FINAL_OPT) ---
    ("Baseline\nOpt (re-run)",       50.21,     47.74,     2),
    ("Array.\nunsafe_get",           83.33,     87.89,     2),
    ("Byte\nSimplification",         88.77,     94.24,     2),
    ("put_u32\nSimplification",      98.91,     92.16,     2),
    ("State\n= int",                 87.77,     90.71,     2),
    ("State+rk\n= int",             119.97,    122.80,     2),
    ("Table\nConversion",           164.74,    151.74,     2),
]

labels   = [s[0] for s in stages]
enc_vals = [s[1] for s in stages]
dec_vals = [s[2] for s in stages]
phases   = [s[3] for s in stages]

# C reference at 100 MB (from results_final_opt/c_results.csv)
C_ENC = 154.29
C_DEC = 149.23

x = np.arange(len(labels))

PHASE_COLORS = {1: "#4C72B0", 2: "#DD8452"}
C_COLOR      = "#2ca02c"

def bar_color(phase):
    return PHASE_COLORS[phase]

def make_journey(title, values, c_ref, filename):
    fig, ax = plt.subplots(figsize=(15, 6))

    colors = [bar_color(p) for p in phases]
    bars = ax.bar(x, values, color=colors, edgecolor="white", linewidth=0.6, zorder=2)

    # value labels on bars
    for bar, val in zip(bars, values):
        ax.text(bar.get_x() + bar.get_width() / 2,
                bar.get_height() + 1.5,
                f"{val:.1f}",
                ha="center", va="bottom", fontsize=7.5, fontweight="bold")

    # C reference dotted line
    ax.axhline(c_ref, color=C_COLOR, linewidth=2, linestyle="--", zorder=3,
               label=f"C Reference  {c_ref} MB/s")

    # phase divider
    divider_x = 6.5   # between index 6 (Remove Block Copies) and 7 (Baseline re-run)
    ax.axvline(divider_x, color="gray", linewidth=1.2, linestyle=":", alpha=0.7)
    ax.text(divider_x + 0.08, ax.get_ylim()[1] * 0.97,
            "clean re-benchmark →", fontsize=8, color="gray", va="top")

    ax.set_xticks(x)
    ax.set_xticklabels(labels, fontsize=8.5)
    ax.set_xlabel("Optimisation Stage", fontsize=11)
    ax.set_ylabel("Throughput (MB/s)", fontsize=11)
    ax.set_title(title, fontsize=13, fontweight="bold")
    ax.grid(axis="y", linestyle="--", alpha=0.4, zorder=0)
    ax.set_ylim(0, max(max(values), c_ref) * 1.15)

    # legend
    p1_patch = mpatches.Patch(color=PHASE_COLORS[1], label="Phase 1 (BENCHMARK_OPT)")
    p2_patch = mpatches.Patch(color=PHASE_COLORS[2], label="Phase 2 (BENCHMARK_FINAL_OPT)")
    c_line   = plt.Line2D([0], [0], color=C_COLOR, linewidth=2,
                          linestyle="--", label=f"C Reference  {c_ref} MB/s")
    ax.legend(handles=[p1_patch, p2_patch, c_line], fontsize=9, loc="upper left")

    plt.tight_layout()
    plt.savefig(filename, dpi=150)
    plt.close()
    print(f"  {filename}")

import os
base = os.path.dirname(os.path.abspath(__file__))

print("Generating optimisation journey graphs...")
make_journey(
    "Rijndael AES-128 — Encryption Speed Optimisation Journey (100 MB)",
    enc_vals, C_ENC,
    os.path.join(base, "optimization_journey_encryption.png")
)
make_journey(
    "Rijndael AES-128 — Decryption Speed Optimisation Journey (100 MB)",
    dec_vals, C_DEC,
    os.path.join(base, "optimization_journey_decryption.png")
)
print("Done.")
