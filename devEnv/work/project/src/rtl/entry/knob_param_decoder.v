`timescale 1ns / 1ps
//=============================================================================
// File         : knob_param_decoder.v
// Author       : Mateo Almeida
// Description  :
//   This module converts MIDI data bytes received from a UART interface
//   into internal parameter write operations. Each valid MIDI byte produces:
//     - A parameter address (param_addr)
//     - A scaled parameter value (param_value)
//     - A one-cycle validation pulse (param_valid)
//
//   MIDI byte format interpretation:
//     * Bits [6:4] : Parameter address (up to 8 possible parameters)
//     * Bits [6:0] : MIDI value (0–127), expanded to VALUE_WIDTH bits
//
//   The module is intended for use in digital control systems where
//   MIDI controllers (e.g., knobs or sliders) adjust internal parameters.
//
// Parameters:
//   VALUE_WIDTH : Bit width of the output parameter value.
//
// Inputs:
//   clk         : System clock.
//   rst         : Active-high synchronous reset.
//   midi_data   : MIDI data byte.
//   midi_valid  : Indicates that the MIDI data byte is valid.
//
// Outputs:
//   param_addr  : Address of the parameter to be written.
//   param_value : Parameter value scaled to VALUE_WIDTH bits.
//   param_valid : One-cycle pulse indicating a valid parameter write.
//
//=============================================================================

module knob_param_decoder #(
    parameter integer VALUE_WIDTH = 16
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire      [7:0]         midi_data,
    input  wire                    midi_valid,
    output reg       [2:0]         param_addr,
    output reg [VALUE_WIDTH-1:0]   param_value,
    output reg                     param_valid
);

    //-------------------------------------------------------------------------
    // Function: expand_value
    // Description:
    //   Expands a 7-bit MIDI value (0–127) to VALUE_WIDTH bits by left-aligning
    //   the value and filling the least significant bits with zeros.
    //-------------------------------------------------------------------------
    function [VALUE_WIDTH-1:0] expand_value;
        input [6:0] midi_value;
        begin
            expand_value = {midi_value, {(VALUE_WIDTH-7){1'b0}}};
        end
    endfunction

    //-------------------------------------------------------------------------
    // Main sequential logic
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // Reset initialization
            param_addr  <= 3'd0;
            param_value <= {VALUE_WIDTH{1'b0}};
            param_valid <= 1'b0;
        end else begin
            // Default: no valid parameter write
            param_valid <= 1'b0;

            // Decode MIDI data when valid
            if (midi_valid) begin
                // Parameter selection from bits [6:4]
                param_addr  <= midi_data[6:4];

                // Expand MIDI value to VALUE_WIDTH bits
                param_value <= expand_value(midi_data[6:0]);

                // Indicate a valid parameter update
                param_valid <= 1'b1;
            end
        end
    end

endmodule
