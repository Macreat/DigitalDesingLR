`timescale 1ns/1ps
module sipo_reg #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire shift_en,
    input  wire bit_in,
    output reg  [WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 0;
        else if (shift_en)
            data_out <= {data_out[WIDTH-2:0], bit_in}; // desplaza izquierda
    end
endmodule
