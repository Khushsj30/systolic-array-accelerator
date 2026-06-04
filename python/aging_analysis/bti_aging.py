import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path

# BTI Model Parameters
# Using R-D (Reaction-Diffusion) power law: delta_Vth = A * t^n
# Reference: Alam & Mahapatra, "A Comprehensive Model of PMOS NBTI Degradation", 2005
# n = 0.25 is well-established for both NBTI (PMOS) and PBTI (NMOS) in sub-250nm CMOS
Vth0 = 0.42        # Initial threshold voltage (V) — Sky130 sky130_fd_sc_hd typical
A = 2e-4           # BTI degradation prefactor (illustrative; PDK-calibrated value requires SPICE)
n = 0.25           # Time exponent — physically derived from R-D diffusion theory
T_years = 10       # Simulation period (years)
Vdd = 1.8          # Supply voltage (V) — Sky130 nominal
Tclk_ns = 10.0     # Clock period (ns) — 100MHz design target

# Time array (seconds)
t_sec = np.linspace(1, T_years * 365.25 * 24 * 3600, 1000)
t_years = t_sec / (365.25 * 24 * 3600)

# BTI threshold voltage shift: delta_Vth = A * t^n
delta_Vth = A * (t_sec ** n)
Vth_aged = Vth0 + delta_Vth

# Timing impact: linear approximation — delay proportional to Vth shift / Vdd
# (First-order CMOS delay model: t_d ~ Vdd / (Vdd - Vth)^2; linearized for small delta_Vth)
delay_degradation_pct = (delta_Vth / Vdd) * 100
Tclk_aged = Tclk_ns * (1 + delay_degradation_pct / 100)

# At 10 years
print("=" * 50)
print("BTI AGING ANALYSIS - 4x4 Systolic Array")
print("=" * 50)
print(f"Model              : R-D power law, delta_Vth = A * t^n (Alam & Mahapatra, 2005)")
print(f"Time exponent n    : {n} (physically derived from H2 diffusion in Si-SiO2)")
print(f"Supply voltage Vdd : {Vdd} V (Sky130 sky130_fd_sc_hd nominal)")
print(f"Initial Vth        : {Vth0:.3f} V")
print(f"Vth after 10 years : {Vth_aged[-1]:.3f} V")
print(f"Delta Vth (10yr)   : {delta_Vth[-1]*1000:.1f} mV")
print(f"Delay degradation  : {delay_degradation_pct[-1]:.2f}%")
print(f"Clock (fresh)      : {Tclk_ns:.2f} ns")
print(f"Clock (10yr aged)  : {Tclk_aged[-1]:.2f} ns")
print(f"Timing slack lost  : {Tclk_aged[-1]-Tclk_ns:.3f} ns")
print(f"NOTE: Prefactor A is illustrative. Absolute values require PDK-calibrated SPICE.")
print("=" * 50)

# Plot
fig, axes = plt.subplots(1, 3, figsize=(15, 4))
fig.suptitle('BTI Aging Analysis - 4x4 Systolic Array (Sky130 130nm)\nR-D Power Law: delta_Vth = A * t^0.25  [Alam & Mahapatra, 2005]', fontsize=11, fontweight='bold')

axes[0].plot(t_years, delta_Vth * 1000, color='red', linewidth=2)
axes[0].set_xlabel('Time (years)')
axes[0].set_ylabel('delta_Vth (mV)')
axes[0].set_title('Threshold Voltage Shift')
axes[0].grid(True)

axes[1].plot(t_years, delay_degradation_pct, color='orange', linewidth=2)
axes[1].set_xlabel('Time (years)')
axes[1].set_ylabel('Delay Degradation (%)')
axes[1].set_title('Timing Degradation')
axes[1].grid(True)

axes[2].plot(t_years, Tclk_aged, color='blue', linewidth=2)
axes[2].axhline(y=Tclk_ns, color='green', linestyle='--', label='Fresh (10ns)')
axes[2].set_xlabel('Time (years)')
axes[2].set_ylabel('Clock Period (ns)')
axes[2].set_title('Clock Period vs Age')
axes[2].legend()
axes[2].grid(True)

plt.tight_layout()
repo_root = Path(__file__).resolve().parents[2]
out_dir = repo_root / 'docs' / 'diagrams'
out_dir.mkdir(parents=True, exist_ok=True)
plt.savefig(out_dir / 'bti_aging_analysis.png', dpi=150, bbox_inches='tight')
plt.close()
print(f"Plot saved to {out_dir / 'bti_aging_analysis.png'}")
