
# Name of the testbench without extenstion
TESTBENCH = toplevel_tb

# VHDL files
FILES =  \
	../toplevel.vhd \
	../../tb/uart/uart_tb_pkg.vhd \
	../../hdl/*.vhd 

# Default settings for gtkwave (visable signal etc.)
#  use gtkwave > File > Write Save File (Strg + S) to generate the file
WAVEFORM_SETTINGS = $(TESTBENCH).sav

# Simulation break condition
#GHDL_SIM_OPT = --assert-level=error
GHDL_SIM_OPT = --stop-time=4ms

# Load default options for GHDL.
# Defines make [all|compile|run|view|clean]
include makefile.ghdl.mk

