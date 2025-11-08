`timescale 1ns/1ps
module baud_gen #(
    parameter integer CLK_FREQ_HZ = 1_600_000,
    parameter integer BAUD_RATE   = 100_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire en,      // habilita conteo (activo cuando UART está recibiendo)
    input  wire align,   // resetea contador al detectar start bit
    output reg  tick
);
    localparam integer DIVISOR = CLK_FREQ_HZ / BAUD_RATE;
    integer count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            tick  <= 0;
        end else if (align) begin
            count <= 0;
            tick  <= 0;
        end else if (en) begin
            if (count == DIVISOR - 1) begin
                count <= 0;
                tick  <= 1;
            end else begin
                count <= count + 1;
                tick  <= 0;
            end
        end else begin
            tick <= 0;
        end
    end
endmodule
