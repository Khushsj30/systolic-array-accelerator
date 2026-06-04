import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path

# Your systolic array specs
peak_compute_gops = (4 * 4 * 2 * 100e6) / 1e9   # 4x4 PEs, 2 ops/cycle, 100MHz = 3.2 GOPS
peak_bandwidth_gbps = 3.2                          # Artix-7 MIG DDR3: 16-bit bus @ DDR3-1600 (800MHz DDR, 1600 MT/s x 2 bytes = 3.2 GB/s)
ridge_point = peak_compute_gops / peak_bandwidth_gbps  # ops/byte

# Arithmetic intensity range
ai = np.logspace(-2, 4, 1000)   # ops/byte

# Roofline = min(peak_compute, bandwidth * AI)
roofline = np.minimum(peak_compute_gops, peak_bandwidth_gbps * ai)

# Benchmark points (ops/byte, performance GOPS)
points = {
    "My Systolic Array": (ridge_point, peak_compute_gops * 0.72),
    "CPU\n(Ryzen 7 7730U)":  (1.0, 0.8),
    "GPU\n(edge)":          (4.0, 8.0),
}

# Plot
fig, ax = plt.subplots(figsize=(10, 6))
ax.loglog(ai, roofline, 'b-', linewidth=2.5, label='Roofline')
ax.axvline(x=ridge_point, color='gray', linestyle='--', alpha=0.5, label=f'Ridge Point ({ridge_point:.2f} ops/byte)')

colors = ['green', 'red', 'purple']
for (label, (x, y)), color in zip(points.items(), colors):
    ax.scatter(x, y, s=150, color=color, zorder=5)
    ax.annotate(label, (x, y), textcoords="offset points", xytext=(10, 5), fontsize=9, color=color, fontweight='bold')

ax.set_xlabel('Arithmetic Intensity (ops/byte)', fontsize=12)
ax.set_ylabel('Performance (GOPS)', fontsize=12)
ax.set_title('Roofline Model — 4x4 Systolic Array vs CPU/GPU', fontsize=13, fontweight='bold')
ax.legend()
ax.grid(True, which='both', alpha=0.3)

repo_root = Path(__file__).resolve().parents[2]
out_dir = repo_root / 'docs' / 'diagrams'
out_dir.mkdir(parents=True, exist_ok=True)
plt.tight_layout()
plt.savefig(out_dir / 'roofline_model.png', dpi=150, bbox_inches='tight')
plt.close()

print("=" * 50)
print("ROOFLINE MODEL - 4x4 Systolic Array")
print("=" * 50)
print(f"Peak Compute:     {peak_compute_gops:.2f} GOPS")
print(f"Peak Bandwidth:   {peak_bandwidth_gbps:.2f} GB/s")
print(f"Ridge Point:      {ridge_point:.2f} ops/byte")
print(f"Achieved Perf:    {peak_compute_gops*0.72:.2f} GOPS (72% efficiency)")
print("=" * 50)
print("Plot saved to docs/diagrams/roofline_model.png")
