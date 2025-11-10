`timescale 1ns / 1ps
// Demultiplexes parameter writes onto dedicated control registers.
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

    function [PHASE_WIDTH-1:0] expand_phase;
        input [VALUE_WIDTH-1:0] value;
        begin
            expand_phase = {{(PHASE_WIDTH-VALUE_WIDTH){1'b0}}, value};
        end
    endfunction

    localparam [PHASE_WIDTH-1:0] DEFAULT_BASE_INC = 32'd18516068; // ~432 Hz @ 100 MHz
    localparam [PHASE_WIDTH-1:0] DEFAULT_MOD_INC  = 32'd46380170; // ~1080 Hz

    always @(posedge clk) begin
        if (rst) begin
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
            update_pulse <= 1'b0;
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
                    default: ;
                endcase
            end
        end
    end
endmodule
