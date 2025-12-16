`timescale 1ns / 1ps
//=============================================================================
// File         : nexys_audio_top_tb.v
// Author       : Mateo Almeida
// Description  :
//   Top-level system testbench for the nexys_audio_top module. This testbench
//   verifies the integration of MIDI input handling, parameter decoding,
//   FM synthesis, and PWM audio output.
//
//   The testbench simulates:
//     - System clock and reset behavior
//     - MIDI UART traffic to configure synthesis parameters
//     - Manual and switch-based gate control
//     - End-to-end audio signal flow up to the PWM output
//
//   Waveform output is written to:
//     sim/build/nexys_audio_top_tb.vcd
//
//=============================================================================

module nexys_audio_top_tb;

    //-------------------------------------------------------------------------
    // Testbench parameters
    //-------------------------------------------------------------------------
    localparam integer CLK_PERIOD = 10;       // 100 MHz system clock (ns)
    localparam integer BIT_PERIOD = 32_000;   // MIDI UART bit period (31.25 kbaud)

    //-------------------------------------------------------------------------
    // Testbench signals
    //-------------------------------------------------------------------------
    reg clk         = 1'b0;
    reg rst_n       = 1'b0;   // Active-low reset
    reg midi_rx     = 1'b1;   // UART idle state
    reg gate_button = 1'b0;
    reg [3:0] user_sw = 4'b0000;

    wire audio_pwm_p;
    wire audio_pwm_n;

    //-------------------------------------------------------------------------
    // Clock generation
    //-------------------------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------------------------------
    // Device Under Test (DUT)
    //-------------------------------------------------------------------------
    nexys_audio_top dut (
        .clk100      (clk),
        .rst_n       (rst_n),
        .midi_rx     (midi_rx),
        .gate_button (gate_button),
        .user_sw     (user_sw),
        .audio_pwm_p (audio_pwm_p),
        .audio_pwm_n (audio_pwm_n)
    );

    //-------------------------------------------------------------------------
    // Task: send_midi
    // Description:
    //   Sends a single MIDI-formatted byte over the simulated UART interface.
    //   The format follows standard 8-N-1 asynchronous serial transmission.
    //-------------------------------------------------------------------------
    task send_midi(input [7:0] data);
        integer i;
        begin
            // Start bit
            midi_rx <= 1'b0;
            #(BIT_PERIOD);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                midi_rx <= data[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            midi_rx <= 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    //-------------------------------------------------------------------------
    // Waveform dump configuration
    //-------------------------------------------------------------------------
    initial begin
        // Dump waveform data to sim/build directory
        $dumpfile("sim/build/nexys_audio_top_tb.vcd");
        $dumpvars(0, nexys_audio_top_tb);
    end

    //-------------------------------------------------------------------------
    // Test sequence
    //-------------------------------------------------------------------------
    initial begin
        // Hold reset low at startup
        #(50*CLK_PERIOD);
        rst_n <= 1'b1;
        #(50*CLK_PERIOD);

        // Configure synthesis parameters via MIDI
        send_midi(8'b0010_1111); // Base phase increment (coarse)
        send_midi(8'b0110_0001); // Modulation index (beta)
        send_midi(8'b1110_0101); // Output gain

        // Trigger note using gate button
        gate_button <= 1'b1;
        #(10_000*CLK_PERIOD);
        gate_button <= 1'b0;

        // Trigger note using user switch
        #(5_000*CLK_PERIOD);
        user_sw[0] <= 1'b1;
        #(5_000*CLK_PERIOD);

        // End simulation
        $finish;
    end

endmodule
