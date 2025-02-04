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

CORES_SRC_DIR = cores
VERILOG_SRC_DIR = rtl
VERILOG_SRC = \
	$(VERILOG_SRC_DIR)/cryptkey.v \
	$(CORES_SRC_DIR)/ck1/rtl/ck1.v \
	$(CORES_SRC_DIR)/clk_reset_gen/rtl/clk_reset_gen.v \
	$(CORES_SRC_DIR)/fw_ram/rtl/fw_ram.v \
	$(CORES_SRC_DIR)/picorv32/rtl/picorv32.v \
	$(CORES_SRC_DIR)/rom/rtl/rom.v \
	$(CORES_SRC_DIR)/timer/rtl/timer.v \
	$(CORES_SRC_DIR)/timer/rtl/timer_core.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/adder.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/blockmem1r1w.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/blockmem2r1wptr.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/blockmem2r1w.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/blockmem2rptr1w.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/modexp_core.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/modexp.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/montprod.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/residue.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/shl.v \
	$(CORES_SRC_DIR)/modexp/src/rtl/shr.v \
	$(CORES_SRC_DIR)/trng/rtl/trng.v \
	$(CORES_SRC_DIR)/uart/rtl/uart.v \
	$(CORES_SRC_DIR)/uart/rtl/uart_core.v \
	$(CORES_SRC_DIR)/uart/rtl/uart_fifo.v


#-------------------------------------------------------------------
# Build everything.
#-------------------------------------------------------------------
all: fpga.dfu


#-------------------------------------------------------------------
# Main FPGA build flow.
# Synthesis. Place & Route. Bitstream generation.
#-------------------------------------------------------------------
fpga.dfu: fpga.bit
	cp fpga.bit fpga.dfu
	dfu-suffix -v 1209 -p 5af0 -a fpga.dfu


fpga.bit: fpga.config
	ecppack fpga.config fpga.bit


fpga.config: fpga.json
	nextpnr-ecp5 --85k --json $^ \
		--lpf config/orangecrab_r0.2.1.pcf \
		--top cryptkey \
		--package CSFBGA285 \
		--ignore-loops \
		--textcfg $@


fpga.json: $(VERILOG_SRC)
	yosys \
	-l synth.txt \
	-DFIRMWARE_HEX=\"fw/firmware.hex\" \
	-p 'read_verilog $^; synth_ecp5 -json $@'


#-------------------------------------------------------------------
# FPGA device programming.
# With fujproj for ULX3S, or dfu for OrangeCrab.
#-------------------------------------------------------------------
prog: fpga.bit
	fujprog $^


dfu: fpga.dfu
	dfu-util --alt 0 -D $<



#-------------------------------------------------------------------
# Cleanup.
#-------------------------------------------------------------------
clean:
	rm -f fpga.json
	rm -f fpga.config
	rm -f fpga.bit
	rm -f fpga.dfu
	rm -f synth.txt


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
