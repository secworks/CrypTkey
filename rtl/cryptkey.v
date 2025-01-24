//======================================================================
//
// cryptkey.v
// ----------
// Top level module of the CrypTkey FPGA.
// Based of the application_fpga from the Tkey.
//
//
// (c) 2024 Joachim Strömbergson
//
//======================================================================

`default_nettype none

module cryptkey(
                input wire clk_25mhz,

                input wire ftdi_txd,
                output wire ftdi_rxd,

                output wire wifi_gpio0,

                output [7 : 0] led
                );


  //----------------------------------------------------------------
  // Local parameters
  //----------------------------------------------------------------
  // Top level mem area prefixes.
  localparam ROM_PREFIX      = 2'h0;
  localparam RAM_PREFIX      = 2'h1;
  localparam RESERVED_PREFIX = 2'h2;
  localparam CORE_PREFIX     = 2'h3;

  // Core sub-prefixes.
  localparam TRNG_PREFIX        = 6'h00;
  localparam TIMER_PREFIX       = 6'h01;
  localparam UDS_PREFIX         = 6'h02;
  localparam UART_PREFIX        = 6'h03;
  localparam TOUCH_SENSE_PREFIX = 6'h04;
  localparam FPGA_RAM_PREFIX    = 6'h10;

  localparam AES_PREFIX         = 6'h18;
  localparam BLAKE2S_PREFIX     = 6'h20;
  localparam SHA256_PREFIX      = 6'h21;
  localparam ED25519_PREFIX     = 6'h28;

  localparam CT_PREFIX          = 6'h3f;


  //----------------------------------------------------------------
  // Registers, memories with associated wires.
  //----------------------------------------------------------------
  reg [31 : 0] muxed_rdata_reg;
  reg [31 : 0] muxed_rdata_new;

  reg          muxed_ready_reg;
  reg          muxed_ready_new;

  reg [31 : 0] led_ctr_reg;

  reg          ftdi_rxd_reg;
  reg          ftdi_rxd_new;
  reg          ftdi_rxd_we;

  reg          ftdi_txd_reg;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire          clk;
  wire          rst_n;

  /* verilator lint_off UNOPTFLAT */
  wire          cpu_trap;
  wire          cpu_valid;
  wire          cpu_instr;
  wire [3 : 0]  cpu_wstrb;
  /* verilator lint_off UNUSED */
  wire [31 : 0] cpu_addr;
  wire [31 : 0] cpu_wdata;

//  reg           ct_cs;
//  reg           ct_we;
//  reg  [7 : 0]  ct_address;
//  reg [31 : 0]  ct_write_data;
//  wire [31 : 0] ct_read_data;
//  wire          ct_ready;

//  reg           rom_cs;
//  reg  [11 : 0] rom_address;
//  wire [31 : 0] rom_read_data;
//  wire          rom_ready;

//  reg           ram_cs;
//  reg  [ 3 : 0] ram_we;
//  reg  [15 : 0] ram_address;
//  reg  [31 : 0] ram_write_data;
//  wire [31 : 0] ram_read_data;
//  wire          ram_ready;

//  reg           trng_cs;
//  reg           trng_we;
//  reg  [ 7 : 0] trng_address;
//  reg  [31 : 0] trng_write_data;
//  wire [31 : 0] trng_read_data;
//  wire          trng_ready;

  reg           timer_cs;
  reg           timer_we;
  reg  [ 7 : 0] timer_address;
  reg  [31 : 0] timer_write_data;
  wire [31 : 0] timer_read_data;
  wire          timer_ready;

//  reg           uart_cs;
//  reg           uart_we;
//  reg  [7 : 0]  uart_address;
//  reg  [31 : 0] uart_write_data;
//  wire [31 : 0] uart_read_data;
//  wire          uart_ready;

  reg           fpga_ram_cs;
  reg  [3 : 0]  fpga_ram_we;
  reg  [11 : 0] fpga_ram_address;
  reg  [31 : 0] fpga_ram_write_data;
  wire [31 : 0] fpga_ram_read_data;
  wire          fpga_ram_ready;
  /* verilator lint_on UNOPTFLAT */


  //----------------------------------------------------------------
  // Port assignments.
  //----------------------------------------------------------------
  // Need to assign this to not reset the device.
  assign wifi_gpio0 = 1'h1;
  assign led        = led_ctr_reg[27 : 20];
  assign ftdi_rxd   = ftdi_rxd_reg;


  //----------------------------------------------------------------
  // Module instantiations.
  //----------------------------------------------------------------
  clk_reset_gen #(
                  .RESET_CYCLES(100)
                  )
  clk_reset_gen_inst(
                     .ext_clk(clk_25mhz),
                     .clk(clk),
                     .rst_n(rst_n)
                     );


  picorv32 #(
             .ENABLE_COUNTERS(0),
             .TWO_STAGE_SHIFT(0),
             .CATCH_MISALIGN(0),
             .COMPRESSED_ISA(1),
             .ENABLE_FAST_MUL(1),
             .BARREL_SHIFTER(1)
             )
  cpu_inst(
           .clk(clk_25mhz),
           .resetn(1'h1),
           .trap(cpu_trap),

           .mem_valid(cpu_valid),
           .mem_ready(muxed_ready_reg),
           .mem_addr (cpu_addr),
           .mem_wdata(cpu_wdata),
           .mem_wstrb(cpu_wstrb),
           .mem_rdata(muxed_rdata_reg),

           // Defined unused ports. Makes lint happy. But
           // we still needs to help lint with empty ports.
           /* verilator lint_off PINCONNECTEMPTY */
           .irq(32'h0),
           .eoi(),
           .trace_valid(),
           .trace_data(),
           .mem_instr(cpu_instr),
           .mem_la_read(),
           .mem_la_write(),
           .mem_la_addr(),
           .mem_la_wdata(),
           .mem_la_wstrb(),
           .pcpi_valid(),
           .pcpi_insn(),
           .pcpi_rs1(),
           .pcpi_rs2(),
           .pcpi_wr(1'h0),
           .pcpi_rd(32'h0),
           .pcpi_wait(1'h0),
           .pcpi_ready(1'h0)
           /* verilator lint_on PINCONNECTEMPTY */
           );
//
//
//  rom rom_inst(
//               .clk(clk),
//               .rst_n(rst_n),
//
//               .cs(rom_cs),
//               .address(rom_address),
//               .read_data(rom_read_data),
//         .ready(rom_ready)
//               );

  fpga_ram fpga_ram_inst(
                         .clk(clk),
                         .rst_n(rst_n),

                         .cs(fpga_ram_cs),
                         .we(fpga_ram_we),
                         .address(fpga_ram_address),
                         .write_data(fpga_ram_write_data),
                         .read_data(fpga_ram_read_data),
                         .ready(fpga_ram_ready)
                         );

  timer timer_inst (
                    .clk(clk),
                    .reset_n(rst_n),

                    .cs(timer_cs),
                    .we(timer_we),
                    .address(timer_address),
                    .write_data(timer_write_data),
                    .read_data(timer_read_data),
                    .ready(timer_ready)
                    );


  //----------------------------------------------------------------
  // Reg_update.
  // Posedge triggered with synchronous, active low reset.
  //----------------------------------------------------------------
  always @(posedge clk)
    begin : reg_update
      if (!rst_n) begin
        muxed_rdata_reg <= 32'h0;
        muxed_ready_reg <= 1'h0;
        led_ctr_reg     <= 32'h0;
        ftdi_rxd_reg    <= 1'h0;
        ftdi_txd_reg    <= 1'h0;
      end

      else begin
        ftdi_txd_reg    <= ftdi_txd;
        muxed_rdata_reg <= muxed_rdata_new;
        muxed_ready_reg <= muxed_ready_new;
        led_ctr_reg     <= led_ctr_reg + 1'h1;

        if (ftdi_rxd_we) begin
          ftdi_rxd_reg <= ftdi_rxd_new;
        end
      end
    end


  //----------------------------------------------------------------
  // cpu_mem_ctrl
  // CPU memory decode and control logic.
  //----------------------------------------------------------------
  always @*
    begin : cpu_mem_ctrl
      reg [1 : 0] area_prefix;
      reg [5 : 0] core_prefix;

      area_prefix         = cpu_addr[31 : 30];
      core_prefix         = cpu_addr[29 : 24];

      muxed_ready_new     = 1'h0;
      muxed_rdata_new     = 32'h0;

//      rom_cs              = 1'h0;
//      rom_address         = cpu_addr[13 : 2];

      fpga_ram_cs         = 1'h0;
      fpga_ram_we         = cpu_wstrb;
      fpga_ram_address    = cpu_addr[13 : 2];
      fpga_ram_write_data = cpu_wdata;

      timer_cs            = 1'h0;
      timer_we            = |cpu_wstrb;
      timer_address       = cpu_addr[9 : 2];
      timer_write_data    = cpu_wdata;

//      ct_cs               = 1'h0;
//      ct_we               = cpu_wstrb;
//      ct_address          = cpu_addr[10 : 2];
//      ct_write_data       = cpu_wdata;

//      uart_cs             = 1'h0;
//      uart_we             = |cpu_wstrb;
//      uart_address        = cpu_addr[9 : 2];
//      uart_write_data     = cpu_wdata;

      case (area_prefix)
//        ROM_PREFIX: begin
//          rom_cs          = 1'h1;
//          muxed_rdata_new = rom_read_data;
//          muxed_ready_new = rom_ready;
//        end

        RESERVED_PREFIX: begin
          muxed_rdata_new = 32'h0;
          muxed_ready_new = 1'h1;
        end

        CORE_PREFIX: begin
          case (core_prefix)

//	    CT_PREFIX: begin
//              ct_cs           = 1'h1;
//              muxed_rdata_new = led_ctr_reg;
//              muxed_ready_new = 1'h1;
//	    end

	    FPGA_RAM_PREFIX: begin
              fpga_ram_cs     = 1'h1;
              muxed_rdata_new = fpga_ram_read_data;
              muxed_ready_new = fpga_ram_ready;
	    end

//	    UART_PREFIX: begin
//              ftdi_rxd_new    = cpu_wdata[0];
//              ftdi_rxd_we     = ct_we;
//              muxed_rdata_new = ftdi_txd_reg;
//              muxed_ready_new = 1'h1;
//	    end

            TIMER_PREFIX: begin
              timer_cs        = 1'h1;
              muxed_rdata_new = timer_read_data;
              muxed_ready_new = timer_ready;
            end

	    default: begin
	      muxed_rdata_new = 32'h0;
	      muxed_ready_new = 1'h1;
	    end
          endcase // case (core_prefix)
        end // CORE_PREFIX

        default: begin
          muxed_rdata_new = 32'h0;
          muxed_ready_new = 1'h1;
        end
      endcase // case (area_prefix)
	end


endmodule // cryptkey

//======================================================================
// EOF cryptkey.v
//======================================================================
