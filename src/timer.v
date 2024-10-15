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

  reg [7:0] reg_data;
  reg [2:0] reg_addr;

  always @(posedge clk) begin
    if (enable && rst_n) begin
        reg_addr <= A;
        if (we_n) begin
            if (~A[0]) begin
                reg_data <= timer;
            end else begin
                reg_data <= {irq, 7'd0};
            end
        end
     end
  end

  always @(negedge clk) begin
    if (~rst_n) begin
        timer_divider <= 10'd0;
        timer_count <= 10'd0;
        timer <= 8'd0;
    end else begin  
        if (enable) begin  
            irq <= 1'b1;
            irq_en <= reg_addr[2]; 
            if (~we_n) begin
            // write timer counter
                timer <= DI - 1;
                // write divider based on address lines
                case (reg_addr[1:0])
                    2'b00:   timer_divider <= 10'd0;
                    2'b01:   timer_divider <= 10'd7;
                    2'b10:   timer_divider <= 10'd63;
                    2'b11:   timer_divider <= 10'd1023;
                endcase
            end
        end

        if (timer == 8'd0) begin
            irq <= ~(irq_en & 1'd1); // trigger irq if enabled when timer reaches 0
            timer_count <= timer_count + 1;
        end else begin
        // increment the count
            timer_count <= timer_count + 1;
        end
        // decrement the timer when the divider is reached
        if (timer_count == timer_divider) begin
            timer <= timer - 1;
            timer_count <= 0;
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

