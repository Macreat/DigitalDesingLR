`timescale 1ns / 1ps
module phase_accumulator #(
    parameter integer PHASE_WIDTH = 32
) (
    input  wire [PHASE_WIDTH-1:0] phase_inc,
    input  wire                   clk,
    input  wire                   rst,
    output reg  [PHASE_WIDTH-1:0] phase,
    output reg                    tick
);

    wire [PHASE_WIDTH:0] next_phase;
    assign next_phase = phase + phase_inc;

    always @(posedge clk) begin
        if (rst) begin
            phase <= {PHASE_WIDTH{1'b0}};
            tick  <= 1'b0;
        end else begin
            phase <= next_phase[PHASE_WIDTH-1:0];
            tick  <= next_phase[PHASE_WIDTH];
        end
    end
endmodule
