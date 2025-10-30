`timescale 1ns/1ps

module sipo_reg #(
    parameter integer WIDTH = 8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire shift_en,
    input  wire bit_in,
    output reg  [WIDTH-1:0] data_out
);
    initial begin
        if (WIDTH < 4)
            $error("sipo_reg WIDTH must be >= 4");
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else if (shift_en)
            // Desplazar a la izquierda. El nuevo bit entra por el LSB.
            data_out <= {data_out[WIDTH-2:0], bit_in};
    end
endmodule
