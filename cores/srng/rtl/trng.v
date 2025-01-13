//======================================================================
//
// trng.v 
// ------ Ring oscillator based true random number generator
// (a.k.a. a source of entropy).
//
// Based on the difference in intrinsic frequency of digital ring
// oscillators, the trng collects jitter Asauming that the user aways checks
// the ready flag before reading the coree should be able to delicer a
// word.
//
// Do NOT use this core directly as a random number generator. Instead
// use it to seed a proper, random number generator. This will ensure
// that you wcan control the excected distribution, the security level
// you need and the data capacity ypu need.
//
//
// Author: Joachim Strömbergson
// Copyright (c) 2024, Amagicom AB
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

module trng(
	        input wire           clk,
            input wire           reset_n,
            input wire [15 : 0]  num_sample_cycles,

            output wire          error,
            input wire           ack_error,

            output wire [31 : 0] data,
            input wire           ack_data,
            output wire          ready,
	        );

  
  // ---------------------------------------------------------------
  // Parameters.
  // ---------------------------------------------------------------
  localparam ctr_width = 32;
  localparam NUM_ROSC = 32;

  localparam BITS_BETWEEN_READY = 32;
  localparam MAC_RUN_LENGTH     = 30;

  
  // ---------------------------------------------------------------
  // Registers.
  // ---------------------------------------------------------------
  reg [ctr_width-1:0] ctr_reg = 0;
  reg [ctr_width-1:0] ctr_new = 0;
  
  reg [31 : 0]  data_shift_reg;
  reg           data_shift_we;

  reg [15 : 0]  cycle_ctr_reg;
  reg [15 : 0]  cycle_ctr_new;

  reg [5 : 0]   bit_ctr_reg;
  reg [5 : 0]   bit_ctr_new;
  reg           bit_ctr_we;

  reg [5 : 0]   run_length_ctr_reg;
  reg [5 : 0]   run_length_ctr_new;
  reg           run_length_ctr_we;

  reg           bit_sampled_reg;
  reg           bit_sampled_new;

  reg           rosc_bit_reg;
  reg           rosc_bit_new;
  reg           rosc_bit_we;
  
  reg           previous_bit_reg;
  reg           previous_bit_new;
  reg           previous_bit_we;
  
  reg           error_reg;
  reg           error_new;
  reg           error_we;

  reg           ready_reg;
  reg           ready_new;
  reg           ready_we;

  
  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire [(NUM_ROSC - 1) : 0] feedback;


  //----------------------------------------------------------------
  // Assignments.
  //----------------------------------------------------------------
  // TODO: Add output from run length counter.
  assign error = error_reg;
  assign ready = ready_reg & ~error_reg;
  assign data  = data_shift_reg;

  
  //----------------------------------------------------------------
  // ring_oscillators
  //
  // 32 digital inverters, each connected to itself. 
  // This creates combinational loops which creates digital
  // oscillators.
  //----------------------------------------------------------------
  genvar i;
  generate
    for(i = 0 ; i < NUM_ROSC ; i = i + 1)
      begin: ring_oscillators
	    (* keep *) LUT4 #(.INIT(16'h1)) rosc (.A(feedback[i]), .B(0), .C(0), .D(0), .Z(feedback[i]));
      end
  endgenerate


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      if (!reset_n)
        begin
          data_shift_reg     <= 32'h0;
          cycle_ctr_reg      <= 32'h0;
          bit_sampled_reg    <= 1'h0;
          bit_ctr_reg        <= 6'h0;
          run_length_ctr_reg <= 6'h0;
          previous_bit_reg   <= 1'h0;
          error_reg          <= 1'h0;
          ready_reg          <= 1'h0;
        end

      else 
        begin
          cycle_ctr_reg   <= cycle_ctr_new;
          bit_sampled_reg <= bit_sampled_new;
                             
          if (bit_ctr_we) begin
            bit_ctr_reg <= bit_ctr_new;
          end
                             
          if (run_length_ctr_we) begin
            run_length_ctr_reg <= run_length_ctr_new;
          end
          
          if (data_shift_we) begin
            data_shift_reg <= {data_shift_reg[30 : 0], rosc_bit_reg};
          end

          if (rosc_bit_we) begin
            rosc_bit_reg <= rosc_bit_new;
          end
          
          if (previous_bit_we) begin
            previous_bit_reg <= previous_bit_new;
          end

          if (error_we) begin
            error_reg <= error_new;
          end

          if (ready_we) begin
            ready_reg <= ready_new;
          end
        end
    end

  
  //----------------------------------------------------------------
  // rosc_sample
  //
  // Logic that implements sampling of oscillators after a given
  // number of cycles.
  //----------------------------------------------------------------
  always @*
    begin : rosc_sample
      bit_sampled_new = 1'h0;
      rosc_bit_we     = 1'h0;
      
      // Xor combine rosc outputs to create a single bit.
      rosc_bit_new = ^feedback;

      // Free running cycle counter.
      cycle_ctr_new = cycle_ctr_reg + 1'h1;
      
      if (cycle_ctr_reg == num_sample_cycles) begin
        cycle_ctr_new   = 16'h0;
        rosc_bit_we     = 1'h1;
        bit_sampled_new = 1'h1;
      end // rosc_sample
    end

  
  //----------------------------------------------------------------
  // error
  //
  // Logic that implements the error detection, error signalling
  // and handling of error acknowledge.
  //----------------------------------------------------------------
  always @*
    begin : error
      previous_bit_we    = 1'h0;
      error_new          = 1'h0;
      error_we           = 1'h1;
      run_length_ctr_new = 6'h0;
      run_length_ctr_we  = 1'h0;

      previous_bit_new = rosc_bit_reg;
      
      if (bit_sampled_reg) begin
        previous_bit_we = 1'h1;
        
        if (previous_bit_reg == rosc_bit_reg) begin
          run_length_ctr_new = run_length_ctr_reg + 1'h1;
        end
        else begin
          run_length_ctr_new = 6'h0;
          run_length_ctr_we  = 1'h1;
        end
      end
      
      if (run_length_ctr_reg == MAX_RUN_LENGTH) begin
        error_new          = 1'h1;
        error_we           = 1'h1;
      end
      
      if (error_ack) begin
        error_new          = 1'h0;
        error_we           = 1'h1;
        run_length_ctr_new = 6'h0;
        run_length_ctr_we  = 1'h1;
      end
    end

  
  //----------------------------------------------------------------
  // data_ready
  //
  // Logic that implements the data shift register, the bit counter, 
  // the ready signal and data read acknowledge.
  //----------------------------------------------------------------
  always @*
    begin : ready
      data_shift_we = 1'h0;
      bit_ctr_new   = 6'h0;
      bit_ctr_we    = 1'h1;
      ready_new     = 1'h0;
      ready_we      = 1'h0;

      if (bit_sampled_reg) begin
        data_shift_we = 1'h1;
        bit_ctr_new   = bit_ctr_reg + 1'h1;
        bit_ctr_we    = 1'h1;
      end

      if (bit_ctr_reg == (BITS_BETWEEN_READY - 1)) begin
        ready_new = 1'h1;
        ready_we  = 1'h1;
      end

      if (ack_data) begin
        ready_new   = 1'h0;
        ready_we    = 1'h1;
        bit_ctr_new = 6'h0;
        bit_ctr_we  = 1'h1;
      end
    end // data_ready
  
endmodule // trng

//======================================================================
// EOF trng.v
//======================================================================
