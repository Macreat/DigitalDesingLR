`timescale 1ns/1ps

module detector (
    input  wire [3:0] window,
    input  wire [3:0] pattern,
    output wire match
);
    assign match = (window == pattern);
endmodule
