module trng(
	    input wire        clk_25mhz,
            input wire [6:0]  btn,
            output wire [7:0] led,
            output wire       wifi_gpio0
	   );

  // ---------------------------------------------------------------
  // Parameters.
  // ---------------------------------------------------------------
  localparam ctr_width = 32;
  localparam NUM_ROSC = 32;


  // ---------------------------------------------------------------
  // registers
  // ---------------------------------------------------------------
  reg [7:0]           led_reg;

  reg [ctr_width-1:0] ctr_reg = 0;
  reg [ctr_width-1:0] ctr_new = 0;

  reg rosc0_reg;
  reg rosc1_reg;
  reg rosc_we;

  wire [(NUM_ROSC - 1) : 0] feedback;


  //----------------------------------------------------------------
  // oscillators.
  //
  // 32 single inverters, each connect to itself.
  //----------------------------------------------------------------
  genvar i;
  generate
    for(i = 0 ; i < NUM_ROSC ; i = i + 1)
      begin: ring_oscillators
	(* keep *) LUT4 #(.INIT(16'h1)) rosc (.A(feedback[i]), .B(0), .C(0), .D(0), .Z(feedback[i]));
      end
  endgenerate


  // ---------------------------------------------------------------
  // Assignments
  // ---------------------------------------------------------------
  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;
  assign led        = led_reg;


  always @(posedge clk_25mhz) begin
    ctr_reg        <= ctr_reg + 1;
    led_reg[7]     <= rosc_reg;
    led_reg[6]     <= rosc_reg;
    led_reg[5]     <= rosc_reg;
    led_reg[4]     <= rosc_reg;
    led_reg[3]     <= rosc_reg;
    led_reg[2]     <= rosc_reg;
    led_reg[1]     <= rosc_reg;
    led_reg[0]     <= rosc_reg;

    if (rosc_we) begin
      rosc_reg <= ^feedback;
    end
  end

  always @*
    begin : counter_logic
      ctr_new = ctr_reg;

      if (btn[2]) begin
	ctr_new = ctr_reg + 1;
      end

      if (btn[1]) begin
	ctr_new = ctr_reg + 1;
      end
    end // counter_logic

  always @*
    begin : rosc_sample_logic
      rosc_we = 1'h0;

      if (ctr_reg[21]) begin
	rosc_we = 1'h1;
      end
    end

endmodule // trng
