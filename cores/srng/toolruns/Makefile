#=======================================================================
#
# Makefile
# --------
# Makefile for building the trng simulation model and FPGA bitstream
# for core testing on hardware.
#
# (c) 2024 Joachim Strömbergson
#
#=======================================================================

VERILOG_SRC_DIR = ../rtl
VERILOG_SRC = \
	$(VERILOG_SRC_DIR)/trng.v


all: fpga.bit


fpga.bit: fpga.config
	ecppack fpga.config fpga.bit


fpga.config: fpga.json
	nextpnr-ecp5 --85k --json $^ \
		--lpf ../config/ulx3s_v20.lpf \
		--ignore-loops \
		--textcfg $@


fpga.json: $(VERILOG_SRC)
	yosys -p 'read_verilog $^; synth_ecp5 -json $@'


prog: fpga.bit
	fujprog $^


clean:
	rm -rf fpga.json fpga.config fpga.bit

#=======================================================================
# EOF Makefile
#=======================================================================
