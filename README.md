# Systolic Array ML Accelerator

> RTL-to-Layout implementation of a 4×4 weight-stationary systolic array
> for matrix multiplication acceleration — the core of every neural network.

**Status:** 🚧 Phase 1 in progress

## Tool Stack
- Simulation: Icarus Verilog v12 + GTKWave
- FPGA Synthesis: Vivado 2025.1 (Artix-7)
- Physical Layout: Magic VLSI 8.3 + Sky130 PDK
- LVS + Parasitic: Netgen + NGSpice-42
- Analysis: Python 3.12 (numpy, matplotlib, PyTorch)
