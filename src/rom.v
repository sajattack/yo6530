module rom(
  input clk,
  input [9:0] A,
  output OE,
  output [7:0] DO
);

  parameter ROM_FILE = "roms/6530-003.hex";

  reg [7:0] ROM1K[1024];

  initial $readmemh(ROM_FILE, ROM1K);

  always_ff @(posedge clk) begin
    if (enabled) //(RS_n == 1'b0 && CS2==1'b0)
      {OE, DO} <= {1'b1, ROM1K[A]};

  end

endmodule
