module timer (
    input            enable,
    input            clk,
    input            rst_n,
    input            we_n,   // RW Read high/Write low
    input      [2:0] A,      // Address
    input      [7:0] DI,     // Data to processor
    output reg [7:0] DO,     // Data from processor
    output reg       OE,     // Indicates data driven on DO
    output reg       irq,
    output reg irq_en
);

  reg [9:0] timer_divider;
  reg [9:0] timer_count;
  reg [7:0] timer;

  always @(negedge clk) begin
    irq <= 1'd1;
    // reset logic
    if (~rst_n) begin
      timer <= 8'd0;
      timer_divider <= 10'd1;
      timer_count <= 10'd0;
      irq <= 1'd1; // high means not interrupt
      irq_en <= 1'd0; // low means interrupt disabled
    end 

    else begin
      if (~we_n & enable) begin  
        irq_en <= A[2]; 
        // write timer counter
        // I forget why this is -1, but it probably says in the datasheet
        timer <= DI - 1;
        // write divider based on address lines
        case (A[1:0])
          2'b00:   timer_divider <= 10'd0;
          2'b01:   timer_divider <= 10'd7;
          2'b10:   timer_divider <= 10'd63;
          2'b11:   timer_divider <= 10'd1023;
          default: ;
        endcase
      end else if (~A[0] & enable) begin
        // read timer counter
        irq_en <= A[2];
        DO <= timer;
        OE <= 1'b1;
      end else begin
        DO <= {irq, 7'd0}; // read irq
        OE <= 1'b0;
      end
    end

    // decrement the timer when the divider rolls over
    if (timer_count == timer_divider) begin
      timer <= timer - 1;
      timer_count <= 0;
      if (timer == 8'd0) begin
        //timer_divider <= 10'd0; // why is this here?
        // I think I was trying to prevent it running to infinity - but instead this 
        // wipes out the divider the user chose
        // also this doesn't actually increment ever so that doesn't make sense
        irq <= ~(irq_en & 1'd1); // trigger irq if enabled when timer reaches 0
      end
    end

    // increment the count
    // note it will be reset to 0 once it reaches the divider value
    timer_count <= timer_count + 1;
  end
endmodule

