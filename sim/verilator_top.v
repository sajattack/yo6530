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

    inout DB0,
    inout DB1,
    inout DB2,
    inout DB3,
    inout DB4,
    inout DB5,
    inout DB6,
    inout DB7,

    inout PA0,
    inout PA1,
    inout PA2,
    inout PA3,
    inout PA4,
    inout PA5,
    inout PA6,
    inout PA7,

    inout PB0,
    inout PB1,
    inout PB2,
    inout PB3,
    inout PB4,
    inout CS2_PB5,
    input CS1,
    inout IRQ_PB7,
    input R_W,

    input PHI2,
    input RES,

    input [7:0] data_i,
    output reg [7:0] data_o,
    output OE,

    output reg [7:0] porta_o,
    output reg [7:0] portb_o,
    output reg [7:0] ddra,
    output reg [7:0] ddrb

);

  wire we_n;
  reg irq, irq_en;

  reg [7:0] porta_i;
  // verilator lint_off UNDRIVEN
  reg [7:0] portb_i;
  // verilator lint_on UNDRIVEN
  
  assign we_n = R_W;

  assign {DB7, DB6, DB5, DB4, DB3, DB2, DB1, DB0} = we_n ? data_o : 8'bzzzzzzzz;

//always_comb begin
//  data_i = !we_n ? {DB7, DB6, DB5, DB4, DB3, DB2, DB1, DB0}: 8'bzzzzzzzz;
//end

  assign PA7 = ddra[7] ? porta_o[7] : 1'bz;
  assign PA6 = ddra[6] ? porta_o[6] : 1'bz;
  assign PA5 = ddra[5] ? porta_o[5] : 1'bz;
  assign PA4 = ddra[4] ? porta_o[4] : 1'bz;
  assign PA3 = ddra[3] ? porta_o[3] : 1'bz;
  assign PA2 = ddra[2] ? porta_o[2] : 1'bz;
  assign PA1 = ddra[1] ? porta_o[1] : 1'bz;
  assign PA0 = ddra[0] ? porta_o[0] : 1'bz;

  assign IRQ_PB7 = irq_en ? irq : ddrb[7] ? portb_o[7]: 1'bz;
  // CS1_PB6 is an input
  assign CS2_PB5 = ddrb[5] ? portb_o[5]: 1'bz;
  assign PB4 = ddrb[4] ? portb_o[4] : 1'bz;
  assign PB3 = ddrb[3] ? portb_o[3] : 1'bz;
  assign PB2 = ddrb[2] ? portb_o[2] : 1'bz;
  assign PB1 = ddrb[1] ? portb_o[1] : 1'bz;
  assign PB0 = ddrb[0] ? portb_o[0] : 1'bz;

  always_comb begin
    porta_i[7] = !ddra[7] ? PA7 : 1'bz;
    portb_i[7] = !ddrb[7] ? IRQ_PB7: 1'bz;
    porta_i[6] = !ddra[6] ? PA6 : 1'bz;
    //portb_i[6] = CS1_PB6;
    porta_i[5] = !ddra[5] ? PA5 : 1'bz;
    portb_i[5] = !ddrb[5] ? CS2_PB5  : 1'bz;
    porta_i[4] = !ddra[4] ? PA4 : 1'bz;
    portb_i[4] = !ddrb[4] ? PB4 : 1'bz;
    porta_i[3] = !ddra[3] ? PA3 : 1'bz;
    portb_i[3] = !ddrb[3] ? PB3 : 1'bz;
    porta_i[2] = !ddra[2] ? PA2 : 1'bz;
    portb_i[2] = !ddrb[2] ? PB2 : 1'bz;
    porta_i[1] = !ddra[1] ? PA1 : 1'bz;
    portb_i[1] = !ddrb[1] ? PB1 : 1'bz;
    porta_i[0] = !ddra[0] ? PA0 : 1'bz;
    portb_i[0] = !ddrb[0] ? PB0 : 1'bz;
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
