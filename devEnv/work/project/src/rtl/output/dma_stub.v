`timescale 1ns / 1ps
//=============================================================================
// File         : dma_stub.v
// Author       : Mateo Almeida
// Description  :
//   This module implements a simplified Direct Memory Access (DMA) stub
//   intended for testing and integration purposes. Instead of performing
//   actual memory transfers, it captures the most recent valid input sample
//   and stores it internally.
//
//   The module always signals readiness to accept new samples and updates
//   the stored value whenever a valid sample is presented. This makes it
//   useful as a placeholder for a future DMA or audio output interface
//   during early development and verification stages.
//
// Parameters:
//   SAMPLE_WIDTH : Bit width of the input and stored sample data.
//
// Inputs:
//   clk          : System clock.
//   rst          : Active-high synchronous reset.
//   sample_in    : Signed input sample data.
//   sample_valid : Indicates that sample_in is valid.
//
// Outputs:
//   last_written : Holds the most recently accepted sample value.
//   ready        : Indicates that the module is ready to accept a sample.
//
//=============================================================================

module dma_stub #(
    parameter integer SAMPLE_WIDTH = 16
) (
    input  wire                           clk,
    input  wire                           rst,
    input  wire signed [SAMPLE_WIDTH-1:0] sample_in,
    input  wire                           sample_valid,
    output reg  [SAMPLE_WIDTH-1:0]        last_written,
    output reg                            ready
);

    //-------------------------------------------------------------------------
    // Main sequential logic
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // Reset initialization
            last_written <= {SAMPLE_WIDTH{1'b0}};
            ready        <= 1'b1;
        end else begin
            // Capture input sample when valid
            if (sample_valid) begin
                last_written <= sample_in;
            end

            // Always ready to accept new samples
            ready <= 1'b1;
        end
    end

endmodule
