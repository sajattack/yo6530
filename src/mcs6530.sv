module mcs6530 (
    input            phi2,
    input            rst_n,
    input            we_n,   // RW Read high/Write low
    input      [9:0] A,      // Address
    input      [7:0] DI,     // Data from processor
    output reg [7:0] DO,     // Data to processor
    output           OE,     // Indicates data driven on DO
    input            RS0,    // ROM select
    output reg [7:0] PAO,    // port A output
    input      [7:0] PAI,    // port A input
    output reg [7:0] PBO,    // port B output
    input      [7:0] PBI,    // port B input
    output reg [7:0] DDRA,   // port A OE (data direction register)
    output reg [7:0] DDRB    // port B OE (data direction register)
);

  logic CS1;

  // FIXME Don't understand what this is supposed to be for yet
  /* verilator lint_off UNUSEDSIGNAL */
  logic CS2;
  /* verilator lint_on UNUSEDSIGNAL */

  logic timer_irq_en;
  logic timer_irq;
  reg [9:0] timer_divider;
  reg [9:0] timer_count;
  reg [7:0] timer;

  reg [7:0] rom_do;
  reg [7:0] ram_do;
  reg [7:0] io_do;
  reg [7:0] timer_do;
  reg rom_oe;
  reg ram_oe;
  reg io_oe;
  reg timer_oe;



  // When a pin is set to an output (direction = 1), make sure
  // the output data is read as such
  logic [7:0] PAI_int, PBI_int;
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin : gen_inputs
      assign PAI_int[i] = DDRA[i] ? PAO[i] : PAI[i];
      assign PBI_int[i] = DDRB[i] ? PBO[i] : PBI[i];
    end
  endgenerate

  assign CS1 = PBI_int[6];
  assign CS2 = PBI_int[5];


  // bruteforce address decoding
  //parameter IOT_BASE = 10'h0;

  logic ram_enable;
  logic rom_enable;
  logic timer_enable;
  logic io_enable;

  always_comb begin
    rom_enable = rst_n & RS0 & CS1;
    ram_enable = rst_n & !RS0 & !CS1 & !A[9] & A[7] & A[6];
    timer_enable = rst_n & !RS0 & !CS1 & A[9] & A[8] & A[7] & A[6] & A[2];
    io_enable = rst_n & !RS0 & !CS1 & A[9] & A[8] & A[7] & A[6] & !A[2];
  end


  always_ff @(posedge phi2) begin
    // reset logic
    if (~rst_n) begin
      PAO <= 8'd0;
      DDRA <= 8'd0;
      PBO <= 8'd0;
      DDRB <= 8'd0;
      timer <= 8'd0;
      timer_divider <= 10'd0;
      timer_count <= 10'd0;
      timer_irq <= 1'd0;
      timer_irq_en <= 1'd0;
    end  // io port logic
    else if (io_enable) begin
      case ({
        we_n, A[2:0]
      })
        4'b0_000: PAO <= DI;  // Write port A
        4'b1_000: {io_oe, io_do} <= {1'b1, PAI_int};  // Read port A
        4'b0_001: DDRA <= DI;  // Write DDRA
        4'b1_001: {io_oe, io_do} <= {1'b1, DDRA};  // Read DDRA
        4'b0_010: PBO <= DI;  // Write port B
        4'b1_010: {io_oe, io_do} <= {1'b1, PBI_int};  // Read port B
        4'b0_011: DDRB <= DI;  // Write DDRB
        4'b1_011: {io_oe, io_do} <= {1'b1, DDRB};  // Read DDRB
        default:  ;
      endcase
    end  //timer logic

    else if (timer_enable) begin  // timer select
      if (~we_n) begin  // write
        timer_irq_en <= A[3];
        timer_irq <= 0;
        timer <= DI - 1;
        // write divider based on address lines
        case (A[1:0])
          2'b00:   timer_divider <= 10'd0;
          2'b01:   timer_divider <= 10'd7;
          2'b10:   timer_divider <= 10'd63;
          2'b11:   timer_divider <= 10'd1023;
          default: ;
        endcase
      end else if (~A[0]) begin
        timer_irq_en <= A[3];
        timer_do <= timer;
        timer_oe <= 1'b1;
        if (timer != 0) timer_irq <= 0;
      end else begin
        timer_do <= {7'd0, timer_irq};
        timer_oe <= 1'b0;
      end
    end

    if (timer_count == timer_divider) begin
      timer <= timer - 1;
      timer_count <= 0;
      if (timer == 8'd0) begin
        timer_divider <= 10'd0;
        timer_irq <= 1'd1;
      end else begin
        timer_count <= timer_count + 1;
        PBO[7] <= ~(timer_irq & timer_irq_en);
      end
    end
  end

  ram ram0 (
      .clk(phi2),
      .we_n(we_n),
      .A(A[5:0]),
      .DI(DI),
      .DO(ram_do),
      .OE(ram_oe)
  );

  rom rom0 (
      .clk(phi2),
      .A  (A),
      .DO (rom_do),
      .OE (rom_oe)
  );

  always_comb begin
    if (ram_enable) begin
      DO = ram_do;
      OE = ram_oe;
    end else if (rom_enable) begin
      DO = rom_do;
      OE = rom_oe;
    end else if (timer_enable) begin
      DO = timer_do;
      OE = timer_oe;
    end else if (io_enable) begin
      DO = io_do;
      OE = io_oe;
    end else begin
      {OE, DO} = {1'b0, 8'bxxxxxxxx};
    end
  end
  ;


endmodule

