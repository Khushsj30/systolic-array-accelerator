[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Systolic Array AI Accelerator
> RTL to FPGA to ASIC | Sky130 130nm | OpenLane | Vivado

![GDSII Layout](docs/diagrams/gdsii_layout.png)

## Simulation Waveforms

### PE Testbench — Single Processing Element (3×4=12 verified)
![PE Waveform](docs/screenshots/pe_waveform.png)
> `a_in=0x03`, `b_in=0x04` → `acc=0x0C (12)` | `pass_count=1`, `fail_count=0`

### Array Testbench — 4×4 Systolic Matrix Multiply
![Array Waveform](docs/screenshots/array_waveform.png)
> All 16 `c[i][j]` outputs populated with correct hex values at ~58ns

## Performance Analysis

### Roofline Model
![Roofline Model](docs/diagrams/roofline_model.png)
> Bandwidth reference: Artix-7 MIG DDR3 peak ~3.2 GB/s (DDR3-1600, 16-bit bus, 1600 MT/s x 2 bytes). Ridge point at 1.0 ops/byte — compute and memory balanced at 72% efficiency.

### BTI Aging Analysis
![BTI Aging Analysis](docs/diagrams/bti_aging_analysis.png)
> Qualitative BTI trend using the R-D power law: delta_Vth = A * t^0.25 (Alam & Mahapatra, 2005). The t^0.25 time dependence and self-limiting degradation shape are physically correct for 130nm-class CMOS. Absolute magnitudes require PDK-calibrated SPICE extraction and are not claimed here.

### Matrix Visualization
![Matrix Visualization](docs/diagrams/matrix_visualization.png)
> Diagonal input skewing — data arrives at correct PE at exactly the right cycle.

---
What is this?

I built a 4x4 weight-stationary systolic array from scratch — the same fundamental architecture inside Google's TPUs and modern AI accelerators. The goal was simple: go all the way from a Python simulation to an actual GDSII chip layout, touching every layer of the hardware stack along the way.

No shortcuts. No black boxes. Every layer understood and implemented.

---

Why did I build this?

Matrix multiplication is the backbone of every neural network — it is literally 90% of what DNNs compute. General-purpose CPUs and GPUs handle this, but they are inefficient because they constantly shuffle data between memory and compute units (the memory wall problem).

A systolic array solves this by keeping data flowing directly between processing elements — no memory trips, no wasted energy. I wanted to understand this at the transistor level, not just theoretically.

---

The Full Stack

Python (NumPy)           ->  Cycle-accurate golden reference
Verilog RTL              ->  Processing Element + 4x4 Array
Icarus Verilog + GTKWave ->  Functional simulation + waveform analysis
Vivado 2025.1            ->  FPGA synthesis on Artix-7 at 100MHz
KLayout + Sky130         ->  Transistor-level CMOS layout
OpenLane + Sky130 PDK    ->  Full RTL-to-GDSII automated ASIC flow
KLayout                  ->  GDSII visualization
Python (matplotlib)      ->  BTI aging analysis + Roofline model

---

Phase by Phase

Phase 0 - Environment Setup  
Verified the full VLSI toolchain: Icarus Verilog 12.0, GTKWave, KLayout 0.28, Sky130 PDK, NGSpice-42, Netgen, Vivado 2025.1. Set up a Python venv with numpy, matplotlib, pandas, PyTorch.

Phase 1 - Python Golden Reference  
Before touching any hardware description, I built a cycle-accurate software simulation of the systolic array in NumPy. Weight-stationary dataflow, diagonal input skewing, full 4x4 matrix multiply — verified against `np.matmul()`. This becomes the answer key that all RTL outputs are compared against.

Result: VERIFICATION PASSED — output matches NumPy ground truth exactly.

Phase 2 - Processing Element RTL  
Designed the MAC unit (multiply-accumulate) in structural Verilog:
- 8-bit inputs (A and B operands)
- 32-bit accumulator (prevents overflow across deep pipelines)
- Synchronous reset + enable gating
- 5/5 unit tests passing

To begin a new matrix multiply, assert rst for one clock cycle to clear all accumulators before re-enabling the array.

Phase 3 - Full 4x4 Array Integration  
Wired 16 PEs into a complete systolic mesh with an input skewing controller. Each row of matrix A enters one cycle later than the row above it, creating a diagonal wave that ensures data arrives at the right PE at exactly the right time.

Result: 16/16 integration tests passing. All outputs match Python golden reference exactly.

Phase 4 - FPGA Synthesis (Vivado)  
Synthesized on Artix-7 xc7a35t targeting 100MHz.

WNS              : +1.863 ns  
Failing endpoints: 0  
LUT utilization  : 6.69%  
FF utilization   : 1.69%  
DSP blocks       : 0 (pure LUT-based MAC)

Timing met with healthy slack. Zero DSP usage — the entire MAC array is in LUT fabric.

Phase 5 - ASIC Physical Layout (OpenLane + Sky130)  
Ran the full RTL-to-GDSII flow using OpenLane with the SkyWater 130nm open-source PDK.

42-step automated flow:  
Synthesis (Yosys) -> Floorplanning -> IO Placement -> Tap/Decap Insertion -> Power Planning -> Global Placement -> Placement Optimization -> Clock Tree Synthesis -> Routing Optimization -> Global Routing -> Detailed Routing (TritonRoute) -> SPEF Parasitic Extraction (min/nom/max corners) -> Multi-Corner STA -> GDSII Streaming -> LVS -> DRC -> ERC

DRC violations  : 0  
LVS             : Passed  
Setup violations: 0  
Hold violations : 0  
Die area        : 0.314 mm² (reported from OpenLane run)  
PDK             : SkyWater sky130A  
Std cell library: sky130_fd_sc_hd

Also drew a CMOS inverter from scratch using KLayout on Sky130. Fixed all 3 DRC violations (nwell enclosure, diff overhang, poly extension) -> DRC clean.

Phase 6 - BTI Aging Analysis  
Modeled long-term transistor degradation using the Bias Temperature Instability (BTI) physics model, calibrated to Sky130 130nm typical values.

BTI model          : R-D power law, delta_Vth = A * t^n, n = 0.25 (Alam & Mahapatra, 2005)
Time exponent n    : 0.25 (well-established for both NBTI in PMOS and PBTI in NMOS)
Supply voltage     : 1.8 V (Sky130 nominal, sky130_fd_sc_hd)
Model scope        : Qualitative trend only. Coefficient A is illustrative.
                     Process-calibrated values require PDK SPICE or a ring oscillator aging monitor.
Key takeaway       : BTI degradation follows a self-limiting power law — rate slows over time.
                     In production silicon, a timing margin (typically 10-15% of clock period)
                     is reserved at signoff to absorb aging over the chip lifetime.

Phase 7 - Roofline Model  
Characterized the array performance envelope against CPU and edge GPU.

Platform          | Arithmetic Intensity | Performance
My Systolic Array | 1.00 ops/byte        | 2.30 GOPS
CPU (typical)     | 1.0 ops/byte         | 0.80 GOPS
GPU (edge)        | 4.0 ops/byte         | 8.00 GOPS

The array sits at the ridge point — the sweet spot where compute and memory bandwidth are perfectly balanced. 72% hardware utilization efficiency.

---

Repo Structure

python/
  golden_reference/   cycle-accurate NumPy simulation
  aging_analysis/     BTI aging model
  roofline/           Roofline performance model
rtl/
  pe/                 Processing element (MAC unit)
  array/              Full 4x4 systolic array
  controller/         Input skew controller
tb/                   Verilog testbenches
sim/
  vcd/                GTKWave waveform dumps
  logs/               Matrix data for testbenches
vivado/
  reports/            Timing and utilization reports
layout/
  klayout/            KLayout layout scripts
openlane/
  systolic_array/     ASIC flow config and run outputs
docs/
  diagrams/           Analysis plots
  screenshots/        GDSII layout views

---

Tools Used

Simulation        : Icarus Verilog 12.0, GTKWave  
FPGA Synthesis    : Vivado 2025.1 (Artix-7)  
Physical Layout   : KLayout 0.28 (primary), Sky130 PDK  
ASIC Flow         : OpenLane (Yosys, OpenROAD, TritonRoute)  
PDK               : SkyWater Sky130A 130nm  
Analysis          : Python, NumPy, Matplotlib  
Version Control   : Git, GitHub

---

Key Takeaways

Systolic arrays achieve high efficiency by eliminating the memory wall — data flows through PEs instead of bouncing to and from DRAM.

The same RTL can target both FPGA (fast prototyping) and ASIC (real silicon) with different toolchains.

Open-source EDA (OpenLane + Sky130) makes real chip-level verification accessible without proprietary tools.

Hardware does not just work at time-zero — BTI aging degrades timing margins over years and that needs to be designed for.

---

Built end-to-end as a Complex Engineering Project in VLSI Design.  
Every layer from NumPy to GDSII implemented and verified.

---

Future Work

- Scale from 4x4 to 8x8 PE mesh for higher throughput
- Add INT4 sub-word precision support alongside INT8
- Implement zero-skipping sparse computation block
- Power gating on idle PEs for dynamic energy reduction
- Post-layout NGSpice simulation with extracted parasitics
- Full aging-aware timing closure with BTI margin built into constraints

---

Roofline Model Notes

CPU reference: single-core ARM Cortex-A55 running GEMM at ~0.8 GOPS (typical edge SoC).  
GPU reference: NVIDIA Jetson Nano edge GPU at ~8 GOPS sustained for INT8 workloads.  
Systolic array peak compute: 4x4 PEs x 2 ops/cycle x 100MHz = 3.2 GOPS theoretical, 2.30 GOPS achieved (72% efficiency).

---

### Roofline Bandwidth Context

The 3.2 GB/s bandwidth figure is derived from the Artix-7 xc7a35t MIG DDR3 interface specification: 16-bit data bus operating at DDR3-1600 (800 MHz clock, double data rate = 1600 MT/s), giving 1600e6 x 2 bytes = 3.2 GB/s peak theoretical throughput. This yields a ridge point of 1.0 ops/byte (3.2 GOPS / 3.2 GB/s). This figure applies to the FPGA implementation only. A separate ASIC roofline using Sky130-estimated on-chip SRAM bandwidth is planned for a future revision.

---

## OpenLane ASIC Implementation Results (Sky130A PDK)

Full physical implementation completed with antenna repair enabled (`RUN_HEURISTIC_DIODE_INSERTION=1`, `GRT_ANTENNA_ITERS=3`).

### DRC / LVS / Antenna

| Check | Result |
|---|---|
| Magic DRC violations | **0** |
| LVS | **Clean** (15,226 nets matched) |
| Antenna pin violations | **3** (down from 48 — 94% reduction) |
| Antenna net violations | **3** (down from 47 — 94% reduction) |

Note: 3 residual antenna violations remain on the longest accumulator bus nets; they require manual routing detours or additional PDK-specific diode cells beyond the automated repair.

### Area & Cells

| Metric | Value |
|---|---|
| Die area | **0.314 mm²** |
| Core utilization | **46.09%** |
| Synthesized cell count | **14,058 cells** |
| Total cells (with physical) | **48,044 cells** |
| Core area | **295,783 µm²** |

### Timing & Power

| Metric | Value |
|---|---|
| Clock period | **10 ns (100 MHz)** |
| Critical path | **5.34 ns** |
| Slack | **4.66 ns** |
| Setup violations | **0** |
| Hold violations | **0** |
| Typical internal power | **8.32 mW** |
| Typical switching power | **7.54 mW** |
| Leakage power | **85.6 nW** |
| Total power | **~15.86 mW** |

### Routing

| Metric | Value |
|---|---|
| Wire length | **795,186 µm** |
| Vias | **638,841** |
| TritonRoute violations | **0** |
| Runtime | **49 min 9 sec** |
