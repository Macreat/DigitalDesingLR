`timescale 1ns / 1ps
//=============================================================================
// File         : knob_param_decoder.v
// Author       : Mateo Almeida
// Description  :
//   This module translates MIDI data bytes received from a UART interface
//   into internal parameter write operations. Each valid MIDI byte produces:
//     - A parameter address (param_addr)
//     - A scaled parameter value (param_value)
//     - A validation pulse (param_valid)
//
//   MIDI byte interpretation:
//     * Bits [6:4] : Parameter address (up to 8 possible parameters)
//     * Bits [6:0] : MIDI value (0–127), expanded to the desired bit width
//
//   This module is intended for control systems (e.g., knobs or MIDI
//   controllers) where internal parameters are adjusted using simple
//   MIDI messages.
//
// Parameters:
//   VALUE_WIDTH : Bit width of the output parameter value.
//
// Inputs:
//   clk         : System clock.
//   rst         : Active-high synchronous reset.
//   midi_data   : Received MIDI data byte.
//   midi_valid  : Indicates that midi_data is valid.
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
    //
    // Example (VALUE_WIDTH = 16):
    //   midi_value = 7'b1010101
    //   expanded   = 1010101_000000000
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
            // Reset state initialization
            param_addr  <= 3'd0;
            param_value <= {VALUE_WIDTH{1'b0}};
            param_valid <= 1'b0;
        end else begin
            // Default: no valid parameter write
            param_valid <= 1'b0;

            // Decode MIDI byte when valid
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
