`timescale 1ns / 1ps
module dma_stub #(
    parameter integer SAMPLE_WIDTH = 16
) (
    input  wire                        clk,
    input  wire                        rst,
    input  wire signed [SAMPLE_WIDTH-1:0] sample_in,
    input  wire                        sample_valid,
    output reg  [SAMPLE_WIDTH-1:0]     last_written,
    output reg                         ready
);

    always @(posedge clk) begin
        if (rst) begin
            last_written <= {SAMPLE_WIDTH{1'b0}};
            ready        <= 1'b1;
        end else begin
            if (sample_valid) begin
                last_written <= sample_in;
            end
            ready <= 1'b1;
        end
    end
endmodule
