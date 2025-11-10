`timescale 1ns / 1ps
// Translates MIDI data bytes coming from the UART into parameter writes.
module knob_param_decoder #(
    parameter integer VALUE_WIDTH = 16
) (
    input  wire              clk,
    input  wire              rst,
    input  wire      [7:0]   midi_data,
    input  wire              midi_valid,
    output reg       [2:0]   param_addr,
    output reg [VALUE_WIDTH-1:0] param_value,
    output reg               param_valid
);

    function [VALUE_WIDTH-1:0] expand_value;
        input [6:0] midi_value;
        begin
            expand_value = {midi_value, {(VALUE_WIDTH-7){1'b0}}};
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            param_addr  <= 3'd0;
            param_value <= {VALUE_WIDTH{1'b0}};
            param_valid <= 1'b0;
        end else begin
            param_valid <= 1'b0;
            if (midi_valid) begin
                param_addr  <= midi_data[6:4]; // 7 combinations -> up to 8 params
                param_value <= expand_value(midi_data[6:0]);
                param_valid <= 1'b1;
            end
        end
    end
endmodule
