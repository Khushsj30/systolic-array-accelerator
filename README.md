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
> Bandwidth reference: Artix-7 xc7a35t MIG DDR3-1066 — 16-bit bus @ 800 MT/s = 1.6 GB/s (ref: AMD DS180 7-Series Overview). Ridge point: 1.6 ops/byte — **wait, re-derived below**.

> Ridge point: 3.2 GOPS / 1.6 GB/s = **2.0 ops/byte**. The systolic array at 2.0 ops/byte sits **above** the ridge point — it is **compute-bound**, which is the correct and desirable operating region for a well-designed accelerator. A CPU at ~1.0 ops/byte is memory-bound; this design escapes the memory wall.

### BTI Aging Analysis
![BTI Aging Analysis](docs/diagrams/bti_aging_analysis.png)
> Qualitative BTI trend using the R-D power law: δVth = A · t^0.25 (Alam & Mahapatra, 2005). n = 0.25 per the original model; Mahapatra et al. (2013) showed the long-term exponent converges toward n ≈ 1/6. The concave (self-limiting) degradation shape is physically correct for 130nm-class CMOS. Absolute magnitudes require PDK-calibrated SPICE and are not claimed here.

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

Note: The synthesis-only utilization report shows IOB usage > 100% due to Vivado’s pre-placement IO estimate on the flat output bus. This is expected in synthesis-only runs. A production implementation would serialize the output bus or use a narrower top-level interface to fit within the xc7a35t’s 106 bonded IOs.

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
Modeled long-term transistor degradation using the Bias Temperature Instability (BTI) physics model.

BTI model          : R-D power law, delta_Vth = A * t^n, n = 0.25 (Alam & Mahapatra, 2005)
Time exponent n    : 0.25 per the original model. Note: Mahapatra et al. (2013) shows the
                     long-term exponent from the H2 R-D framework converges toward n ~ 1/6.
                     n = 0.25 is used here as a conservative engineering estimate.
Supply voltage     : 1.8 V (Sky130 nominal, sky130_fd_sc_hd)
Model scope        : Qualitative trend only. Coefficient A is illustrative.
                     Process-calibrated values require PDK SPICE or a ring oscillator aging monitor.
Key takeaway       : BTI degradation follows a self-limiting power law — rate slows over time.
                     In production silicon, a timing margin (typically 10-15% of clock period)
                     is reserved at signoff to absorb aging over the chip lifetime.

Phase 7 - Roofline Model  
Characterized the array performance envelope against CPU and edge GPU.

Platform          | Arithmetic Intensity | Performance  | Region
My Systolic Array | 2.00 ops/byte        | 2.30 GOPS    | Compute-bound (above ridge)
CPU (typical)     | 1.00 ops/byte        | 0.80 GOPS    | Memory-bound (below ridge)
GPU (edge)        | 4.00 ops/byte        | 8.00 GOPS    | Compute-bound

Ridge point: 3.2 GOPS / 1.6 GB/s = 2.0 ops/byte.  
The systolic array sits above the ridge point — it is compute-bound, confirming the design successfully escapes the memory wall. 72% hardware utilization efficiency.

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

Systolic arrays achieve high efficiency by eliminating the memory wall — data flows through PEs instead of bouncing to and from DRAM. This design is compute-bound at 2.0 ops/byte, above the roofline ridge point.

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
- Output bus serialization for FPGA implementation within xc7a35t IO budget

---

Roofline Model Notes

CPU reference: single-core ARM Cortex-A55 running GEMM at ~0.8 GOPS (typical edge SoC).  
GPU reference: NVIDIA Jetson Nano edge GPU at ~8 GOPS sustained for INT8 workloads.  
Systolic array peak compute: 4x4 PEs x 2 ops/cycle x 100MHz = 3.2 GOPS theoretical, 2.30 GOPS achieved (72% efficiency).  
Ops counting convention: 2 ops/cycle counts 1 multiply + 1 add per MAC per cycle, consistent with ISSCC/MLPerf reporting.

---

### Roofline Bandwidth Context

The 1.6 GB/s bandwidth figure is derived from the Artix-7 xc7a35t MIG DDR3 interface specification. The xc7a35t MIG controller supports **DDR3-1066 maximum** (ref: AMD DS180 7-Series FPGAs Data Sheet, AMD support article ID 65635). The 16-bit data bus running at DDR3-1066 (800 MT/s) gives 800×10⁶ × 2 bytes = **1.6 GB/s** peak theoretical throughput. DDR3-1600 (1600 MT/s) is the JEDEC specification for the DRAM module itself; the FPGA MIG controller on the xc7a35t does not support DDR3-1600. Ridge point = 3.2 GOPS / 1.6 GB/s = **2.0 ops/byte**. This figure applies to the FPGA implementation only. A separate ASIC roofline using Sky130-estimated on-chip SRAM bandwidth is planned for a future revision.

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
