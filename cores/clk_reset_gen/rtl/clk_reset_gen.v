//======================================================================
//
// clk_reset_gen.v
// -----------
// Clock and reset generator used in the Tillitis Key 1 design.
// This module instantiate the internal SB_HFOSC clock source in the
// Lattice ice40 UP device. It then connects it to the PLL, and
// finally connects the output from the PLL to the global clock net.
//
//
// Author: Joachim Strombergson
// Copyright (C) 2022 - Tillitis AB
// SPDX-License-Identifier: GPL-2.0-only
//
//======================================================================

`default_nettype none

module clk_reset_gen #(
    parameter RESET_CYCLES = 100
) (
   input wire clk_ref,
   input wire sys_reset,

   output wire clk,
   output wire rst_n
   );


  //----------------------------------------------------------------
  // Registers with associated wires.
  //----------------------------------------------------------------
  reg  [7 : 0] rst_ctr_reg = 8'h0;
  reg  [7 : 0] rst_ctr_new;
  reg          rst_ctr_we;

  reg          rst_n_reg = 1'h0;
  reg          rst_n_new;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire        clkop;
  wire        locked;


  //----------------------------------------------------------------
  // Concurrent assignment.
  //----------------------------------------------------------------
  assign rst_n = rst_n_reg;
  assign clk = clkop;


  //----------------------------------------------------------------
  // Core instantiations.
  //----------------------------------------------------------------
  /* verilator lint_off PINMISSING */
  (* FREQUENCY_PIN_CLKI="25" *)
  (* FREQUENCY_PIN_CLKOP="100" *)
  (* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
  EHXPLLL #(
            .PLLRST_ENA("DISABLED"),
            .INTFB_WAKE("DISABLED"),
            .STDBY_ENABLE("DISABLED"),
            .DPHASE_SOURCE("DISABLED"),
            .OUTDIVIDER_MUXA("DIVA"),
            .OUTDIVIDER_MUXB("DIVB"),
            .OUTDIVIDER_MUXC("DIVC"),
            .OUTDIVIDER_MUXD("DIVD"),
            .CLKI_DIV(1),
            .CLKOP_ENABLE("ENABLED"),
            .CLKOP_DIV(12),
            .CLKOP_CPHASE(2),
            .CLKOP_FPHASE(0),
            .FEEDBK_PATH("CLKOP"),
            .CLKFB_DIV(2)
            )
  ehxpll_inst(
              .RST(1'b0),
              .STDBY(1'b0),
              .CLKI(clk_ref),
              .CLKOP(clkop),
              .CLKFB(clkop),
              .CLKINTFB(),
              .PHASESEL0(1'b0),
              .PHASESEL1(1'b0),
              .PHASEDIR(1'b1),
              .PHASESTEP(1'b1),
              .PHASELOADREG(1'b1),
              .PLLWAKESYNC(1'b0),
              .ENCLKOP(1'b0),
              .LOCK(locked)
              );


  //----------------------------------------------------------------
  // reg_update.
  //----------------------------------------------------------------
  always @(posedge clk) begin : reg_update
    rst_n_reg     <= rst_n_new;

    if (rst_ctr_we) begin
      rst_ctr_reg <= rst_ctr_new;
    end
  end


  //----------------------------------------------------------------
  // rst_logic.
  //----------------------------------------------------------------
  always @* begin : rst_logic
    rst_n_new   = 1'h1;
    rst_ctr_new = 8'h0;
    rst_ctr_we  = 1'h0;

    if (rst_ctr_reg < RESET_CYCLES) begin
      rst_n_new   = 1'h0;
      rst_ctr_new = rst_ctr_reg + 1'h1;
      rst_ctr_we  = 1'h1;
    end
  end

endmodule  // clk_reset_gen

//======================================================================
// EOF clk_reset_gen.v
//======================================================================
