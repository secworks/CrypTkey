# fpga_ram
RAM implemented inside the FPGA.


## Introduction
This core implements a RAM using the FPGA block memories. The purpose is to store code and data that either needs access latencty than an external SDRAM, or should not be exposed outside of the FPGA.


## API
The core currently does not have an API.
If needed it would probably be intergrated as part of the memory space.


## Implementation Details
The core is implemented by implicitly instatiating a number of sysMEM Embedded Block RAMs.


The contents of the fw_ram is cleared when the FPGA is powered up and
configured by the bitstream. The contents is not cleared by a system
reset.

If the fw_app_mode input is set, no memory accesses are allowed. Any
reads when the fw_app_mode is set will retun an all zero word.
