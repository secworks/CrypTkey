//======================================================================
//
// fw_ram.v
// --------
// A 512 x 32 RAM (2048 bytes) for use by the FW. The memory has
// support for mode based access control.
//
// Author: Joachim Strombergson
// Copyright (C) 2022 - Tillitis AB
// SPDX-License-Identifier: GPL-2.0-only
//
//======================================================================

`default_nettype none

module fw_ram (
    input wire clk,
    input wire reset_n,

    input wire system_mode,

    input  wire          cs,
    input  wire [ 3 : 0] we,
    input  wire [ 8 : 0] address,
    input  wire [31 : 0] write_data,
    output wire [31 : 0] read_data,
    output wire          ready
);


  //----------------------------------------------------------------
  // Registers and wires.
  //----------------------------------------------------------------
  reg [31 : 0] fw_ram_mem [0 : 511];

  reg  [31 : 0] tmp_read_data;
  reg  [31 : 0] mem_read_data0;
  reg  [31 : 0] mem_read_data1;
  reg           ready_reg;
  wire          system_mode_cs;
  reg           bank0;
  reg           bank1;


  //----------------------------------------------------------------
  // Concurrent assignment of ports.
  //----------------------------------------------------------------
  assign read_data      = fw_ram_mem[address];
  assign ready          = ready_reg;
  assign system_mode_cs = cs && ~system_mode;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @(posedge clk) begin : reg_update
    if (!reset_n) begin
      ready_reg <= 1'h0;
    end
    else begin
      ready_reg <= cs;

      if (cs) begin
        if (we) begin
          fw_ram_mem[address] <= write_data;
        end
      end
    end
  end

endmodule  // fw_ram

//======================================================================
// EOF fw_ram.v
//======================================================================
