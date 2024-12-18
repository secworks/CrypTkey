//======================================================================
//
// srng_core.v
// -----------
// Secure random number generator core for CrypTkey.
//
// Author: Joachim Strömbergson// Copyright (c) 2024, Assured AB
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

module srng_rng(
                input wire           clk,
                input wire           reset_n,
                
                input wire           seed,
                input wire           next,

                output wire          error,
                output wire          ready,
                output wire [31 : 0] read_data
              );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // Max number of blocks before reseeding.
  localparam MAX_NUM_BLOCKS = 32'h00000010;

  localparam [2: 0] CTRL_IDLE   = 3'h0;
  localparam [2: 0] CTRL_SEED   = 3'h1;
  localparam [2: 0] CTRL_UPDATE = 3'h3;

  
  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0]   block_word_0_reg;
  reg [31 : 0]   block_word_0_new;
  reg            block_word_0_we;

  reg [31 : 0]   block_word_1_reg;
  reg [31 : 0]   block_word_1_new;
  reg            block_word_1_we;

  reg [31 : 0]   block_word_2_reg;
  reg [31 : 0]   block_word_2_new;
  reg            block_word_2_we;

  reg [31 : 0]   block_word_3_reg;
  reg [31 : 0]   block_word_3_new;
  reg            block_word_3_we;

  reg [31 : 0]   block_word_4_reg;
  reg [31 : 0]   block_word_4_new;
  reg            block_word_4_we;

  reg [31 : 0]   block_word_5_reg;
  reg [31 : 0]   block_word_5_new;
  reg            block_word_5_we;

  reg [31 : 0]   block_word_6_reg;
  reg [31 : 0]   block_word_6_new;
  reg            block_word_6_we;

  reg [31 : 0]   block_word_7_reg;
  reg [31 : 0]   block_word_7_new;
  reg            block_word_7_we;

  reg [31 : 0]   block_word_8_reg;
  reg [31 : 0]   block_word_8_new;
  reg            block_word_8_we;

  reg [31 : 0]   block_word_9_reg;
  reg [31 : 0]   block_word_9_new;
  reg            block_word_9_we;

  reg [31 : 0]   block_word_a_reg;
  reg [31 : 0]   block_word_a_new;
  reg            block_word_a_we;

  reg [31 : 0]   block_word_b_reg;
  reg [31 : 0]   block_word_b_new;
  reg            block_word_b_we;

  reg [31 : 0]   block_word_c_reg;
  reg [31 : 0]   block_word_c_new;
  reg            block_word_c_we;

  reg [31 : 0]   block_word_d_reg;
  reg [31 : 0]   block_word_d_new;
  reg            block_word_d_we;

  reg [31 : 0]   block_word_e_reg;
  reg [31 : 0]   block_word_e_new;
  reg            block_word_e_we;

  reg [31 : 0]   block_word_f_reg;
  reg [31 : 0]   block_word_f_new;
  reg            block_word_f_we;

  reg [31 : 0]  digest_0_mem [0 : 7];
  reg           digest_0_mem_we;

  reg [31 : 0]  digest_1_mem [0 : 7];
  reg           digest_1_mem_we;

  reg           seed_status_reg;
  reg           seed_status_rew;
  reg           seed_status_we;
    
  reg [31 : 0]  digest_ctr_reg;
  reg [31 : 0]  digest_ctr_new;
  reg           digest_ctr_inc;
  reg           digest_ctr_rst;
  reg           digest_ctr_we;

  reg [2 : 0]   digest_word_ctr_reg;
  reg [2 : 0]   digest_word_ctr_new;
  reg           digest_word_ctr_inc;
  reg           digest_word_ctr_rst;
  reg           digest_word_ctr_we;
    
  reg           digest_select_reg;
  reg           digest_select_we;

  reg [2 : 0]   srng_core_ctrl_reg;
  reg [2 : 0]   srng_core_ctrl_new;
  reg           srng_core_ctrl_we;

  
  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg            blake2s_init;
  reg            blake2s_update;
  reg            blake2s_finish;

  wire [511 : 0] blake2s_block;
  wire [255 : 0] blake2w_digest;
  wire           blake2s_ready;

  wire           trng_error;
  wire           trng_ready;
  wire [31 : 0]  trng_data;

  reg            block_seed;
  reg            block_update;
  reg [31 : 0]   tmp_read_data;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign blake2s_block = {block_word_0_reg, block_word_1_reg, 
                          block_word_2_reg, block_word_3_reg, 
                          block_word_4_reg, block_word_5_reg, 
                          block_word_6_reg, block_word_7_reg, 
                          block_word_8_reg, block_word_9_reg, 
                          block_word_a_reg, block_word_b_reg, 
                          block_word_c_reg, block_word_d_reg, 
                          block_word_e_reg, block_word_f_reg};

  assign read_data = tmp_read_data;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  blake2s_core blake2s_core_inst(
				 .clk(clk),
				 .reset_n(reset_n),

				 .init(blake2s_init),
				 .update(blake2s_update),
				 .finish(blak2s_finish),

				 .block(blake2s_block),
				 .blocklen(blake2s_block_len),

				 .digest(blake2s_digest),
				 .ready(blake2s_ready)
				 );


  trng trng_inst(
		 .clk(clk),
		 .reset_n(reset_n),

		 .error(trng_error),

		 .data(trng_data),
		 .ready(trng_ready)
		 );


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < 8 ; i = i + 1) begin
            digest_0_mem <= 32'h0;
            digest_1_mem <= 32'h0;
          end

          block_word_0_reg         <= 32'h0;
          block_word_1_reg         <= 32'h0;
          block_word_2_reg         <= 32'h0;
          block_word_3_reg         <= 32'h0;
          block_word_4_reg         <= 32'h0;
          block_word_5_reg         <= 32'h0;
          block_word_6_reg         <= 32'h0;
          block_word_7_reg         <= 32'h0;
          block_word_8_reg         <= 32'h0;
          block_word_9_reg         <= 32'h0;
          block_word_a_reg         <= 32'h0;
          block_word_b_reg         <= 32'h0;
          block_word_c_reg         <= 32'h0;
          block_word_d_reg         <= 32'h0;
          block_word_e_reg         <= 32'h0;
          block_word_f_reg         <= 32'h0;
          seed_status              <= 1'h0;
          digest_word_ctr_reg      <= 3'h0;
          digest_select_reg        <= 1'h0;
          srng_core_ctrl_reg       <= CTRL_IDLE;
        end
      else
        begin
          if (block_word_0_we) begin
            block_word_0_reg <= block_word_0_new;
          end

          if (block_word_1_we) begin
            block_word_1_reg <= block_word_1_new;
          end

          if (block_word_2_we) begin
            block_word_2_reg <= block_word_2_new;
          end

          if (block_word_3_we) begin
            block_word_3_reg <= block_word_3_new;
          end

          if (block_word_4_we) begin
            block_word_4_reg <= block_word_4_new;
          end

          if (block_word_5_we) begin
            block_word_5_reg <= block_word_5_new;
          end

          if (block_word_6_we) begin
            block_word_6_reg <= block_word_6_new;
          end

          if (block_word_7_we) begin
            block_word_7_reg <= block_word_7_new;
          end

          if (block_word_8_we) begin
            block_word_8_reg <= block_word_8_new;
          end

          if (block_word_9_we) begin
            block_word_9_reg <= block_word_9_new;
          end

          if (block_word_a_we) begin
            block_word_a_reg <= block_word_a_new;
          end

          if (block_word_b_we) begin
            block_word_b_reg <= block_word_b_new;
          end

          if (block_word_c_we) begin
            block_word_c_reg <= block_word_c_new;
          end

          if (block_word_d_we) begin
            block_word_d_reg <= block_word_d_new;
          end

          if (block_word_e_we) begin
            block_word_e_reg <= block_word_e_new;
          end

          if (block_word_f_we) begin
            block_word_f_reg <= block_word_f_new;
          end

          if (digest_0_mem_we) begin
            digest_0_mem[0] <= blake2s_digest[031 : 000];
            digest_0_mem[1] <= blake2s_digest[063 : 032];
            digest_0_mem[2] <= blake2s_digest[095 : 064];
            digest_0_mem[3] <= blake2s_digest[127 : 096];
            digest_0_mem[4] <= blake2s_digest[159 : 128];
            digest_0_mem[5] <= blake2s_digest[191 : 160];
            digest_0_mem[6] <= blake2s_digest[223 : 192];
            digest_0_mem[7] <= blake2s_digest[255 : 224];
          end

          if (digest_1_mem_we) begin
            digest_1_mem[0] <= blake2s_digest[031 : 000];
            digest_1_mem[1] <= blake2s_digest[063 : 032];
            digest_1_mem[2] <= blake2s_digest[095 : 064];
            digest_1_mem[3] <= blake2s_digest[127 : 096];
            digest_1_mem[4] <= blake2s_digest[159 : 128];
            digest_1_mem[5] <= blake2s_digest[191 : 160];
            digest_1_mem[6] <= blake2s_digest[223 : 192];
            digest_1_mem[7] <= blake2s_digest[255 : 224];
          end
          
          if (seed_status_we) begin
            seed_status_reg <= seed_status_new;
          end

          if (digest_ctr_we) begin
            digest_ctr_reg <= digest_ctr_new;
          end
       
          if (digest_word_ctr_we) begin
            digest_word_ctr_reg <= digest_word_ctr_new;
          end
          
          if (digest_select_we) begin
            digest_select_reg <= ~digest_select_reg
          end
          
          if (srng_core_ctrl_we) begin
            srng_core_ctrl_reg <= srng_core_ctrl_new;
          end
          
        end
    end // reg_update

  
  //----------------------------------------------------------------
  // data_select_logic
  //
  // Logic that selects which digest memory and word presented 
  // to the user when reading the data.
  //----------------------------------------------------------------
  always @*
    begin : data_select_logic;
      if ~digest_select_reg begin
        tmp_read_data = digest_0_mem[digest_word_ctr_reg];
      end 
      else begin
        tmp_read_data = digest_1_mem[digest_word_ctr_reg];
      end
    end
      
  
  //----------------------------------------------------------------
  // block_logic
  //
  // Logic that seeds or updates the state block.
  //----------------------------------------------------------------
  always @*
    begin : block_logic
      block_word_0_new = trng_data;
      block_word_0_we = 1'h0;

      block_word_1_new = trng_data;
      block_word_1_we = 1'h0;

      block_word_2_new = trng_data;
      block_word_2_we = 1'h0;

      block_word_3_new = trng_data;
      block_word_3_we = 1'h0;

      block_word_4_new = trng_data;
      block_word_4_we = 1'h0;

      block_word_5_new = trng_data;
      block_word_5_we = 1'h0;

      block_word_6_new = trng_data;
      block_word_6_we = 1'h0;

      block_word_7_new = trng_data;
      block_word_7_we = 1'h0;

      block_word_8_new = trng_data;
      block_word_8_we = 1'h0;

      block_word_9_new = trng_data;
      block_word_9_we = 1'h0;

      block_word_a_new = trng_data;
      block_word_a_we = 1'h0;

      block_word_b_new = trng_data;
      block_word_b_we = 1'h0;

      block_word_c_new = trng_data;
      block_word_c_we = 1'h0;

      block_word_d_new = trng_data;
      block_word_d_we = 1'h0;

      block_word_e_new = trng_data;
      block_word_e_we = 1'h0;

      block_word_f_new = trng_data;
      block_word_f_we = 1'h0;
      
      if (seed_block) begin
        case (block_word_ctr_reg)
          0: block_word_0_we = 1'h1;
          1: block_word_1_we = 1'h1;
          2: block_word_2_we = 1'h1;
          3: block_word_3_we = 1'h1;
          4: block_word_4_we = 1'h1;
          5: block_word_5_we = 1'h1;
          6: block_word_6_we = 1'h1;
          7: block_word_7_we = 1'h1;
          8: block_word_8_we = 1'h1;
          9: block_word_9_we = 1'h1;
          a: block_word_a_we = 1'h1;
          b: block_word_b_we = 1'h1;
          c: block_word_c_we = 1'h1;
          d: block_word_d_we = 1'h1;
          e: block_word_e_we = 1'h1;
          f: block_word_f_we = 1'h1;
        endcase // case (block_word_ctr_reg)
      end

      if (update_block) begin
        block_word_0_new = block0_reg + 1'h1;
        block_word_0_we  = 1'h1;

        block_word_8_new = blake2s_digest[031 : 000];
        block_word_9_we  = 1'h1;

        block_word_8_new = blake2s_digest[063 : 032];
        block_word_9_we  = 1'h1;

        block_word_a_new = blake2s_digest[095 : 064];
        block_word_a_we  = 1'h1;

        block_word_b_new = blake2s_digest[127 : 096];
        block_word_b_we  = 1'h1;

        block_word_c_new = blake2s_digest[159 : 128];
        block_word_c_we  = 1'h1;

        block_word_d_new = blake2s_digest[191 : 160];
        block_word_d_we  = 1'h1;

        block_word_e_new = blake2s_digest[223 : 192];
        block_word_e_we  = 1'h1;

        block_word_f_new = blake2s_digest[255 : 224];
        block_word_f_we  = 1'h1;
      end
    end

  
  //----------------------------------------------------------------
  // digest_ctr
  //
  // Logic that implements the digest counter.
  //----------------------------------------------------------------
  always @*
    begin : digest_ctr
      digest_ctr_new = 32'h0;
      digest_ctr_we  = 1'h0;

      if (digest_ctr_rst) begin
        digest_ctr_new = 32'h0;
        digest_ctr_we  = 1'h1;
      end
      
      if (digest_ctr_inc) begin
        digest_ctr_new = digest_ctr_reg + 1'h1;
        digest_ctr_we  = 1'h1;
      end
    end

  
  //----------------------------------------------------------------
  // digest_word_ctr
  //
  // Logic that implements the digest wordf counter.
  //----------------------------------------------------------------
  always @*
    begin : digest_word_ctr
      digest_word_ctr_new = 3'h0;
      digest_word_ctr_we  = 1'h0;

      if (digest_word_ctr_rst) begin
        digest_word_ctr_new = 3'h0;
        digest_word_ctr_we  = 1'h1;
      end
      
      if (digest_word_ctr_inc) begin
        digest_word_ctr_new = digest_word_ctr_reg + 1'h1;
        digest_word_ctr_we  = 1'h1;
      end
    end

  
  //----------------------------------------------------------------
  // srng_ctrl
  //
  // State machine controlling the srng.
  //----------------------------------------------------------------
  always @*
    begin : api
      block_seed          = 1'h0;
      block_update        = 1'h0;
      blake2s_init        = 1'h0;
      blake2s_next        = 1'h0;
      blake2s_finish      = 1'h0;
      digest_select_we    = 1'h0;
      digest_0_mem_we     = 1'h0;
      digest_1_mem_we     = 1'h0;
      digest_word_ctr_inc = 1'h0;
      digest_word_ctr_rst = 1'h0;
      seed_status_new     = 1'h0;
      seed_status_we      = 1'h0;
      ready_new           = 1'h0;
      ready_we            = 1'h0;
      srng_core_ctrl_new  = CTRL_IDLE;
      srng_core_ctrl_we   = 1'h0;
      
      case (srng_core_ctrl_reg)
        CTRL_IDLE: begin
          if (seed) or (~seed_status_reg) begin
            ready_new           = 1'h0;
            ready_we            = 1'h1;
            srng_core_ctrl_new  = CTRL_SEED0;
            srng_core_ctrl_we   = 1'h1;
          end

          if (next) begin
            digest_word_ctr_inc = 1'h1;
            
            if (digest_word_ctr_reg == 4'h0) begin
              ready_new           = 1'h0;
              ready_we            = 1'h1;
              srng_core_ctrl_new  = CTRL_UPDATE;
              srng_core_ctrl_we   = 1'h1;
            end

            if (digest_word_ctr_reg == 3'hf) begin
              digest_select_we    = 1'h1;
            end
          end
        end

        
        CTRL_SEED: begin
          ready_new           = 1'h1;
          ready_we            = 1'h1;
          seed_status_new     = 1'h1;
          seed_status_we      = 1'h1;
          srng_core_ctrl_new  = CTRL_IDLE;
          srng_core_ctrl_we   = 1'h1;
        end

        
        CTRL_UPDATE: begin
          ready_new           = 1'h1;
          ready_we            = 1'h1;
          srng_core_ctrl_new  = CTRL_IDLE;
          srng_core_ctrl_we   = 1'h1;
        end
        
        default: begin
        end
      endcase // case (srng_core_ctrl_reg)
    end // srng_ctrl

endmodule // srng

//======================================================================
// EOF srng.v
//======================================================================
