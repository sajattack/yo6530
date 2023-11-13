 module mcs6530 (
    input        phi2,
    input        rst_n,
    input        we_n,   // RW Read high/Write low
    output       irq_n,
    input  [9:0] A,      // Address
    input  [7:0] DI,     // Data from processor
    output [7:0] DO,     // Data to processor
    output       OE,     // Indicates data driven on DO
    input        CS1,    // Active-low, same pin as PB6
    input        CS2,    // Same pin as PB5
    input        RS_n,  // Active-low ROM select
    output [7:0] PAO,    // port A output
    input  [7:0] PAI,    // port A input
    output [7:0] PBO,    // port B output
    input  [7:0] PBI,    // port B input
);


  parameter IOT_BASE = 0;
  parameter ROM_FILE = "roms/6530-003.hex";

  // When a pin is set to an output (direction = 1), make sure
  // the output data is read as such
  logic [7:0] PAI_int, PBI_int;
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin : inputs
      assign PAI_int[i] = DDRA[i] ? PAO[i] : PAI[i];
      assign PBI_int[i] = DDRB[i] ? PBO[i] : PBI[i];
    end
  endgenerate


  reg [7:0] DDRA;   // data direction register A
  reg [7:0] DDRB;   // data direction register B

  // Memories
  reg [7:0] ROM1K[0:1023];
  reg [7:0] RAM64[0:63];


  initial $readmemh(ROM_FILE, ROM1K);

  // memory logic
  always_ff @(posedge phi2) begin
    if (RS_n == 1'b0 && CS2==1'b0) 
        DO <= {1'b1, ROM1K[A[9:0]]};
   end
 
   always_ff @(posedge phi2) begin
    if (!CS1 && A[9:7]==3'b111)
      if (~we_n)
        RAM64[A[6:0]] <= DI;
      else
        DO <= RAM64[A[6:0]];
  end
                                                                         
  // This logic was mask programmed; see Figure 6 in the MCS6530 data sheet
  logic IOT_SELECT;
  assign IOT_SELECT = !CS1 && (A[9:6] == IOT_BASE[9:6]);

  // IO logic
  always_ff @(posedge phi2) begin
    if (~rst_n) begin
      PAO  <= 8'd0;
      DDRA <= 8'd0;
      PBO  <= 8'd0;
      DDRB <= 8'd0;
      timer <= 8'd0;
      timer_divider <= 9'd0;
      timer_count <= 9'd0;
      timer_irq <= 1'd0;
      timer_irq_en <= 1'd0;
    
    end else begin
      {OE, DO} <= {1'b0, 8'bx};
      if (IOT_SELECT)
        case ({
          we_n, A[2:0]
        })
          4'b0_000: PAO <= DI;  // Write port A
          4'b1_000: {OE, DO} <= {1'b1, PAI_int};  // Read port A
          4'b0_001: DDRA <= DI;  // Write DDRA
          4'b1_001: {OE, DO} <= {1'b1, DDRA};  // Read DDRA
          4'b0_010: PBO <= DI;  // Write port B
          4'b1_010: {OE, DO} <= {1'b1, PBI_int};  // Read port B
          4'b0_011: DDRB <= DI;  // Write DDRB
          4'b1_011: {OE, DO} <= {1'b1, DDRB};  // Read DDRB
          default:  ;
        endcase
    end
  end

  //timer logic
  logic timer_irq_en;
  logic timer_irq;
  reg[9:0] timer_divider;
  reg[9:0] timer_count;
  reg[7:0] timer;
  always_ff @(posedge phi2) begin
    if (timer_count == timer_divider) begin
      timer <= timer - 1;
      timer_count <= 0;
        if (timer == 8'd0) begin
          timer_divider <= 9'd0;
          timer_irq <= 1'd1;
        end
    end
    else
      timer_count <= timer_count + 1;
    if (CS1) // chip active
      if (A[2])  // timer select
        if (~we_n) begin// write
          timer_irq_en <= A[3];
          timer_irq <= 0;
          timer <= DI -1;
          timer_count <= 0;
            // write divider based on address lines
            case (A[1:0])
              2'b00: timer_divider <= 10'd0;
              2'b01: timer_divider <= 10'd7;
              2'b10: timer_divider <= 10'd63;
              2'b11: timer_divider <= 10'd1023;
            endcase
        end
      else if (~A[0]) begin
        timer_irq_en <= A[3];
        DO <= timer;
        if (timer !=0)
            timer_irq <= 0;
      end
        else
          DO <= {7'd0, timer_irq};

  irq_n <= ~(timer_irq & timer_irq_en);
end

endmodule
