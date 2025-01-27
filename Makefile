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
	$(CORES_SRC_DIR)/sha256/src/rtl/sha256_core.v \
	$(CORES_SRC_DIR)/sha256/src/rtl/sha256_k_constants.v \
	$(CORES_SRC_DIR)/sha256/src/rtl/sha256.v \
	$(CORES_SRC_DIR)/sha256/src/rtl/sha256_w_mem.v \
	$(CORES_SRC_DIR)/ck1/rtl/ck1.v \
	$(CORES_SRC_DIR)/clk_reset_gen/rtl/clk_reset_gen.v \
	$(CORES_SRC_DIR)/fw_ram/rtl/fw_ram.v \
	$(CORES_SRC_DIR)/picorv32/rtl/picorv32.v \
	$(CORES_SRC_DIR)/rom/rtl/rom.v \
	$(CORES_SRC_DIR)/timer/rtl/timer.v \
	$(CORES_SRC_DIR)/timer/rtl/timer_core.v \
	$(CORES_SRC_DIR)/trng/rtl/trng.v \
	$(CORES_SRC_DIR)/uart/rtl/uart.v \
	$(CORES_SRC_DIR)/uart/rtl/uart_core.v \
	$(CORES_SRC_DIR)/uart/rtl/uart_fifo.v


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
		--lpf config/ulx3s_v20.lpf \
		--top cryptkey \
		--package CABGA381 \
		--ignore-loops \
		--textcfg $@


fpga.json: $(VERILOG_SRC)
	yosys \
	-l synth.txt \
	-DFIRMWARE_HEX=\"fw/firmware.hex\" \
	-p 'read_verilog $^; synth_ecp5 -json $@'


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
