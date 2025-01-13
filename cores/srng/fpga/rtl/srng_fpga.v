//======================================================================
//
// srng_fpga.v
// -----------
// Top level module for test fpga to allow testing of the srng
// core on real HW. In this case the ULX3S board.
//
// The module basically read out data from the core and update
// the LEDs on the board.
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

module srng_fpga(
	             input wire        clk_25mhz,
                 output wire [7:0] led,
                 output wire       wifi_gpio0
	             );

  // ---------------------------------------------------------------
  // Parameters.
  // ---------------------------------------------------------------
  // Wait 2**22 cycles between LED update.
  localparam NUM_WAIT_CYCLES = 32'h00400000;

  localparam CTRL_IDLE        = 3'h0;
  localparam CTRL_WAIT_CYCLES = 3'h1;
  localparam CTRL_READ_STATUS = 3'h1;
  localparam CTRL_READ_DATA   = 3'h2;
  localparam CTRL_UPDATE_LED  = 3'h3;

  // Defined API from srng.v
  localparam ADDR_STATUS             = 8'h09;
  localparam STATUS_READY_BIT        = 0;
  localparam STATUS_ERROR_BIT        = 1;
  localparam ADDR_NUM_DIGESTS        = 8'h0a;
  localparam ADDR_NUM_SAMPLE_CYCLES  = 8'h0b;
  localparam ADDR_DATA               = 8'h10;
  
  
  // ---------------------------------------------------------------
  // Registers.
  // ---------------------------------------------------------------
  reg [31 : 0] cycle_ctr_reg;
  reg [31 : 0] cycle_ctr_new;
  reg          cycle_ctr_we;

  reg          read_srng_data_reg;
  reg          read_srng_data_new;

  reg [31 : 0] core_read_data_reg;
  reg [31 : 0] core_read_data_new;
  reg          core_read_data_we;
  
  reg [7 : 0] led_reg;
  reg         led_we;

  reg [2 : 0] srng_fpga_ctrl_reg;
  reg [2 : 0] srng_fpga_ctrl_new;
  reg         srng_fpga_ctrl_we;
  
  
  // ---------------------------------------------------------------
  // Wires
  // ---------------------------------------------------------------
  // Wires to connect the core.
  reg           core_cs;
  reg           core_we;
  reg  [7 : 0]  core_address;
  reg  [31 : 0] core_write_data;
  wire [31 : 0] core_read_data;
  wire          clk;

  
  // ---------------------------------------------------------------
  // Assignments.
  // ---------------------------------------------------------------
  // Set GPIO0 high to keep ULX3S board from rebooting.
  assign wifi_gpio0 = 1'h1;
  assign clk        = clk_25mhz;
  assign led        = led_reg;
  
  
  // ---------------------------------------------------------------
  // Core instantiation.
  // ---------------------------------------------------------------
  srng srng_inst(
                 .clk(clk),
                 .reset_n(1'h1),
                 .cs(core_cs),
                 .we(core_we),
                 .address(core_address),
                 .write_data(core_write_data),
                 .read_data(core_read_data)
                 );

  
  // ---------------------------------------------------------------
  // reg_update
  // 
  // Note we don't have a reset generator in this module.
  // We probably should.
  // ---------------------------------------------------------------
  always @(posedge clk) 
    begin : reg_update
      cycle_ctr_reg      <= cycle_ctr_new;
      read_srng_data_reg <= read_srng_data_new;

      if (core_read_data_we) begin
        core_read_data_reg <= core_read_data;
      end
      
      if (led_we) begin
        led_reg <= core_read_data_reg[7 : 0]; 
      end
      
      if (srng_fpga_ctrl_we) begin
        srng_fpga_ctrl_reg <= srng_fpga_ctrl_new;
      end
    end

  
  // ---------------------------------------------------------------
  // cycle_ctr
  //
  // Cycle counter that is just used to slow down the LED
  // updates to something a human can observe.
  // ---------------------------------------------------------------
  always @*
    begin : cycle_ctr
      if (cycle_ctr_reg == NUM_WAIT_CYCLES) begin
        read_srng_data_new = 1'h1;
        cycle_ctr_new      = 32'h0;
      end
         
      else begin
        read_srng_data_new = 1'h0;
        cycle_ctr_new      = cycle_ctr_reg + 1;
      end
    end

  
  // ---------------------------------------------------------------
  // srng_fpga_ctrl
  //
  // FSM that controls the use of the core and update
  // of the led register.
  // ---------------------------------------------------------------
  always @*
    begin : srng_fpga_ctrl
      core_read_data_we  = 1'h0;
      led_we             = 1'h0;
      core_cs            = 1'h0;
      core_we            = 1'h0;
      core_address       = 8'h0;
      srng_fpga_ctrl_new = CTRL_IDLE;
      srng_fpga_ctrl_we  = 1'h0;

      case (srng_fpga_ctrl_reg)
        CTRL_IDLE:
          begin
            if (read_srng_data_reg)
              begin
                srng_fpga_ctrl_new = CTRL_READ_STATUS;
                srng_fpga_ctrl_we  = 1'h1;
              end
          end

        CTRL_READ_STATUS:
          begin
            core_cs      = 1'h1;
            core_address = ADDR_STATUS;

            if (core_read_data[STATUS_READY_BIT])
              begin
                srng_fpga_ctrl_new = CTRL_READ_DATA;
                srng_fpga_ctrl_we  = 1'h1;
              end
          end

        CTRL_READ_DATA:
          begin
            core_read_data_we  = 1'h1;
            core_cs            = 1'h1;
            srng_fpga_ctrl_new = CTRL_UPDATE_LED;
            srng_fpga_ctrl_we  = 1'h1;
          end

        CTRL_UPDATE_LED:
          begin
            led_we             = 1'h1;
            srng_fpga_ctrl_new = CTRL_IDLE;
            srng_fpga_ctrl_we  = 1'h1;
          end
      
        default : begin end
      endcase // case (srng_fpga_ctrl_reg)
      
      
    end
  
endmodule // srng_fpga

//======================================================================
// EOF srng_fpga
//======================================================================
