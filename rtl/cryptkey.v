//======================================================================
//
// cryptkey.v
// ----------
// Top level module of the application FPGA.
// The design exposes a UART interface to allow a host to
// send commands and receive resposes as needed load, execute and
// communicate with applications.
//
//
// Author: Joachim Strombergson
// Copyright (C) 2022 - Tillitis AB
// SPDX-License-Identifier: GPL-2.0-only
//
//======================================================================

`default_nettype none

module cryptkey (
                         input wire clk_25mhz,
                         output wire wifi_gpio0,

                         input wire ftdi_txd,
                         output wire ftdi_rxd,

//                         output wire spi_ss,
//                         output wire spi_sck,
//                         output wire spi_mosi,
//                         input  wire spi_miso,

//                         input  wire app_gpio1,
//                         input  wire app_gpio2,
//                         output wire app_gpio3,
//                         output wire app_gpio4,

                         output [7 : 0] led
//                         output wire led_r,
//                         output wire led_g,
//                         output wire led_b
                        );


  //----------------------------------------------------------------
  // Local parameters
  //----------------------------------------------------------------
  // Top level mem area prefixes.
  localparam ROM_PREFIX = 2'h0;
  localparam RAM_PREFIX = 2'h1;
  localparam RESERVED_PREFIX = 2'h2;
  localparam MMIO_PREFIX = 2'h3;

  // MMIO core sub-prefixes.
  localparam TRNG_PREFIX = 6'h00;
  localparam TIMER_PREFIX = 6'h01;
  localparam UDS_PREFIX = 6'h02;
  localparam UART_PREFIX = 6'h03;
  localparam TOUCH_SENSE_PREFIX = 6'h04;
  localparam FW_RAM_PREFIX = 6'h10;
  localparam CK1_PREFIX = 6'h3f;

  // Instruction used to cause a trap.
  localparam ILLEGAL_INSTRUCTION = 32'h0;


  //----------------------------------------------------------------
  // Registers, memories with associated wires.
  //----------------------------------------------------------------
  reg  [31 : 0] muxed_rdata_reg;
  reg  [31 : 0] muxed_rdata_new;

  reg           muxed_ready_reg;
  reg           muxed_ready_new;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire          clk;
  wire          reset_n;

  /* verilator lint_off UNOPTFLAT */
  wire          cpu_trap;
  wire          cpu_valid;
  wire          cpu_instr;
  wire [03 : 0] cpu_wstrb;
  /* verilator lint_off UNUSED */
  wire [31 : 0] cpu_addr;
  wire [31 : 0] cpu_wdata;

  reg           rom_cs;
  reg  [11 : 0] rom_address;
  wire [31 : 0] rom_read_data;
  wire          rom_ready;

  reg           ram_cs;
  reg  [ 3 : 0] ram_we;
  reg  [15 : 0] ram_address;
  reg  [31 : 0] ram_write_data;
  wire [31 : 0] ram_read_data;
  wire          ram_ready;

  reg           trng_cs;
  reg           trng_we;
  reg  [ 7 : 0] trng_address;
  reg  [31 : 0] trng_write_data;
  wire [31 : 0] trng_read_data;
  wire          trng_ready;

  reg           timer_cs;
  reg           timer_we;
  reg  [ 7 : 0] timer_address;
  reg  [31 : 0] timer_write_data;
  wire [31 : 0] timer_read_data;
  wire          timer_ready;

  reg           uds_cs;
  reg  [ 2 : 0] uds_address;
  wire [31 : 0] uds_read_data;
  wire          uds_ready;

  reg           uart_cs;
  reg           uart_we;
  reg  [ 7 : 0] uart_address;
  reg  [31 : 0] uart_write_data;
  wire [31 : 0] uart_read_data;
  wire          uart_ready;

  reg           fw_ram_cs;
  reg  [ 3 : 0] fw_ram_we;
  reg  [ 8 : 0] fw_ram_address;
  reg  [31 : 0] fw_ram_write_data;
  wire [31 : 0] fw_ram_read_data;
  wire          fw_ram_ready;

  reg           touch_sense_cs;
  reg           touch_sense_we;
  reg  [ 7 : 0] touch_sense_address;
  wire [31 : 0] touch_sense_read_data;
  wire          touch_sense_ready;

  reg           ck1_cs;
  reg           ck1_we;
  reg  [ 7 : 0] ck1_address;
  reg  [31 : 0] ck1_write_data;
  wire [31 : 0] ck1_read_data;
  wire          ck1_ready;
  wire          system_mode;
  wire          force_trap;
  wire [14 : 0] ram_addr_rand;
  wire [31 : 0] ram_data_rand;
  wire          ck1_system_reset;
  /* verilator lint_on UNOPTFLAT */

  wire          tmp_led_r;
  wire          tmp_led_g;
  wire          tmp_led_b;


  //----------------------------------------------------------------
  // Assignments.
  //----------------------------------------------------------------
  assign wifi_gpio0 = 1'h1;
  assign led        = {tmp_led_r, tmp_led_r, tmp_led_g,tmp_led_g,
                       tmp_led_b, tmp_led_b, cpu_addr[5 : 4]};


  //----------------------------------------------------------------
  // Module instantiations.
  //----------------------------------------------------------------
  clk_reset_gen #(
      .RESET_CYCLES(200)
  ) reset_gen_inst (
                    .clk_ref(clk_25mhz),
                    .clk(clk),
                    .rst_n(reset_n)
  );


  picorv32 #(
      .ENABLE_COUNTERS(0),
      .TWO_STAGE_SHIFT(0),
      .CATCH_MISALIGN (0),
      .COMPRESSED_ISA (1),
      .ENABLE_FAST_MUL(1),
      .BARREL_SHIFTER (1)
  ) cpu (
      .clk(clk),
      .resetn(reset_n),
      .trap(cpu_trap),

      .mem_valid(cpu_valid),
      .mem_ready(muxed_ready_reg),
      .mem_addr (cpu_addr),
      .mem_wdata(cpu_wdata),
      .mem_wstrb(cpu_wstrb),
      .mem_rdata(muxed_rdata_reg),
      .mem_instr(cpu_instr),

      // Defined unused ports. Makes lint happy. But
      // we still needs to help lint with empty ports.
      /* verilator lint_off PINCONNECTEMPTY */
      .irq(32'h0),
      .eoi(),
      .trace_valid(),
      .trace_data(),
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


  rom rom_inst (
      .clk(clk),
      .reset_n(reset_n),

      .cs(rom_cs),
      .address(rom_address),
      .read_data(rom_read_data),
      .ready(rom_ready)
  );


//  ram ram_inst (
//      .clk(clk),
//      .reset_n(reset_n),
//
//      .ram_addr_rand(ram_addr_rand),
//      .ram_data_rand(ram_data_rand),
//
//      .cs(ram_cs),
//      .we(ram_we),
//      .address(ram_address),
//      .write_data(ram_write_data),
//      .read_data(ram_read_data),
//      .ready(ram_ready)
//  );


  fw_ram fw_ram_inst (
      .clk(clk),
      .reset_n(reset_n),

      .system_mode(system_mode),

      .cs(fw_ram_cs),
      .we(fw_ram_we),
      .address(fw_ram_address),
      .write_data(fw_ram_write_data),
      .read_data(fw_ram_read_data),
      .ready(fw_ram_ready)
  );


  trng trng_inst (
      .clk(clk),
      .reset_n(reset_n),
      .cs(trng_cs),
      .we(trng_we),
      .address(trng_address),
      .write_data(trng_write_data),
      .read_data(trng_read_data),
      .ready(trng_ready)
  );


  timer timer_inst (
      .clk(clk),
      .reset_n(reset_n),

      .cs(timer_cs),
      .we(timer_we),
      .address(timer_address),
      .write_data(timer_write_data),
      .read_data(timer_read_data),
      .ready(timer_ready)
  );


  uds uds_inst (
      .clk(clk),
      .reset_n(reset_n),

      .system_mode(system_mode),

      .cs(uds_cs),
      .address(uds_address),
      .read_data(uds_read_data),
      .ready(uds_ready)
  );


  uart uart_inst (
      .clk(clk),
      .reset_n(reset_n),

      .rxd(ftdi_txd),
      .txd(ftdi_rxd),

      .cs(uart_cs),
      .we(uart_we),
      .address(uart_address),
      .write_data(uart_write_data),
      .read_data(uart_read_data),
      .ready(uart_ready)
  );


  ck1 ck1_inst (
      .clk(clk),
      .reset_n(reset_n),

      .system_mode(system_mode),

      .cpu_addr  (cpu_addr),
      .cpu_instr (cpu_instr),
      .cpu_valid (cpu_valid),
      .cpu_trap  (cpu_trap),
      .force_trap(force_trap),

      .system_reset(ck1_system_reset),

      .ram_addr_rand(ram_addr_rand),
      .ram_data_rand(ram_data_rand),

//      .spi_ss  (spi_ss),
//      .spi_sck (spi_sck),
//      .spi_mosi(spi_mosi),
//      .spi_miso(spi_miso),

      .led_r(tmp_led_r),
      .led_g(tmp_led_g),
      .led_b(tmp_led_b),

//      .gpio1(app_gpio1),
//      .gpio2(app_gpio2),
//      .gpio3(app_gpio3),
//      .gpio4(app_gpio4),

      .cs(ck1_cs),
      .we(ck1_we),
      .address(ck1_address),
      .write_data(ck1_write_data),
      .read_data(ck1_read_data),
      .ready(ck1_ready)
  );


  //----------------------------------------------------------------
  // Reg_update.
  // Posedge triggered with synchronous, active low reset.
  //----------------------------------------------------------------
  always @(posedge clk) begin : reg_update
    if (!reset_n) begin
      muxed_rdata_reg <= 32'h0;
      muxed_ready_reg <= 1'h0;
    end

    else begin
      muxed_rdata_reg <= muxed_rdata_new;
      muxed_ready_reg <= muxed_ready_new;
    end
  end


  //----------------------------------------------------------------
  // cpu_mem_ctrl
  // CPU memory decode and control logic.
  //----------------------------------------------------------------
  always @* begin : cpu_mem_ctrl
    reg [1 : 0] area_prefix;
    reg [5 : 0] core_prefix;

    area_prefix         = cpu_addr[31 : 30];
    core_prefix         = cpu_addr[29 : 24];

    muxed_ready_new     = 1'h0;
    muxed_rdata_new     = 32'h0;

    rom_cs              = 1'h0;
    rom_address         = cpu_addr[13 : 2];

    ram_cs              = 1'h0;
    ram_we              = 4'h0;
    ram_address         = cpu_addr[17 : 2];
    ram_write_data      = cpu_wdata;

    fw_ram_cs           = 1'h0;
    fw_ram_we           = cpu_wstrb;
    fw_ram_address      = cpu_addr[10 : 2];
    fw_ram_write_data   = cpu_wdata;

    trng_cs             = 1'h0;
    trng_we             = |cpu_wstrb;
    trng_address        = cpu_addr[9 : 2];
    trng_write_data     = cpu_wdata;

    timer_cs            = 1'h0;
    timer_we            = |cpu_wstrb;
    timer_address       = cpu_addr[9 : 2];
    timer_write_data    = cpu_wdata;

    uds_cs              = 1'h0;
    uds_address         = cpu_addr[4 : 2];

    uart_cs             = 1'h0;
    uart_we             = |cpu_wstrb;
    uart_address        = cpu_addr[9 : 2];
    uart_write_data     = cpu_wdata;

    touch_sense_cs      = 1'h0;
    touch_sense_we      = |cpu_wstrb;
    touch_sense_address = cpu_addr[9 : 2];

    ck1_cs              = 1'h0;
    ck1_we              = |cpu_wstrb;
    ck1_address         = cpu_addr[9 : 2];
    ck1_write_data      = cpu_wdata;


    // Two stage mux implementing read and
    // write access performed based on the address
    // from the CPU.
    if (cpu_valid && !muxed_ready_reg) begin
      if (force_trap) begin
        muxed_rdata_new = ILLEGAL_INSTRUCTION;
        muxed_ready_new = 1'h1;
      end
      else begin
        case (area_prefix)
          ROM_PREFIX: begin
            rom_cs          = 1'h1;
            muxed_rdata_new = rom_read_data;
            muxed_ready_new = rom_ready;
          end

          RAM_PREFIX: begin
            ram_cs          = 1'h1;
            ram_we          = cpu_wstrb;
            muxed_rdata_new = 32'hdeaddead;
            muxed_ready_new = 1'h1;
          end

          RESERVED_PREFIX: begin
            muxed_rdata_new = 32'h0;
            muxed_ready_new = 1'h1;
          end

          MMIO_PREFIX: begin
            case (core_prefix)
              TRNG_PREFIX: begin
                trng_cs         = 1'h1;
                muxed_rdata_new = trng_read_data;
                muxed_ready_new = trng_ready;
              end

              TIMER_PREFIX: begin
                timer_cs        = 1'h1;
                muxed_rdata_new = timer_read_data;
                muxed_ready_new = timer_ready;
              end

              UDS_PREFIX: begin
                uds_cs          = 1'h1;
                muxed_rdata_new = uds_read_data;
                muxed_ready_new = uds_ready;
              end

              UART_PREFIX: begin
                uart_cs         = 1'h1;
                muxed_rdata_new = uart_read_data;
                muxed_ready_new = uart_ready;
              end

              TOUCH_SENSE_PREFIX: begin
                touch_sense_cs  = 1'h1;
                muxed_rdata_new = 32'hbeefbeef;
                muxed_ready_new = 1'h1;
              end

              FW_RAM_PREFIX: begin
                fw_ram_cs       = 1'h1;
                muxed_rdata_new = fw_ram_read_data;
                muxed_ready_new = fw_ram_ready;
              end

              CK1_PREFIX: begin
                ck1_cs          = 1'h1;
                muxed_rdata_new = ck1_read_data;
                muxed_ready_new = ck1_ready;
              end

              default: begin
                muxed_rdata_new = 32'h0;
                muxed_ready_new = 1'h1;
              end
            endcase  // case (core_prefix)
          end  // case: MMIO_PREFIX

          default: begin
            muxed_rdata_new = 32'h0;
            muxed_ready_new = 1'h1;
          end
        endcase  // case (area_prefix)
      end
    end
  end

endmodule  // cryptkey

//======================================================================
// EOF cryptkey.v
//======================================================================
