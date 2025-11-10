`timescale 1ns / 1ps
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

    wire rst = ~rst_n;

    wire [7:0] midi_byte;
    wire       midi_byte_valid;
    wire       midi_busy;
    wire       midi_framing_error;

    midi_uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(31_250)
    ) midi_rx_inst (
        .clk          (clk100),
        .rst          (rst),
        .rx           (midi_rx),
        .data_out     (midi_byte),
        .data_valid   (midi_byte_valid),
        .busy         (midi_busy),
        .framing_error(midi_framing_error)
    );

    wire [2:0] param_addr;
    wire [15:0] param_value;
    wire        param_valid;

    knob_param_decoder param_decoder (
        .clk        (clk100),
        .rst        (rst),
        .midi_data  (midi_byte),
        .midi_valid (midi_byte_valid),
        .param_addr (param_addr),
        .param_value(param_value),
        .param_valid(param_valid)
    );

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

    param_demux demux (
        .clk           (clk100),
        .rst           (rst),
        .param_addr    (param_addr),
        .param_value   (param_value),
        .param_valid   (param_valid),
        .phase_inc_base(phase_inc_base),
        .phase_inc_mod (phase_inc_mod),
        .beta          (beta),
        .decay         (decay),
        .gain          (gain),
        .feedback      (feedback),
        .attack        (attack),
        .sustain       (sustain),
        .timbre_sel    (timbre_sel),
        .update_pulse  (update_pulse)
    );

    wire gate = gate_button | user_sw[0];

    wire signed [15:0] synth_sample;
    wire               synth_valid;

    fm_synth synth (
        .clk           (clk100),
        .rst           (rst),
        .gate          (gate),
        .phase_inc_base(phase_inc_base),
        .phase_inc_mod (phase_inc_mod),
        .beta          (beta),
        .feedback      (feedback),
        .gain          (gain),
        .attack_rate   (attack),
        .decay_rate    (decay),
        .sustain_level (sustain),
        .sample        (synth_sample),
        .sample_valid  (synth_valid)
    );

    dma_stub capture (
        .clk          (clk100),
        .rst          (rst),
        .sample_in    (synth_sample),
        .sample_valid (synth_valid),
        .last_written (),
        .ready        ()
    );

    pwm_audio_out #(
        .SAMPLE_WIDTH(16)
    ) pwm (
        .clk      (clk100),
        .rst      (rst),
        .sample_in(synth_sample),
        .pwm_out_p(audio_pwm_p),
        .pwm_out_n(audio_pwm_n)
    );
endmodule
