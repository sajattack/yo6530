module io (
    input clk,
    input rst_n,
    input enable,
    input we_n,
    input [2:0] A,
    output reg [7:0] PAO,    // port A output
    input reg [7:0] PAI,    // port A input
    output reg [7:0] PBO,    // port B output
    input reg [7:0] PBI,    // port B input
    output reg [7:0] DDRA,   // port A OE (data direction register)
    output reg [7:0] DDRB,   // port B OE (data direction register)
    input reg [7:0] DI,
    output reg [7:0] DO,
    output reg OE
);

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

  always @(posedge clk) begin
    if (enable) begin
      case ({
        we_n, A[2:0]
      })
        4'b0_000: {OE, PAO} <= {1'b0, DI};  // Write port A
        4'b1_000: {OE, DO} <= {1'b1, PAI_int};  // Read port A
        4'b0_001: {OE, DDRA} <= {1'b0, DI};  // Write DDRA
        4'b1_001: {OE, DO} <= {1'b1, DDRA};  // Read DDRA
        4'b0_010: {OE, PBO} <= {1'b0, DI};  // Write port B
        4'b1_010: {OE, DO} <= {1'b1, PBI_int};  // Read port B
        4'b0_011: {OE, DDRB} <= {1'b0, DI};  // Write DDRB
        4'b1_011: {OE, DO} <= {1'b1, DDRB};  // Read DDRB
        default:  OE <= 1'b0;
      endcase
    end
  end

endmodule
