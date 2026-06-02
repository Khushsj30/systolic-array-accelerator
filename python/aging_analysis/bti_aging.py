import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os

# BTI Model Parameters (Sky130 130nm typical values)
Vth0 = 0.42        # Initial threshold voltage (V)
A = 0.003          # BTI degradation coefficient
n = 0.25           # Time exponent (typical 0.25 for BTI)
T_years = 10       # Simulation period
Vdd = 1.8          # Supply voltage (Sky130)
Tclk_ns = 10.0     # Clock period (ns) - your 100MHz design

# Time array (seconds)
t_sec = np.linspace(1, T_years * 365.25 * 24 * 3600, 1000)
t_years = t_sec / (365.25 * 24 * 3600)

# BTI threshold voltage shift: delta_Vth = A * t^n
delta_Vth = A * (t_sec ** n)
Vth_aged = Vth0 + delta_Vth

# Timing impact: delay increases as Vth rises
# Simple linear model: delay_degradation % = (delta_Vth / Vdd) * 100
delay_degradation_pct = (delta_Vth / Vdd) * 100
Tclk_aged = Tclk_ns * (1 + delay_degradation_pct / 100)

# At 10 years
print("=" * 50)
print("BTI AGING ANALYSIS - 4x4 Systolic Array")
print("=" * 50)
print(f"Initial Vth:         {Vth0:.3f} V")
print(f"Vth after 10 years:  {Vth_aged[-1]:.3f} V")
print(f"Delta Vth:           {delta_Vth[-1]*1000:.2f} mV")
print(f"Delay degradation:   {delay_degradation_pct[-1]:.2f}%")
print(f"Initial clock period:{Tclk_ns:.2f} ns")
print(f"Aged clock period:   {Tclk_aged[-1]:.2f} ns")
print(f"Timing slack lost:   {Tclk_aged[-1]-Tclk_ns:.3f} ns")
print("=" * 50)

# Plot
fig, axes = plt.subplots(1, 3, figsize=(15, 4))
fig.suptitle('BTI Aging Analysis - 4x4 Systolic Array (Sky130 130nm)', fontsize=12, fontweight='bold')

axes[0].plot(t_years, delta_Vth * 1000, color='red', linewidth=2)
axes[0].set_xlabel('Time (years)')
axes[0].set_ylabel('ΔVth (mV)')
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
os.makedirs('../../docs/diagrams', exist_ok=True)
plt.savefig('../../docs/diagrams/bti_aging_analysis.png', dpi=150, bbox_inches='tight')
plt.close()
print("Plot saved to docs/diagrams/bti_aging_analysis.png")
