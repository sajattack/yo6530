module ram (
    input clk,
    input we_n,
    input [5:0] A,
    input [7:0] DI,
    output reg [7:0] DO,
    output reg OE
);

  reg [7:0] RAM64[64];

  always @(posedge clk) begin
    if (~we_n) begin
        RAM64[A[5:0]] <= DI;
        OE <= 1'b0;
    end
    else {OE, DO[7:0]} <= {1'b1, RAM64[A[5:0]]};
  end

endmodule
