# =============================================================================
# File        : systolic_array.sdc
# Project     : Systolic Array AI Accelerator
# Author      : Khush (NIT Warangal)
# Description : Timing constraints for ASIC flow (OpenLane/OpenROAD, Sky130)
#               Target: 100 MHz (10ns period) on Sky130 PDK
# =============================================================================

# Primary clock — 100 MHz
create_clock -name clk -period 10.000 [get_ports clk]

# Clock uncertainty (setup + hold margin)
set_clock_uncertainty 0.5 [get_clocks clk]

# Clock transition time
set_clock_transition 0.15 [get_clocks clk]

# Input delays (assume 20% of period for external logic)
set_input_delay  -max 2.0 -clock clk [get_ports {a_flat b_flat en rst}]
set_input_delay  -min 0.5 -clock clk [get_ports {a_flat b_flat en rst}]

# Output delays (assume 20% of period for downstream logic)
set_output_delay -max 2.0 -clock clk [get_ports c_flat]
set_output_delay -min 0.5 -clock clk [get_ports c_flat]

# Driving cell for inputs (Sky130 standard cell)
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 [get_ports {a_flat b_flat en rst}]

# Load on outputs
set_load 0.05 [get_ports c_flat]

# False path on reset (async-capable reset, no timing arc needed)
set_false_path -from [get_ports rst]
