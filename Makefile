# =============================================================================
# Makefile — Systolic Array AI Accelerator
# Author  : Khush (NIT Warangal)
# Usage   : make sim | make golden | make aging | make roofline | make all
# =============================================================================

IVERILOG = iverilog
VVP      = vvp
PYTHON   = python3

# RTL sources — order matters for iverilog (dependencies first)
PE_SRC      = rtl/pe/pe.v
SKEW_SRC    = rtl/controller/input_skew_controller.v
ARRAY_SRC   = rtl/array/systolic_array.v
ALL_RTL     = $(PE_SRC) $(SKEW_SRC) $(ARRAY_SRC)

# Testbenches
PE_TB       = tb/pe_tb.v
ARRAY_TB    = tb/systolic_array_tb.v

# Simulation outputs
PE_SIM      = sim/pe_sim
ARRAY_SIM   = sim/array_sim

.PHONY: all sim sim-pe sim-array golden aging roofline clean help

all: sim golden aging roofline

## ── RTL Simulation ───────────────────────────────────────────────────────────

sim: sim-pe sim-array

sim-pe:
	@echo ">>> Simulating PE testbench..."
	@mkdir -p sim/vcd
	$(IVERILOG) -o $(PE_SIM) $(PE_SRC) $(PE_TB)
	$(VVP) $(PE_SIM)
	@echo ">>> PE simulation done. VCD → sim/vcd/pe_tb.vcd"

sim-array:
	@echo ">>> Simulating Array testbench (6 test cases)..."
	@mkdir -p sim/vcd
	$(IVERILOG) -o $(ARRAY_SIM) $(ALL_RTL) $(ARRAY_TB)
	$(VVP) $(ARRAY_SIM)
	@echo ">>> Array simulation done. VCD → sim/vcd/array_tb.vcd"

## ── Python Analysis ──────────────────────────────────────────────────────────

golden:
	@echo ">>> Running golden reference simulation..."
	$(PYTHON) python/golden_reference/systolic_golden.py

aging:
	@echo ">>> Running BTI aging analysis..."
	$(PYTHON) python/aging_analysis/bti_aging.py

roofline:
	@echo ">>> Generating roofline model (Artix-7 FPGA platform)..."
	$(PYTHON) python/roofline/roofline.py

## ── Cleanup ──────────────────────────────────────────────────────────────────

clean:
	@echo ">>> Cleaning build artifacts..."
	rm -f $(PE_SIM) $(ARRAY_SIM)
	rm -f sim/vcd/*.vcd
	rm -f docs/diagrams/*.png
	@echo ">>> Clean done."

## ── Help ─────────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "Systolic Array AI Accelerator — Available targets:"
	@echo "  make sim        — Compile + run PE and array RTL simulations"
	@echo "  make sim-pe     — Run PE testbench only"
	@echo "  make sim-array  — Run array testbench (6 tests: golden/zeros/identity/stress/reset/back-to-back)"
	@echo "  make golden     — Run Python golden reference (NumPy matmul check)"
	@echo "  make aging      — Run BTI aging reliability analysis"
	@echo "  make roofline   — Generate roofline model plot (Artix-7 FPGA platform)"
	@echo "  make all        — Run everything end-to-end"
	@echo "  make clean      — Remove simulation binaries and VCD files"
	@echo ""
	@echo "RTL Sources:"
	@echo "  $(PE_SRC)"
	@echo "  $(SKEW_SRC)"
	@echo "  $(ARRAY_SRC)"
	@echo ""
