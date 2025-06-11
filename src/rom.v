module rom #(
    parameter ROM_CHIP_VERSION = 2
) (
    input clk,
    input enable,
    input [9:0] A,
    output reg OE,
    output reg [7:0] DO
`ifdef DEBUG
    ,input we_n,
    input [7:0] data_i
`endif
);

  reg [9:0] reg_addr;


 (* ram_style = "block" *) reg [7:0] ROM1K[1024]; 

  if (ROM_CHIP_VERSION == 2) begin: gen_rom2
      initial $readmemh("roms/6530-002.hex", ROM1K);
  end else if (ROM_CHIP_VERSION == 3) begin: gen_rom3
      initial $readmemh("roms/6530-003.hex", ROM1K);
  end

  reg [7:0] reg_data;

  always @(posedge clk) begin
      if (enable && we_n) begin
          reg_addr <= A;
          reg_data <= ROM1K[A];
      end
  end

`ifdef DEBUG
  always @(negedge clk) begin
    // if DEBUG, allow writing the ROM
    if (enable && ~we_n) begin
        ROM1K[reg_addr] <= data_i;
    end
  end
`endif

  always_comb begin
    OE = 1'b0;
    DO = 8'h00;
    if (enable && we_n) begin
        {OE, DO} = {1'b1, reg_data};
    end
  end

endmodule
