`timescale 1ns / 1ps
//=============================================================================
// File         : nexys_audio_top.v
// Author       : Mateo Almeida
// Description  :
//   Top-level audio system for the Nexys Video FPGA board. This module
//   integrates MIDI input, parameter decoding, FM synthesis, and audio
//   output generation.
//
//   The system performs the following functions:
//     - Receives MIDI data via UART
//     - Decodes MIDI control data into synthesis parameters
//     - Demultiplexes parameters into dedicated control registers
//     - Generates audio samples using an FM synthesizer
//     - Routes audio samples to output modules (PWM audio output)
//     - Provides hooks for future DMA or audio interface integration
//
//   The design is clocked from a 100 MHz system clock and produces
//   single-ended or differential digital audio output suitable for
//   external filtering and amplification.
//
// Parameters:
//   CLK_FREQ_HZ : System clock frequency in Hz.
//
// Inputs:
//   clk100      : 100 MHz system clock.
//   rst_n       : Active-low external reset.
//   midi_rx     : MIDI serial input (31.25 kbaud).
//   gate_button : Manual gate control (push button).
//   user_sw     : User switches (used for gate and future features).
//
// Outputs:
//   audio_pwm_p : PWM audio output (positive).
//   audio_pwm_n : PWM audio output (negative/complementary).
//
//=============================================================================

module nexys_audio_top #(
    parameter integer CLK_FREQ_HZ = 100_000_000
) (
    input  wire clk100,
    input  wire rst_n,
    input  wire midi_rx,
    input  wire gate_button,
    input  wire [3:0] user_sw,
    output wire audio_pwm_p,
    output wire audio_pwm_n
);

    //-------------------------------------------------------------------------
    // Reset handling (convert active-low reset to active-high)
    //-------------------------------------------------------------------------
    wire rst = ~rst_n;

    //-------------------------------------------------------------------------
    // MIDI UART receiver signals
    //-------------------------------------------------------------------------
    wire [7:0] midi_byte;
    wire       midi_byte_valid;
    wire       midi_busy;
    wire       midi_framing_error;

    //-------------------------------------------------------------------------
    // MIDI UART receiver instance (31.25 kbaud standard MIDI)
    //-------------------------------------------------------------------------
    midi_uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE  (31_250)
    ) midi_rx_inst (
        .clk           (clk100),
        .rst           (rst),
        .rx            (midi_rx),
        .data_out      (midi_byte),
        .data_valid    (midi_byte_valid),
        .busy          (midi_busy),
        .framing_error (midi_framing_error)
    );

    //-------------------------------------------------------------------------
    // MIDI parameter decoding
    //-------------------------------------------------------------------------
    wire [2:0]  param_addr;
    wire [15:0] param_value;
    wire        param_valid;

    knob_param_decoder param_decoder (
        .clk         (clk100),
        .rst         (rst),
        .midi_data   (midi_byte),
        .midi_valid  (midi_byte_valid),
        .param_addr  (param_addr),
        .param_value (param_value),
        .param_valid (param_valid)
    );

    //-------------------------------------------------------------------------
    // Parameter registers and control signals
    //-------------------------------------------------------------------------
    wire [31:0] phase_inc_base;
    wire [31:0] phase_inc_mod;
    wire [15:0] beta;
    wire [15:0] decay;
    wire [15:0] gain;
    wire [15:0] feedback;
    wire [15:0] attack;
    wire [15:0] sustain;
    wire [3:0]  timbre_sel;
    wire        update_pulse;

    //-------------------------------------------------------------------------
    // Parameter demultiplexer
    //-------------------------------------------------------------------------
    param_demux demux (
        .clk            (clk100),
        .rst            (rst),
        .param_addr     (param_addr),
        .param_value    (param_value),
        .param_valid    (param_valid),
        .phase_inc_base (phase_inc_base),
        .phase_inc_mod  (phase_inc_mod),
        .beta           (beta),
        .decay          (decay),
        .gain           (gain),
        .feedback       (feedback),
        .attack         (attack),
        .sustain        (sustain),
        .timbre_sel     (timbre_sel),
        .update_pulse   (update_pulse)
    );

    //-------------------------------------------------------------------------
    // Gate logic (manual button OR user switch)
    //-------------------------------------------------------------------------
    wire gate = gate_button | user_sw[0];

    //-------------------------------------------------------------------------
    // FM synthesizer output
    //-------------------------------------------------------------------------
    wire signed [15:0] synth_sample;
    wire               synth_valid;

    fm_synth synth (
        .clk            (clk100),
        .rst            (rst),
        .gate           (gate),
        .phase_inc_base (phase_inc_base),
        .phase_inc_mod  (phase_inc_mod),
        .beta           (beta),
        .feedback       (feedback),
        .gain           (gain),
        .attack_rate    (attack),
        .decay_rate     (decay),
        .sustain_level  (sustain),
        .sample         (synth_sample),
        .sample_valid   (synth_valid)
    );

    //-------------------------------------------------------------------------
    // DMA stub (capture sink for development and testing)
    //-------------------------------------------------------------------------
    dma_stub capture (
        .clk           (clk100),
        .rst           (rst),
        .sample_in     (synth_sample),
        .sample_valid  (synth_valid),
        .last_written  (),
        .ready         ()
    );

    //-------------------------------------------------------------------------
    // PWM audio output stage
    //-------------------------------------------------------------------------
    pwm_audio_out #(
        .SAMPLE_WIDTH(16)
    ) pwm (
        .clk        (clk100),
        .rst        (rst),
        .sample_in  (synth_sample),
        .pwm_out_p (audio_pwm_p),
        .pwm_out_n (audio_pwm_n)
    );

endmodule
