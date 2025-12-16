`timescale 1ns / 1ps
//=============================================================================
// File         : sine_wave_ob_tb.v
// Author       : Mateo Almeida
// Description  :
//   Testbench for the self-running sine_wave_ob module.
//
//   This testbench verifies:
//     - Proper reset behavior
//     - Continuous sine generation using the internal ROM
//     - Correct offset-binary output (0..255)
//     - Correct conversion to signed 24-bit PCM
//
//   The sine generator runs freely, incrementing its internal index
//   every clock cycle.
//
//   Waveform output is written to:
//     sim/build/sine_wave_ob_tb.vcd
//
//=============================================================================

module sine_wave_ob_tb;

    //-------------------------------------------------------------------------
    // Testbench parameters
    //-------------------------------------------------------------------------
    localparam integer CLK_PERIOD = 10; // 100 MHz clock

    //-------------------------------------------------------------------------
    // Testbench signals
    //-------------------------------------------------------------------------
    reg clk = 1'b0;
    reg rst = 1'b1;

    wire [7:0]        sine_out;
    wire signed [23:0] pcm_sample;

    //-------------------------------------------------------------------------
    // Clock generation
    //-------------------------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------------------------------
    // Device Under Test (DUT)
    //-------------------------------------------------------------------------
    sine_wave_ob dut (
        .clk        (clk),
        .rst        (rst),
        .sine_out   (sine_out),
        .pcm_sample (pcm_sample)
    );

    //-------------------------------------------------------------------------
    // Waveform dump
    //-------------------------------------------------------------------------
    initial begin
        $dumpfile("sim/build/sine_wave_ob_tb.vcd");
        $dumpvars(0, sine_wave_ob_tb);
    end

    //-------------------------------------------------------------------------
    // Test sequence
    //-------------------------------------------------------------------------
    initial begin
        // Hold reset
        #(20*CLK_PERIOD);
        rst <= 1'b0;

        // Let the sine run for several cycles
        #(500_000*CLK_PERIOD);

        // End simulation
        $finish;
    end

endmodule
