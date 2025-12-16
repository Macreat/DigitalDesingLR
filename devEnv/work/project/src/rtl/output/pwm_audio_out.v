`timescale 1ns / 1ps
//=============================================================================
// File         : pwm_audio_out.v
// Author       : Mateo Almeida
// Description  :
//   This module implements a simple PWM-based audio output stage. It converts
//   signed PCM audio samples into a high-frequency pulse-width modulated (PWM)
//   signal suitable for driving an external low-pass filter or audio amplifier.
//
//   The signed input sample is first biased to an unsigned range and then
//   compared against a free-running counter to generate the PWM waveform.
//   A complementary output is also provided for differential or push-pull
//   configurations.
//
// Parameters:
//   SAMPLE_WIDTH       : Bit width of the signed input audio sample.
//   PWM_COUNTER_WIDTH  : Bit width of the PWM counter, which determines the
//                        PWM resolution and carrier frequency.
//
// Inputs:
//   clk         : System clock.
//   rst         : Active-high synchronous reset.
//   sample_in   : Signed PCM audio sample.
//
// Outputs:
//   pwm_out_p   : PWM output (non-inverted).
//   pwm_out_n   : PWM output (inverted/complementary).
//
//=============================================================================

module pwm_audio_out #(
    parameter integer SAMPLE_WIDTH      = 16,
    parameter integer PWM_COUNTER_WIDTH = 10
) (
    input  wire                           clk,
    input  wire                           rst,
    input  wire signed [SAMPLE_WIDTH-1:0] sample_in,
    output reg                            pwm_out_p,
    output wire                           pwm_out_n
);

    //-------------------------------------------------------------------------
    // Free-running PWM counter
    //-------------------------------------------------------------------------
    reg [PWM_COUNTER_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= {PWM_COUNTER_WIDTH{1'b0}};
        end else begin
            counter <= counter + 1'b1;
        end
    end

    //-------------------------------------------------------------------------
    // Bias signed sample to unsigned range and derive PWM threshold
    //-------------------------------------------------------------------------
    wire [SAMPLE_WIDTH:0] bias_sum =
        {1'b0, sample_in} + (1'b1 << (SAMPLE_WIDTH-1));

    // Take the most significant bits as the PWM threshold
    wire [PWM_COUNTER_WIDTH-1:0] threshold =
        bias_sum[SAMPLE_WIDTH - 1 -: PWM_COUNTER_WIDTH];

    //-------------------------------------------------------------------------
    // PWM generation logic
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        pwm_out_p <= (counter < threshold);
    end

    // Complementary PWM output
    assign pwm_out_n = ~pwm_out_p;

endmodule
