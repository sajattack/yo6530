module rom (
    input clk,
    input [9:0] A,
    output reg OE,
    output reg [7:0] DO
);

  parameter ROM_FILE = "roms/6530-002.hex";

  reg [7:0] ROM1K[1024];

  initial $readmemh(ROM_FILE, ROM1K);

  always @(posedge clk) begin
    {OE, DO} <= {1'b1, ROM1K[A]};
  end

endmodule
