# Systolic Array AI Accelerator — One-command build system
# Usage: make sim | make golden | make aging | make roofline | make all | make clean

IVERILOG = iverilog
VVP      = vvp
PYTHON   = python3

PE_SRC    = rtl/pe/pe.v
ARRAY_SRC = rtl/array/systolic_array.v
PE_TB     = tb/pe_tb.v
ARRAY_TB  = tb/array_tb.v

.PHONY: all sim sim-pe sim-array golden aging roofline clean help

all: sim golden aging roofline

## RTL Simulation
sim: sim-pe sim-array

sim-pe:
	@echo ">>> Simulating PE testbench..."
	$(IVERILOG) -o sim/pe_sim $(PE_SRC) $(PE_TB)
	$(VVP) sim/pe_sim
	@echo ">>> PE simulation done. VCD → sim/vcd/pe_tb.vcd"

sim-array:
	@echo ">>> Simulating Array testbench..."
	$(IVERILOG) -o sim/array_sim $(ARRAY_SRC) $(PE_SRC) $(ARRAY_TB)
	$(VVP) sim/array_sim
	@echo ">>> Array simulation done. VCD → sim/vcd/array_tb.vcd"

## Python Analysis
golden:
	@echo ">>> Running golden reference simulation..."
	$(PYTHON) python/golden_reference/systolic_golden.py

aging:
	@echo ">>> Running BTI aging analysis..."
	$(PYTHON) python/aging_analysis/bti_aging.py

roofline:
	@echo ">>> Generating roofline model..."
	$(PYTHON) python/roofline/roofline.py

## Cleanup
clean:
	@echo ">>> Cleaning build artifacts..."
	rm -f sim/pe_sim sim/array_sim
	rm -f sim/vcd/*.vcd

## Help
help:
	@echo ""
	@echo "Systolic Array Accelerator — Available targets:"
	@echo "  make sim       — Run PE + array RTL simulations"
	@echo "  make sim-pe    — Run PE testbench only"
	@echo "  make sim-array — Run array testbench only"
	@echo "  make golden    — Run Python golden reference"
	@echo "  make aging     — Run BTI aging analysis"
	@echo "  make roofline  — Generate roofline model plot"
	@echo "  make all       — Run everything"
	@echo "  make clean     — Remove build artifacts"
	@echo ""
