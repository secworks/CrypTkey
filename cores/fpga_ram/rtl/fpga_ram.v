//======================================================================
//
// fpga_ram.v
// ----------
// RAM inplemented inside the FPGA. We start with a fixed memory.
// Currently 4096 x 32 = 16 kByte.
//
// Author: Joachim Strombergson
// Copyright (C) 2024 Assured AB.
//
//======================================================================

`default_nettype none

module fpga_ram(
                input wire           clk,
                input wire           reset_n,

                input  wire          cs,
                input  wire [3 : 0]  we,
                input  wire [11 : 0] address,
                input  wire [31 : 0] write_data,

                output wire [31 : 0] read_data,
                output wire          ready
);
  
  //----------------------------------------------------------------
  // Registers and associated wires.
  //----------------------------------------------------------------
  reg [31 : 0] mem [11  : 0];
  reg          mem_we;

  reg          ready_reg;
  reg          ready_new;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg  [31 : 0] tmp_read_data;
  

  //----------------------------------------------------------------
  // Concurrent assignment of ports.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;
  assign ready     = ready_reg;

  
  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @(posedge clk) 
    begin : reg_update
      if (!reset_n) begin
        ready_reg <= 1'h0;
      end
      
      else begin
        if (cs) begin
          ready_reg <= ready_new;
        end
        
        if (mem_we) begin
          mem[address] <= write_data;
        end
      end
    end
    
    
  //----------------------------------------------------------------
  // rw_logic.
  //----------------------------------------------------------------
  always @* 
    begin : rw_logic
      ready_new = 1'h0;
      mem_we    = 1'h0;
      
      tmp_read_data = mem[address];
      
      if (cs) begin
        ready_new = 1'h1;

        if (we) begin
          mem_we = 1'h1;
        end
      end
    end
  
endmodule  // fpga_ram

//======================================================================
// EOF fpga_ram.v
//======================================================================
