#=======================================================================
#
# Makefile
# --------
# Makefile for linting, simulatin and srng core. This includes
# building a working FPGA bitstream for testing on an ULX3S board.
#
# (c) 2024 Joachim Strömbergson
#
#=======================================================================

CORE_SRC_DIR = ../rtl
CORE_SRC = \
	$(CORE_SRC_DIR)/blake2s_m_select.v \
	$(CORE_SRC_DIR)/blake2s_G.v \
	$(CORE_SRC_DIR)/blake2s_core.v \
	$(CORE_SRC_DIR)/srng.v \
	$(CORE_SRC_DIR)/srng_core.v \
	$(CORE_SRC_DIR)/trng.v

FPGA_DIR = ../fpga/rtl
FPGA_SRC = $(FPGA_DIR)/srng_fpga.v $(CORE_SRC)

all: srng_fpga.bit

#-------------------------------------------------------------------
# Module lint ans simulation targets.
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Targets for building a test-fpga that can be programmed
# into the ULX3S.
#-------------------------------------------------------------------
srng_fpga.bit: srng_fpga.config
	ecppack srng_fpga.config srng_fpga.bit


srng_fpga.config: srng_fpga.json
	nextpnr-ecp5 --85k --json $^ \
		--lpf ../fpga/config/ulx3s_v20.lpf \
		--ignore-loops \
		--textcfg $@


srng_fpga.json: $(FPGA_SRC)
	yosys -p 'read_verilog $^; synth_ecp5 -json $@'


prog_fpga: srng_fpga.bit
	fujprog $^


clean:
	rm -rf srng_fpga.json srng_fpga.config srng_fpga.bit


#=======================================================================
# EOF Makefile
#=======================================================================
