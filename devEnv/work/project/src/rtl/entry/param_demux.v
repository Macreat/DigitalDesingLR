`timescale 1ns / 1ps
//=============================================================================
// File         : param_demux.v
// Author       : Mateo Almeida
// Description  :
//   This module demultiplexes generic parameter write operations into
//   dedicated internal control registers. It receives a parameter address,
//   a parameter value, and a validation signal, and routes the value to the
//   corresponding register.
//
//   Whenever a valid parameter write is detected (param_valid):
//     - The addressed control register is updated
//     - A single-cycle update pulse (update_pulse) is generated
//
//   This design centralizes the configuration of synthesis and control
//   parameters such as phase increments, envelope shaping, gain control,
//   feedback, and timbre selection.
//
// Parameters:
//   PHASE_WIDTH : Bit width of the phase increment registers.
//   VALUE_WIDTH : Bit width of the generic control parameters.
//
// Inputs:
//   clk         : System clock.
//   rst         : Active-high synchronous reset.
//   param_addr  : Address of the parameter to be written.
//   param_value : Parameter value.
//   param_valid : Indicates a valid parameter write.
//
// Outputs:
//   phase_inc_base : Base oscillator phase increment.
//   phase_inc_mod  : Modulator oscillator phase increment.
//   beta           : Modulation index.
//   decay          : Envelope decay parameter.
//   gain           : Output gain control.
//   feedback       : Feedback amount.
//   attack         : Envelope attack parameter.
//   sustain        : Envelope sustain level.
//   timbre_sel     : Timbre selection control.
//   update_pulse   : One-cycle pulse indicating a parameter update.
//
//=============================================================================

module param_demux #(
    parameter integer PHASE_WIDTH = 32,
    parameter integer VALUE_WIDTH = 16
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire             [2:0]   param_addr,
    input  wire [VALUE_WIDTH-1:0]   param_value,
    input  wire                     param_valid,
    output reg  [PHASE_WIDTH-1:0]   phase_inc_base,
    output reg  [PHASE_WIDTH-1:0]   phase_inc_mod,
    output reg  [VALUE_WIDTH-1:0]   beta,
    output reg  [VALUE_WIDTH-1:0]   decay,
    output reg  [VALUE_WIDTH-1:0]   gain,
    output reg  [VALUE_WIDTH-1:0]   feedback,
    output reg  [VALUE_WIDTH-1:0]   attack,
    output reg  [VALUE_WIDTH-1:0]   sustain,
    output reg  [3:0]               timbre_sel,
    output reg                      update_pulse
);

    //-------------------------------------------------------------------------
    // Function: expand_phase
    // Description:
    //   Extends a VALUE_WIDTH-bit control value to PHASE_WIDTH bits by
    //   zero-extending the most significant bits. This is used to generate
    //   phase increments from generic parameter values.
    //-------------------------------------------------------------------------
    function [PHASE_WIDTH-1:0] expand_phase;
        input [VALUE_WIDTH-1:0] value;
        begin
            expand_phase = {{(PHASE_WIDTH-VALUE_WIDTH){1'b0}}, value};
        end
    endfunction

    //-------------------------------------------------------------------------
    // Default phase increment values
    //-------------------------------------------------------------------------
    localparam [PHASE_WIDTH-1:0] DEFAULT_BASE_INC = 32'd18516068; // ~432 Hz @ 100 MHz
    localparam [PHASE_WIDTH-1:0] DEFAULT_MOD_INC  = 32'd46380170; // ~1080 Hz @ 100 MHz

    //-------------------------------------------------------------------------
    // Main sequential logic
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // Initialize all control registers
            phase_inc_base <= DEFAULT_BASE_INC;
            phase_inc_mod  <= DEFAULT_MOD_INC;
            beta           <= 16'd1024;
            decay          <= 16'd512;
            gain           <= 16'd4096;
            feedback       <= 16'd0;
            attack         <= 16'd256;
            sustain        <= 16'd3072;
            timbre_sel     <= 4'd0;
            update_pulse   <= 1'b0;
        end else begin
            // Default: no update
            update_pulse <= 1'b0;

            // Handle parameter write
            if (param_valid) begin
                update_pulse <= 1'b1;
                case (param_addr)
                    3'd0: phase_inc_base <= expand_phase(param_value);
                    3'd1: phase_inc_mod  <= expand_phase(param_value);
                    3'd2: beta           <= param_value;
                    3'd3: decay          <= param_value;
                    3'd4: gain           <= param_value;
                    3'd5: feedback       <= param_value;
                    3'd6: attack         <= param_value;
                    3'd7: begin
                        sustain    <= param_value;
                        timbre_sel <= param_value[3:0];
                    end
                    default: ; // No action
                endcase
            end
        end
    end

endmodule
