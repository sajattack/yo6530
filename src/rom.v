module rom (
    input clk,
    input enable,
    input [9:0] A,
    output reg OE,
    output reg [7:0] DO
);

  `ifdef MOS6530_002
  parameter ROM_FILE = "roms/6530-002.hex";
  `endif

  `ifdef MOS6530_003
  parameter ROM_FILE = "roms/6530-003.hex";
  `endif

  reg [7:0] ROM1K[1024];

  initial $readmemh(ROM_FILE, ROM1K);

  reg [7:0] reg_data;

  always @(posedge clk) begin
    reg_data <= ROM1K[A];
  end

  always_comb begin
    OE = 1'b0;
    DO = 8'h00;
    if (enable) begin
        {OE, DO} = {1'b1, reg_data};
    end
  end

endmodule
