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
   output wire rst_n,
   );


  //----------------------------------------------------------------
  // Registers with associated wires.
  //----------------------------------------------------------------
  reg [7 : 0] rst_ctr_reg = 8'h0;
  reg [7 : 0] rst_ctr_new;
  reg         rst_ctr_we;

  reg         rst_n_reg = 1'h0;
  reg         rst_n_new;

  wire        hfosc_clk;
  wire        pll_clk;


  //----------------------------------------------------------------
  // Concurrent assignment.
  //----------------------------------------------------------------
  assign clk   = ext_clk;
  assign rst_n = rst_n_reg;


  //----------------------------------------------------------------
  // reg_update.
  //----------------------------------------------------------------
    always @(posedge clk)
      begin : reg_update
        rst_n_reg <= rst_n_new;

        if (rst_ctr_we)
          rst_ctr_reg <= rst_ctr_new;
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

endmodule clk_reset_gen

//======================================================================
// EOF clk_reset_gen.v
//======================================================================
