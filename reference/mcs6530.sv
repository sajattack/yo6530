/*
 * Model of the MCS6530 "RIOT" RAM/ROM/IO/Timer chip
 *
 * Stephen A. Edwards
 * sedwards@cs.columbia.edu
 * Copyright (c) Stehphen A. Edwards, All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

module mcs6530 (
    input        clk,
    input        reset,
    input        RW,     // Read high/Write low
    input  [9:0] A,      // Address
    input  [7:0] DI,     // Data from processor
    output [7:0] DO,     // Data to processor
    output       OE,     // Indicates data driven on DO
    input        CS1,    // Active-low, same pin as PB6
    output [7:0] PAO,
    input  [7:0] PAI,
    output [7:0] PAOE,
    output [7:0] PBO,
    input  [7:0] PBI,
    output [7:0] PBOE
);

  parameter IOT_BASE = 0;

  // When a pin is set to an output (direction = 1), make sure
  // the output data is read as such
  logic [7:0] PAI_int, PBI_int;
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin : inputs
      assign PAI_int[i] = PAOE[i] ? PAO[i] : PAI[i];
      assign PBI_int[i] = PBOE[i] ? PBO[i] : PBI[i];
    end
  endgenerate

  // This logic was mask programmed; see Figure 6 in the MCS6530 data sheet
  logic IOT_SELECT;
  assign IOT_SELECT = !CS1 && (A[9:6] == IOT_BASE[9:6]);

  always_ff @(posedge clk)
    if (reset) begin
      PAO  <= 8'd0;
      PAOE <= 8'd0;
      PBO  <= 8'd0;
      PBOE <= 8'd0;
    end else begin
      {OE, DO} <= {1'b0, 8'bx};
      if (IOT_SELECT)
        case ({
          RW, A[2:0]
        })
          4'b0_000: PAO <= DI;  // Write port A
          4'b1_000: {OE, DO} <= {1'b1, PAI_int};  // Read port A
          4'b0_001: PAOE <= DI;  // Write DDRA
          4'b1_001: {OE, DO} <= {1'b1, PAOE};  // Read DDRA
          4'b0_010: PBO <= DI;  // Write port B
          4'b1_010: {OE, DO} <= {1'b1, PBI_int};  // Read port B
          4'b0_011: PBOE <= DI;  // Write DDRB
          4'b1_011: {OE, DO} <= {1'b1, PBOE};  // Read DDRB
          // FIXME: Handle the timer
          default:  ;
        endcase
    end

endmodule
