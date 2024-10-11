module io (
    input clk,
    // verilator lint_off UNUSEDSIGNAL
    input rst_n,
    // verilator lint_on UNUSEDSIGNAL
    input enable,
    input we_n,
    input [2:0] A,
    output reg [7:0] PAO,    // port A output
    input [7:0] PAI,    // port A input
    output reg [7:0] PBO,    // port B output
    input [7:0] PBI,    // port B input
    output reg [7:0] PAOE,   // port A OE (data direction register)
    output reg [7:0] PBOE,   // port B OE (data direction register)
    input [7:0] DI,
    output reg [7:0] DO,
    output reg OE
);

  logic [7:0] PAI_int, PBI_int;
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin : inputs
      assign PAI_int[i] = PAOE[i] ? PAO[i] : PAI[i];
      assign PBI_int[i] = PBOE[i] ? PBO[i] : PBI[i];
    end
  endgenerate

  reg [7:0] reg_data;
  reg [2:0] reg_addr;
  reg reg_we_n;

  always @(negedge clk) begin
    if (~rst_n) begin
      PAO  <= 8'd0;
      PAOE <= 8'd0;
      PBO  <= 8'd0;
      PBOE <= 8'd0;
    end else begin
      if (enable)
        case ({
          reg_we_n, reg_addr
        })
          4'b0_000: PAO <= DI;  // Write port A
          4'b1_000: ;
          4'b0_001: PAOE <= DI;  // Write DDRA
          4'b1_001: ;
          4'b0_010: PBO <= DI;  // Write port B
          4'b1_010: ;
          4'b0_011: PBOE <= DI;  // Write DDRB
          4'b1_011: ;
          default:  ;
        endcase
    end
  end

  always@(posedge clk) begin
    if (enable) begin
      reg_addr <= A;
      reg_we_n <= we_n;
        case ({
          we_n, A[2:0]
        })
          4'b0_000: ;
          4'b1_000: reg_data <= PAI_int;  // Read port A
          4'b0_001: ;
          4'b1_001: reg_data <= PAOE;  // Read DDRA
          4'b0_010: ;
          4'b1_010: reg_data <= PBI_int;  // Read port B
          4'b0_011: ;
          4'b1_011: reg_data <= PBOE;  // Read DDRB
          default:  ;
        endcase
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
