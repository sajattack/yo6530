module mcs6530 #(
    parameter CHIP_VERSION
) (
    input            phi2,
    input            rst_n,
    input            we_n,   // RW Read high/Write low
    input      [9:0] A,      // Address
    input      [7:0] DI,     // Data to 6530
    output reg [7:0] DO,     // Data from 6530
    output reg       OE,      // Indicates data driven on DO
    input            RS0,    // ROM select
    output reg [7:0] PAO,    // port A output
    input [7:0] PAI,    // port A input
    output reg [7:0] PBO,    // port B output
    input [7:0] PBI,    // port B input
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
    if (CHIP_VERSION == 2) begin
        ram_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & A[7] & A[6];
        io_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & ~A[7] & A[6] & ~A[2];
        timer_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & ~A[7] & A[6] & A[2];
    end else if (CHIP_VERSION == 3) begin
        ram_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & A[7] & ~A[6];
        io_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & ~A[7] & ~A[6] & ~A[2];
        timer_enable = rst_n & RS0 & !CS1 & A[9] & A[8] & ~A[7] & ~A[6] & A[2];
    end
  end

  ram ram0 (
      .clk(phi2),
      .enable(ram_enable),
      .we_n(we_n),
      .A(A[5:0]),
      .DI(DI),
      .DO(ram_do),
      .OE(ram_oe)
  );
  
  rom #(
      .ROM_CHIP_VERSION(CHIP_VERSION)
  ) rom0 (
      .clk(phi2),
      .enable(rom_enable),
      .A  (A),
      .DO (rom_do),
      .OE (rom_oe)
  );

  timer timer0 (
      .clk  (phi2),
      .enable (timer_enable),
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
      .enable(io_enable),
      .rst_n(rst_n),
      .we_n  (we_n),
      .A  (A [2:0] ),
      .DI  (DI),
      .DO  (io_do),
      .PBO (PBO),
      .PBI (PBI),
      .PAI (PAI),
      .PAO (PAO),
      .PAOE(DDRA),
      .PBOE (DDRB),
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
      {OE, DO} = {1'b0, 8'h00};
    end
  end

endmodule

