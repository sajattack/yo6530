module verilator_top (
    /*input A0,
    input A1,
    input A2,
    input A3,
    input A4,
    input A5,
    input A6,
    input A7,
    input A8,
    input A9,*/
    input [9:0] addr,

    input RS0,

    input CS1,
    input R_W,

    input PHI2_2X,
    input RES,

    input [7:0] data_i,
    output reg [7:0] data_o,
    output OE,

    input reg [7:0] porta_i,
    input reg [7:0] portb_i,
    output reg [7:0] porta_o,
    output reg [7:0] portb_o,
    output reg [7:0] ddra,
    output reg [7:0] ddrb,
    output reg PHI2,
    output reg irq, irq_en
);

  wire we_n;

  assign we_n = R_W;

  always @(posedge PHI2_2X) begin
      PHI2 <= ~PHI2;
  end

  mcs6530 mcs6530 (
      .phi2(PHI2),
      .rst_n(RES),
      .we_n(we_n),
      .A(addr),
      .DI(data_i),
      .DO(data_o),
      .OE(OE),
      .RS0(RS0),
      .PAO(porta_o),
      .PAI(porta_i),
      .PBO(portb_o),
      .PBI(portb_i),
      .DDRA(ddra),
      .DDRB(ddrb),
      .CS1(CS1),
      .IRQ(irq),
      .IRQ_EN(irq_en)
  );

endmodule
