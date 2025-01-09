//======================================================================
//
// srng.v
// ------
// Secure random number generator for the CrypTkey.
//
// Author: Joachim Strömbergson
// Copyright (c) 2025 Assured AB
//
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module srng(
            input wire           clk,
            input wire           reset_n,
            
            input wire           cs,
            input wire           we,
            
            input wire  [7 : 0]  address,
            input wire  [31 : 0] write_data,
            output wire [31 : 0] read_data
           );
  

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // API
  localparam ADDR_CTRL               = 8'h08;
  localparam CTRL_RESEED_BIT         = 0;
  localparam ADDR_STATUS             = 8'h09;
  localparam STATUS_READY_BIT        = 0;
  localparam STATUS_ERROR_BIT        = 1;
  localparam ADDR_NUM_DIGESTS        = 8'h0a;
  localparam ADDR_NUM_SAMPLE_CYCLES  = 8'h0b;
  localparam ADDR_DATA               = 8'h10;

  // Default config values.
  localparam DEFAULT_MAX_NUM_DIGESTS   = 32'h00ffffff;
  localparam DEFAULT_NUM_SAMPLE_CYCLES = 16'h0400;

  
  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg          next_reg;
  reg          next_new;
  reg          reseed_reg;
  reg          reseed_new;
  reg [31: 0]  num_digests_reg;
  reg          num_digests_we;
  reg [31: 0]  num_sample_cycles_reg;
  reg          num_sample_cycles_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire           core_error;
  wire           core_ready;
  wire [31 : 0]  core_srng_data;

  reg [31 : 0]   tmp_read_data;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  srng_core srng_core_inst(
				           .clk(clk),
				           .reset_n(reset_n),
                           
				           .next(next_reg),
				           .reseed(reseed_reg),
                
                           .num_digests(num_digests_reg),
                           .num_sample_cycles(num_sample_cycles_reg),
                           
                           .error(core_error),
                           .ready(core_ready),
                           .srng_data(core_srng_data)
				           );


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
		  next_reg          <= 1'h0;
		  reseed_reg        <= 1'h0;
          num_digests_reg <= DEFAULT_MAX_NUM_DIGESTS;
          num_cycles_reg  <= DEFAULT_NUM_CYCLES;
        end

      else
        begin
          next_reg   <= next_new;
          reseed_reg <= reseed_new;

          if (num_digests_we) begin
            num_digests_reg <= write_data;
          end

          if (num_sample_cycles_we) begin
            num_sample_cycles_reg <= write_data[15 : 0];
          end
        end
    end // reg_update


  //----------------------------------------------------------------
  // api
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      next_new             = 1'h0;
      reseed_new           = 1'h0;
      num_digests_we       = 1'h0;
      num_sample_cycles_we = 1'h0;
      tmp_read_data        = 32'h0;
      
      if (cs)
        begin
          if (we) 
            begin
              if (address == ADDR_CTRL) begin
                reseed_new = write_data[CTRL_RESEED_BIT];
              end

              if (address == ADDR_NUM_DIGESTS) begin
                num_digests_we = 1'h1;
              end

              if (address == ADDR_NUM_SAMPLE_CYCLES) begin
                num_sample_cycles_we = 1'h1;
              end

          else
            begin
              if (address == ADDR_STATUS) begin
                tmp_read_data[STATUS_READY_BIT] = core_ready;
                tmp_read_data[STATUS_ERROR_BIT] = core_error;
              end

              if (address == ADDR_NUM_DIGESTS) begin
                tmp_read_dat = num_digests_reg;
              end

              if (address == ADDR_NUM_SAMPLE_CYCLES) begin
                tmp_read_dat = num_sample_cycles_reg;
              end

              if (address == ADDR_DATA) begin
                tmp_read_dat = core_srng_data;
                next_new     = 1'h1;
              end
            end
        end
    end // api
endmodule // srng

//======================================================================
// EOF srng.v
//======================================================================
