module ram (
    input clk,
    input enable,
    input we_n,
    input [5:0] A,
    input [7:0] DI,
    output reg [7:0] DO,
    output reg OE
);

  reg [7:0] RAM64[64];
  reg [7:0] reg_data;
  reg [5:0] reg_addr;

  always @(negedge clk) begin
    if (enable && ~we_n) begin
        RAM64[reg_addr] <= DI;
    end
  end

  always@(posedge clk) begin
    if (enable) begin
       reg_addr <= A;
       reg_data <= RAM64[A];    
    end
  end

  always_comb begin
    OE = 1'b0;
    DO = 8'hxx;
    if (enable) begin
        if (we_n) begin
            {OE, DO} = {1'b1, reg_data};
        end
    end
  end

endmodule
