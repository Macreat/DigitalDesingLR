`timescale 1ns / 1ps
//=============================================================================
// File         : pwm_audio_out_tb.v
// Author       : Mateo Almeida
// Description  :
//   Testbench for the pwm_audio_out module. This testbench verifies correct
//   PWM generation from signed PCM audio samples.
//
//   The testbench sweeps the input sample value across a wide dynamic range,
//   allowing observation of the resulting PWM duty-cycle changes. Both the
//   primary and complementary PWM outputs are monitored.
//
//   Waveform output is written to:
//     sim/build/pwm_audio_out_tb.vcd
//
//=============================================================================

module pwm_audio_out_tb;

    //-------------------------------------------------------------------------
    // Testbench parameters
    //-------------------------------------------------------------------------
    localparam integer CLK_PERIOD = 10; // 100 MHz clock period (ns)

    //-------------------------------------------------------------------------
    // Testbench signals
    //-------------------------------------------------------------------------
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg signed [15:0] sample = -16'sd32768;

    wire pwm_p;
    wire pwm_n;

    //-------------------------------------------------------------------------
    // Clock generation
    //-------------------------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------------------------------
    // Device Under Test (DUT)
    //-------------------------------------------------------------------------
    pwm_audio_out dut (
        .clk        (clk),
        .rst        (rst),
        .sample_in  (sample),
        .pwm_out_p  (pwm_p),
        .pwm_out_n  (pwm_n)
    );

    //-------------------------------------------------------------------------
    // Waveform dump configuration
    //-------------------------------------------------------------------------
    initial begin
        // Dump waveform data to sim/build directory
        $dumpfile("sim/build/pwm_audio_out_tb.vcd");
        $dumpvars(0, pwm_audio_out_tb);
    end

    //-------------------------------------------------------------------------
    // Test sequence
    //-------------------------------------------------------------------------
    initial begin
        // Release reset
        #(10*CLK_PERIOD);
        rst <= 1'b0;

        // Sweep the sample value upward to observe duty-cycle variation
        repeat (512) begin
            #(20*CLK_PERIOD);
            sample <= sample + 16'sd256;
        end

        // End simulation
        $finish;
    end

endmodule
