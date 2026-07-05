
`ifndef __TOP__
`define __TOP__

module top (
    input A0,
    input A1,
    input A2,
    input A3,
    input A4,
    input A5,
    input A6,
    input A7,
    input A8,
    input A9,

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
    inout CS1_PB6,
    inout IRQ_PB7,
    input R_W,

    input PHI2,
    input RES
);

  wire we_n;
  wire rst_n;
  wire phi2_io;
  wire cs1;
  wire irq, irq_en;

  wire OE;

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
      .PIN_TYPE(6'b0000_01),
      .PULLUP  (1'b1)

  ) io_phi2 (
      .PACKAGE_PIN(PHI2),
      .D_IN_0     (phi2_io)
  );

  SB_IO #(
      .PIN_TYPE(6'b0000_01)
  ) io_res (
      .PACKAGE_PIN (RES),
`ifdef VERILATOR
      .CLOCK_ENABLE(1'b1),
`endif
      .D_IN_0      (rst_n)
  );

  // R/W.
  SB_IO #(
      .PIN_TYPE(6'b0000_01)
  ) io_r_w_n (
      .PACKAGE_PIN      (R_W),
`ifdef VERILATOR
      .CLOCK_ENABLE     (1'b1),
`endif
      .D_IN_0           (we_n)
  );

  SB_IO #(
      .PIN_TYPE(6'b0000_01)
  ) io_cs1 (
      .PACKAGE_PIN      (CS1_PB6),
`ifdef VERILATOR
      .CLOCK_ENABLE     (1'b1),
`endif
      .D_IN_0           (cs1)
  );



  // Bidirectional data pins. Non-registered input, output and output enable.
  // Drive only while PHI2 is high, like the real chip (READ timing TCDR is
  // referenced to the positive clock transition): the bus must be free
  // during PHI1 for other devices' turnaround.
  SB_IO #(
      .PIN_TYPE(6'b1010_01)
  ) io_data[7:0] (
      .PACKAGE_PIN      ({DB7, DB6, DB5, DB4, DB3, DB2, DB1, DB0}),
`ifdef VERILATOR
      .CLOCK_ENABLE     (1'b1),
`endif
      .OUTPUT_ENABLE    (OE & phi2_io),
      .D_IN_0           (data_i),
      .D_OUT_0          (data_o)
  );

  // Bidirectional io port A. Non-registered input, output and output enable.
  SB_IO #(
      .PIN_TYPE(6'b1010_01),
      .PULLUP(1'b1)
  ) io_porta[7:0] (
      .PACKAGE_PIN      ({PA7, PA6, PA5, PA4, PA3, PA2, PA1, PA0}),
`ifdef VERILATOR
      .CLOCK_ENABLE     (1'b1),
`endif
      .OUTPUT_ENABLE    (ddra),
      .D_IN_0           (porta_i),
      .D_OUT_0          (porta_o)
  );

  // Bidirectional io port B.  The 6530-002/-003 mask uses the PB6 cell as
  // the CS1 input, so there is no PB6 I/O: reading port B bit 6 returns
  // the CS1 pin level.  PB7 doubles as the /IRQ output when enabled by
  // A3; the datasheet specifies it only pulls low, so it is driven
  // open-drain here to allow wire-ANDing with other interrupt sources.
  SB_IO #(
      .PIN_TYPE(6'b1010_01),
      .PULLUP(1'b1)
  ) io_portb[6:0] (
      .PACKAGE_PIN      ({IRQ_PB7, CS2_PB5, PB4, PB3, PB2, PB1, PB0}),
`ifdef VERILATOR
      .CLOCK_ENABLE     (1'b1),
`endif
      .OUTPUT_ENABLE    ({irq_en ? ~irq : ddrb[7], ddrb[5:0]}),
      .D_IN_0           ({portb_i[7], portb_i[5:0]}),
      .D_OUT_0          ({irq_en ? 1'b0 : portb_o[7], portb_o[5:0]})
  );

  assign portb_i[6] = cs1;


  // Address pin inputs.
  SB_IO #(
      .PIN_TYPE(6'b0000_01)
  ) io_addr[9:0] (
      .PACKAGE_PIN      ({A9, A8, A7, A6, A5, A4, A3, A2, A1, A0}),
`ifdef VERILATOR
      .CLOCK_ENABLE     (1'b1),
`endif
      .D_IN_0           (addr)
  );

  mcs6530 #(
    `ifdef MCS6530_002
      .CHIP_VERSION(2)
    `endif 
    `ifdef MCS6530_003
      .CHIP_VERSION(3)
    `endif
  ) mcs6530_instance (
      .phi2(phi2_io),
      .rst_n(rst_n),
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
      .CS1(cs1),
      .IRQ(irq),
      .IRQ_EN(irq_en)
  );

endmodule

`endif //__TOP__
