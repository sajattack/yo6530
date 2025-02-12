module rom #(
    parameter ROM_CHIP_VERSION
) (
    input clk,
    input enable,
    input [9:0] A,
    output reg OE,
    output reg [7:0] DO
);

  reg [7:0] ROM1K[1024];

  if (ROM_CHIP_VERSION == 2) begin: gen_rom2
    initial $readmemh("roms/6530-002.hex", ROM1K);
  end else if (ROM_CHIP_VERSION == 3) begin: gen_rom3
    initial $readmemh("roms/6530-003.hex", ROM1K);
  end

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
