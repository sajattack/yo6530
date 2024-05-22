module timer (
    input            clk,
    input            rst_n,
    input            we_n,   // RW Read high/Write low
    input      [2:0] A,      // Address
    input      [7:0] DI,     // Data from processor
    output reg [7:0] DO,     // Data to processor
    output           OE,     // Indicates data driven on DO
    output reg       irq
);

  logic timer_irq_en;
  reg [9:0] timer_divider;
  reg [9:0] timer_count;
  reg [7:0] timer;

  always_ff @(posedge clk) begin
    irq <= 1'd1;
    // reset logic
    if (~rst_n) begin
      timer <= 8'd0;
      timer_divider <= 10'd0;
      timer_count <= 10'd0;
      irq <= 1'd0;
      timer_irq_en <= 1'd0;
    end  // io port logic

    else begin
      if (~we_n) begin  // write
        timer_irq_en <= A[2];
        irq <= 0;
        timer <= DI - 1;
        // write divider based on address lines
        case (A[1:0])
          2'b00:   timer_divider <= 10'd0;
          2'b01:   timer_divider <= 10'd7;
          2'b10:   timer_divider <= 10'd63;
          2'b11:   timer_divider <= 10'd1023;
          default: ;
        endcase
      end else if (~A[0]) begin
        timer_irq_en <= A[2];
        DO <= timer;
        OE <= 1'b1;
        if (timer != 0) irq <= 0;
      end else begin
        DO <= {7'd0, ~irq};
        OE <= 1'b0;
      end
    end

    if (timer_count == timer_divider) begin
      timer <= timer - 1;
      timer_count <= 0;
      if (timer == 8'd0) begin
        timer_divider <= 10'd0;
        irq <= 1'd1;
      end
    end

    timer_count <= timer_count + 1;
    irq <= ~(irq & timer_irq_en);

  end


endmodule

