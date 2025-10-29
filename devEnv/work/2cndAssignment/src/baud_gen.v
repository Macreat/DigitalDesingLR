`timescale 1ns/1ps

module baud_gen #(
    parameter integer CLK_FREQ_HZ = 25_000_000,
    parameter integer BAUD_RATE   = 115_200
) (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire align,
    output reg  tick
);
    localparam integer HALF_PERIOD = CLK_FREQ_HZ / 2;

    reg [31:0] phase_accum;
    reg [32:0] next_phase;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_accum <= 32'd0;
            tick        <= 1'b0;
        end else begin
            tick <= 1'b0;

            if (!en) begin
                phase_accum <= 32'd0;
            end else if (align) begin
                phase_accum <= HALF_PERIOD;
            end else begin
                // Accumulate baud increments and emit a tick whenever the accumulator wraps.
                // This fractional-N approach keeps long-term frequency error close to zero.
                next_phase = phase_accum + BAUD_RATE;

                if (next_phase >= CLK_FREQ_HZ) begin
                    tick        <= 1'b1;
                    phase_accum <= next_phase - CLK_FREQ_HZ;
                end else begin
                    phase_accum <= next_phase[31:0];
                end
            end
        end
    end
endmodule
