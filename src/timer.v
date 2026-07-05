module timer (
    input            enable,
    input            clk,
    input            rst_n,
    input            we_n,   // RW Read high/Write low
    input      [2:0] A,      // {A3, A1, A0}
    input      [7:0] DI,     // Data to 6530
    output reg [7:0] DO,     // Data from 6530
    output reg       OE,     // Indicates data driven on DO
    output           irq,    // /IRQ level for PB7: low while flag && irq_en
    output reg       irq_en  // PB7 in IRQ mode (A3 of last timer read/write)
);

  reg [9:0] timer_divider;
  reg [9:0] timer_count;
  reg [7:0] timer;
  reg       flag;  // interrupt flag: bit 7 of the interrupt flag register

  reg [7:0] reg_data;
  reg [2:0] reg_addr;

  assign irq = ~(flag & irq_en);

  always @(posedge clk) begin
    if (enable && rst_n) begin
      reg_addr <= A;
      if (we_n) begin
        if (~A[0]) begin
          reg_data <= timer;
        end else begin
          reg_data <= {flag, 7'd0};
        end
      end
    end
  end

  always @(negedge clk) begin
    if (~rst_n) begin
      timer_divider <= 10'd0;
      timer_count   <= 10'd0;
      timer         <= 8'd0;
      flag          <= 1'b0;
      irq_en        <= 1'b0;
    end else begin
      // Free-running countdown.  The interrupt flag sets when the counter
      // wraps 0 -> FF (N*T+1 cycles after a write of N), and the counter
      // then decrements at /1 so software can read the overshoot in two's
      // complement.
      if (timer_count == timer_divider) begin
        timer_count <= 10'd0;
        timer       <= timer - 8'd1;
        if (timer == 8'd0) begin
          flag          <= 1'b1;
          timer_divider <= 10'd0;
        end
      end else begin
        timer_count <= timer_count + 10'd1;
      end

      // Register accesses override the free-running logic above.
      if (enable) begin
        if (~we_n) begin
          // Timer write: load counter, restart prescaler, clear interrupt;
          // A1/A0 select the divider, A3 the IRQ enable.
          timer       <= DI - 8'd1;
          timer_count <= 10'd0;
          flag        <= 1'b0;
          irq_en      <= reg_addr[2];
          case (reg_addr[1:0])
            2'b00: timer_divider <= 10'd0;
            2'b01: timer_divider <= 10'd7;
            2'b10: timer_divider <= 10'd63;
            2'b11: timer_divider <= 10'd1023;
          endcase
        end else if (~reg_addr[0]) begin
          // Timer read: clear the interrupt and set the IRQ enable from A3.
          // A read on the same edge the interrupt occurs does not clear the
          // flag (datasheet page 10).
          irq_en <= reg_addr[2];
          if (!(timer_count == timer_divider && timer == 8'd0)) begin
            flag <= 1'b0;
          end
        end
        // Interrupt flag register reads have no side effects.
      end
    end
  end

  always_comb begin
    OE = 1'b0;
    DO = 8'h00;
    if (enable) begin
      if (we_n) begin
        {OE, DO} = {1'b1, reg_data};
      end
    end
  end

endmodule
