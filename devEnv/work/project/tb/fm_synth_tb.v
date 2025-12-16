`timescale 1ns / 1ps
//=============================================================================
// File         : fm_synth_tb.v
// Author       : Mateo Almeida
// Description  :
//   Testbench for the fm_synth module. This testbench verifies the functional
//   behavior of the FM synthesizer, including envelope generation, frequency
//   modulation, and parameter responsiveness.
//
//   The testbench:
//     - Generates a 100 MHz system clock
//     - Applies a reset sequence
//     - Toggles the gate signal to trigger note on/off events
//     - Modifies synthesis parameters during runtime
//     - Captures waveform output for offline analysis
//
//   Waveform output is written to:
//     sim/build/fm_synth_tb.vcd
//
//=============================================================================

module fm_synth_tb;

    //-------------------------------------------------------------------------
    // Testbench parameters
    //-------------------------------------------------------------------------
    localparam integer CLK_PERIOD = 10; // 100 MHz clock period (ns)

    //-------------------------------------------------------------------------
    // Testbench signals
    //-------------------------------------------------------------------------
    reg clk  = 1'b0;
    reg rst  = 1'b1;
    reg gate = 1'b0;

    reg [31:0]        phase_inc_base = 32'd18516068;
    reg [31:0]        phase_inc_mod  = 32'd46380170;
    reg signed [15:0] beta           = 16'd2048;
    reg signed [15:0] feedback       = 16'd512;
    reg [15:0]        gain           = 16'd2048;
    reg [15:0]        attack_rate    = 16'd256;
    reg [15:0]        decay_rate     = 16'd64;
    reg [15:0]        sustain_level  = 16'd2048;

    wire signed [15:0] sample;
    wire               sample_valid;

    //-------------------------------------------------------------------------
    // Clock generation
    //-------------------------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------------------------------
    // Device Under Test (DUT)
    //-------------------------------------------------------------------------
    fm_synth dut (
        .clk            (clk),
        .rst            (rst),
        .gate           (gate),
        .phase_inc_base (phase_inc_base),
        .phase_inc_mod  (phase_inc_mod),
        .beta           (beta),
        .feedback       (feedback),
        .gain           (gain),
        .attack_rate    (attack_rate),
        .decay_rate     (decay_rate),
        .sustain_level  (sustain_level),
        .sample         (sample),
        .sample_valid   (sample_valid)
    );

    //-------------------------------------------------------------------------
    // Waveform dump configuration
    //-------------------------------------------------------------------------
    initial begin
        // Dump waveform data to sim/build directory
        $dumpfile("sim/build/fm_synth_tb.vcd");
        $dumpvars(0, fm_synth_tb);
    end

    //-------------------------------------------------------------------------
    // Test sequence
    //-------------------------------------------------------------------------
    initial begin
        // Hold reset active
        #(20*CLK_PERIOD);
        rst <= 1'b0;
        #(20*CLK_PERIOD);

        // First note-on event
        gate <= 1'b1;
        #(2000*CLK_PERIOD);

        // Note-off
        gate <= 1'b0;
        #(500*CLK_PERIOD);

        // Modify modulation index during runtime
        beta <= 16'd1024;

        // Second note-on event with new beta value
        gate <= 1'b1;
        #(2000*CLK_PERIOD);

        // End simulation
        $finish;
    end

endmodule
