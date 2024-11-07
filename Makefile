#=======================================================================
#
# Makefile
# --------
# Makefile for building, simulating the CrypTkey FPGA including
# FW.
#
# Copyright (C) 2024- Joachim Strömbergson
#
#=======================================================================

#-------------------------------------------------------------------
# Defines.
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Top module name ans source files.
#-------------------------------------------------------------------
TOPMOD  = cryptkey

# FPGA source files.

VERILOG_SRC_DIR = rtl
VERILOG_SRC = \
	$(VERILOG_SRC_DIR)/cryptkey.v \
	$(VERILOG_SRC_DIR)/clk_reset_gen.v


#-------------------------------------------------------------------
# Build everything.
#-------------------------------------------------------------------
all: fpga.bit


#-------------------------------------------------------------------
# Main FPGA build flow.
# Synthesis. Place & Route. Bitstream generation.
#-------------------------------------------------------------------
fpga.bit: fpga.config
	ecppack fpga.config fpga.bit


fpga.config: fpga.json
	nextpnr-ecp5 --85k --json $^ \
		--lpf ../config/ulx3s_v20.lpf \
		--ignore-loops \
		--textcfg $@


fpga.json: $(VERILOG_SRC)
	yosys -p 'read_verilog $^; synth_ecp5 -json $@'


#-------------------------------------------------------------------
# FPGA device programming.
#-------------------------------------------------------------------
prog: fpga.bit
	fujprog $^


#-------------------------------------------------------------------
# Cleanup.
#-------------------------------------------------------------------
clean:
	rm -f fpga.json
	rm -f fpga.config
	rm -f fpga.bit


#-------------------------------------------------------------------
# Display info about targets.
#-------------------------------------------------------------------
help:
	@echo ""
	@echo "Build system for CrypTkey FPGA design and firmware."
	@echo ""
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all                Build all targets."
	@echo "prog               Program the FPGA with the bitstream file."
	@echo "clean              Delete all generated files."

#=======================================================================
# EOF Makefile
#=======================================================================
