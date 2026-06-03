# =============================================================================
# File        : systolic_array.xdc
# Project     : Systolic Array AI Accelerator
# Author      : Khush (NIT Warangal)
# Description : Timing + pin constraints for Artix-7 FPGA (Vivado)
#               Target: 100 MHz (10ns period)
#               Board : Basys3 / Nexys A7 (xc7a35t / xc7a100t)
# =============================================================================

# Primary clock — 100 MHz onboard oscillator
# Basys3: W5 pin | Nexys A7: E3 pin — uncomment the correct one
create_clock -name clk -period 10.000 [get_ports clk]
# set_property PACKAGE_PIN W5 [get_ports clk]   ;# Basys3
# set_property PACKAGE_PIN E3 [get_ports clk]   ;# Nexys A7
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset — active high
# set_property PACKAGE_PIN U18 [get_ports rst]  ;# Basys3 BTNC
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# Enable
set_property IOSTANDARD LVCMOS33 [get_ports en]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Input/Output delays
set_input_delay  -max 2.0 -clock clk [get_ports {a_flat b_flat en rst}]
set_input_delay  -min 0.5 -clock clk [get_ports {a_flat b_flat en rst}]
set_output_delay -max 2.0 -clock clk [get_ports c_flat]
set_output_delay -min 0.5 -clock clk [get_ports c_flat]

# False path on reset
set_false_path -from [get_ports rst]
