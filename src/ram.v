module ram(
  input clk,
  input we_n,
  input [9:0] A,
  input [7:0] DI,
  output [7:0] DO,
  output OE
);

  reg RAM64 [7:0][64];

  always @(posedge clk) begin
    if (enabled)
      if (~we_n)
        RAM64[A[6:0]] <= DI;
      else
        {OE, DO} <= {1'b1, RAM64[A[6:0]]};
  end

endmodule
