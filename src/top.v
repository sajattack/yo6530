module top(
  inout A0,
  inout A1,
  inout A2,
  inout A3,
  inout A4,
  inout A5,
  inout A6,
  inout A7,
  inout A8,
  inout A9,

  inout RS0,

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
  inout CS1_PB6,
  inout IRQ_PB7,
  input R_W,

  inout PHI2,
  inout RES,
);

wire we_n;
wire rst_n;
wire irq_n;
wire phi2_io;
wire phi1_io = ~phi2_io;

wire [7:0] data_i;
wire [7:0] data_o;

wire [7:0] porta_i;
wire [7:0] porta_o;

wire [7:0] portb_i;
wire [7:0] portb_o;

wire [7:0] ddra;
wire [7:0] ddrb;


wire [9:0] addr;

SB_IO #(
    .PIN_TYPE    (6'b0000_01),
    .PULLUP      (1'b1)
) io_phi2 (
    .PACKAGE_PIN (PHI2),
    .D_IN_0      (phi2_io)
);

SB_IO #(
    .PIN_TYPE     (6'b0000_00)
) io_res (
    .PACKAGE_PIN  (RES),
  `ifdef VERILATOR
    .CLOCK_ENABLE (1'b1),
  `endif
    .INPUT_CLK    (phi2_io),
    .D_IN_0       (rst_n)
);

// R/W.
SB_IO #(
    .PIN_TYPE          (6'b0000_10)
) io_r_w_n (
    .PACKAGE_PIN       (R_W),
    .LATCH_INPUT_VALUE (phi1_io),
`ifdef VERILATOR
    .CLOCK_ENABLE      (1'b1),
`endif
    .INPUT_CLK         (phi2_io),
    .D_IN_0            (we_n)
);

// Bidirectional data pins. Registered input and output enable.
SB_IO #(
    .PIN_TYPE          (6'b1110_10)
) io_data[7:0] (
    .PACKAGE_PIN       ({DB7, DB6, DB5, DB4, DB3, DB2, DB1, DB0}),
    .LATCH_INPUT_VALUE (phi1_io),
`ifdef VERILATOR
    .CLOCK_ENABLE      (1'b1),
`endif
    .INPUT_CLK         (phi2_io),
    .OUTPUT_CLK        (phi2_io),
    .OUTPUT_ENABLE     (OE),
    .D_IN_0            (data_i),
    .D_OUT_0           (data_o)
);

// Bidirectional io port A. Registered input and output enable.
SB_IO #(
    .PIN_TYPE          (6'b1110_10)
) io_porta[7:0] (
    .PACKAGE_PIN       ({PA7, PA6, PA5, PA4, PA3, PA2, PA1, PA0}),
    .LATCH_INPUT_VALUE (phi1_io),
`ifdef VERILATOR
    .CLOCK_ENABLE      (1'b1),
`endif
    .INPUT_CLK         (phi2_io),
    .OUTPUT_CLK        (phi2_io),
    .OUTPUT_ENABLE     (ddra),
    .D_IN_0            (porta_i),
    .D_OUT_0           (porta_o)
);

// Bidirectional io port B. Registered input and output enable.
SB_IO #(
    .PIN_TYPE          (6'b1110_10)
) io_portb[7:0] (
    .PACKAGE_PIN       ({IRQ_PB7, CS1_PB6, CS2_PB5, PB4, PB3, PB2, PB1, PB0}),
    .LATCH_INPUT_VALUE (phi1_io),
`ifdef VERILATOR
    .CLOCK_ENABLE      (1'b1),
`endif
    .INPUT_CLK         (phi2_io),
    .OUTPUT_CLK        (phi2_io),
    .OUTPUT_ENABLE     (ddrb), 
    .D_IN_0            (portb_i),
    .D_OUT_0           (portb_o)
);



// Address pin inputs.
SB_IO #(
    .PIN_TYPE          (6'b0000_10)
) io_addr[9:0] (
    .PACKAGE_PIN       ({A9, A8, A7, A6, A5, A4, A3, A2, A1, A0}),
    .LATCH_INPUT_VALUE (phi1_io),
`ifdef VERILATOR
    .CLOCK_ENABLE      (1'b1),
`endif
    .INPUT_CLK         (phi2_io),
    .D_IN_0            (addr)
);


mcs6530 mcs6530 (
  .phi2(phi2_io),
  .rst_n(rst_n),
  .we_n(we_n),
  .A(addr),
  .DI(data_i),
  .DO(data_o),
  .OE(OE),
  .RS_n(RS0),
  .PAO(porta_o),
  .PAI(porta_i),
  .PBO(portb_o),
  .PBI(portb_i),
  .DDRA(ddra),
  .DDRB(ddrb)
);

endmodule
  
