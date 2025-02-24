//======================================================================
//
// rom.v
// ------
// Firmware ROM module. Implemented using Embedded Block RAM
// in the FPGA.
//
//
// Author: Joachim Strombergson
// Copyright (C) 2022 - Tillitis AB
// SPDX-License-Identifier: GPL-2.0-only
//
//======================================================================

`default_nettype none

module rom (
    input wire clk,
    input wire reset_n,

    input  wire          cs,
    /* verilator lint_off UNUSED */
    input  wire [11 : 0] address,
    /* verilator lint_on UNUSED */
    output wire [31 : 0] read_data,
    output wire          ready
);


  //----------------------------------------------------------------
  // Registers, memories with associated wires.
  //----------------------------------------------------------------
  reg [31 : 0] memory[0 : 3071];
  initial $readmemh(`FIRMWARE_HEX, memory);

  reg [31 : 0] rom_rdata;
  reg          ready_reg;


  //----------------------------------------------------------------
  // Concurrent assignments of ports.
  //----------------------------------------------------------------
  assign read_data = rom_rdata;
  assign ready     = ready_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @(posedge clk) begin : reg_update
    if (!reset_n) begin
      ready_reg <= 1'h0;
    end
    else begin
      ready_reg <= cs;
    end
  end  // reg_update


  //----------------------------------------------------------------
  // rom_logic
  //----------------------------------------------------------------
  always @* begin : rom_logic
    /* verilator lint_off WIDTH */
    rom_rdata = memory[address];
    /* verilator lint_on WIDTH */
  end

endmodule  // rom

//======================================================================
// EOF rom.v
//======================================================================
