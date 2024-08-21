`define MOS6530_003=1

module mcs6530 (
    input            phi2,
    input            rst_n,
    input            we_n,   // RW Read high/Write low
    input      [9:0] A,      // Address
    input      [7:0] DI,     // Data from processor
    output reg [7:0] DO,     // Data to processor
    output           OE,     // Indicates data driven on DO
    input            RS0,    // ROM select, might need to be inverted?
    output reg [7:0] PAO,    // port A output
    input      [7:0] PAI,    // port A input
    output reg [7:0] PBO,    // port B output
    input      [7:0] PBI,    // port B input
    output reg [7:0] DDRA,   // port A OE (data direction register)
    output reg [7:0] DDRB,   // port B OE (data direction register)
    input CS1,
    output IRQ,
    output IRQ_EN
);

  /* verilator lint_off UNUSEDSIGNAL */
  logic CS2; // CS2 is not used on 6530-002 or 6530-003
             // see here http://retro.hansotten.nl/6502-sbc/6530-6532/6530-replacement-kim-1/
  /* verilator lint_on UNUSEDSIGNAL */


  reg [7:0] rom_do;
  reg [7:0] ram_do;
  reg [7:0] io_do;
  reg [7:0] timer_do;
  reg rom_oe;
  reg ram_oe;
  reg io_oe;
  reg timer_oe;

  logic ram_enable;
  logic rom_enable;
  logic timer_enable;
  logic io_enable;

  always_comb begin
    rom_enable = rst_n & !RS0 & CS1;
    `ifdef MOS6530_002
        ram_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & A[7] & A[6];
        io_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & A[7] & A[6] & !A[2];
        timer_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & A[7] & A[6] & A[2];
    `endif
    `ifdef MOS6530_003
        ram_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & A[7] & ~A[6];
        io_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & ~A[7] & ~A[6] & !A[2];
        timer_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & ~A[7] & ~A[6] & A[2];
    `endif

  end


  always_ff @(posedge phi2) begin
    // reset logic
    if (~rst_n) begin
      PAO <= 8'd0;
      DDRA <= 8'd0;
      PBO <= 8'd0;
      DDRB <= 8'd0;
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

  timer timer0 (
      .enable (timer_enable),
      .clk  (phi2),
      .rst_n  (rst_n),
      .we_n  (we_n),
      .A  ({A [ 3 ], A [1:0] }),
      .DI  (DI),
      .DO  (timer_do),
      .OE  (timer_oe),
      .irq  (IRQ),
      .irq_en(IRQ_EN)
  );

  io io0 (
      .clk  (phi2),
      .we_n  (we_n),
      .A  (A [2:0] ),
      .DI  (DI),
      .DO  (io_do),
      .PBO (PBO),
      .PBI (PBI),
      .PAI (PAI),
      .PAO (PAO),
      .DDRA (DDRA),
      .DDRB (DDRB),
      .OE  (io_oe)
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

endmodule

