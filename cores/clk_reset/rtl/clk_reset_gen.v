//======================================================================
//
// clk_reset_gen.v
// ---------------
// Clock and reset generator.
// Will include PLL and global net instantiations.
// But right now a simple mapping from an external clock to the
// FPGA-internal clock.
//
//
// (c) 2024 Joachim Strömbergson
//
//======================================================================

`default_nettype none

module clk_reset_gen #(parameter RESET_CYCLES = 100)
  (
   input wire ext_clk,
    
   output wire clk,
   output wire rst_n
   );
  

  //----------------------------------------------------------------
  // Registers with associated wires.
  //----------------------------------------------------------------
  reg [7 : 0] rst_ctr_reg = 8'h0;
  reg [7 : 0] rst_ctr_new;
  reg         rst_ctr_we;

  reg         rst_n_reg = 1'h0;
  reg         rst_n_new;

  wire        clkop;
  wire        locked;
  
  //----------------------------------------------------------------
  // ecp5pll_inst
  // Instantiation of the ecp5 EHXPLL including confuguration
  // We set internal clock to 100 MHz
  //----------------------------------------------------------------
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
            .CLKOP_DIV(6),
            .CLKOP_CPHASE(2),
            .CLKOP_FPHASE(0),
            .FEEDBK_PATH("CLKOP"),
            .CLKFB_DIV(4)
            ) 
  ehxpll_inst(
              .RST(1'b0),
              .STDBY(1'b0),
              .CLKI(ext_clk),
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
  // Concurrent assignment.
  //----------------------------------------------------------------
  assign clk   = clkop;
  assign rst_n = rst_n_reg;


  //----------------------------------------------------------------
  // reg_update.
  //----------------------------------------------------------------
  always @(posedge clkop)
    begin : reg_update
      rst_n_reg <= rst_n_new;
      
      if (rst_ctr_we) begin
        rst_ctr_reg <= rst_ctr_new;
      end
    end


  //----------------------------------------------------------------
  // rst_logic.
  //----------------------------------------------------------------
  always @*
    begin : rst_logic
      rst_n_new   = 1'h1;
      rst_ctr_new = 8'h0;
      rst_ctr_we  = 1'h0;

      if (rst_ctr_reg < RESET_CYCLES) begin
        rst_n_new   = 1'h0;
        rst_ctr_new = rst_ctr_reg + 1'h1;
        rst_ctr_we  = 1'h1;
      end
    end
  
endmodule //clk_reset_gen
  
//======================================================================
// EOF clk_reset_gen.v
//======================================================================
