`timescale 1ns / 1ps
//=============================================================================
// File         : pcm_to_dsd_tb.v
// Author       : Mateo Almeida
// Description  :
//   Testbench for the pcm_to_dsd module. This testbench verifies the correct
//   operation of the PCM-to-DSD conversion process using a second-order
//   delta-sigma modulator.
//
//   A synthetic sine-wave PCM source is generated inside the testbench.
//   The PCM sample is updated only when the modulator asserts pcm_ready,
//   emulating a realistic producer–consumer handshake.
//
//   The testbench allows observation of:
//     - The DSD bitstream (dsd_bit)
//     - The DSD clock enable strobe (dsd_ce)
//     - The relationship between PCM input and PDM density
//
//   Waveform output is written to:
//     sim/build/pcm_to_dsd_tb.vcd
//
//=============================================================================

module pcm_to_dsd_tb;

    //-------------------------------------------------------------------------
    // Testbench parameters
    //-------------------------------------------------------------------------
    localparam integer SAMPLE_WIDTH = 24;
    localparam integer CLK_PERIOD   = 10;          // 100 MHz clock (ns)
    localparam integer DSD_FREQ_HZ  = 3_125_000;   // Target DSD bit rate
    localparam integer OSR          = 64;          // Oversampling ratio
    localparam real    TONE_HZ      = 1000.0;      // Test tone frequency
    localparam real    PCM_FS_HZ    = DSD_FREQ_HZ / real'(OSR); // ~48.8 kHz
    localparam real    TWO_PI       = 6.283185307179586;
    localparam integer AMP          = (1 << (SAMPLE_WIDTH-1)) - 1;

    //-------------------------------------------------------------------------
    // Testbench signals
    //-------------------------------------------------------------------------
    reg clk = 1'b0;
    reg rst = 1'b1;

    reg signed [SAMPLE_WIDTH-1:0] pcm_sample = 0;
    reg                           pcm_valid  = 1'b0;

    wire pcm_ready;
    wire dsd_bit;
    wire dsd_ce;

    real phase = 0.0;

    //-------------------------------------------------------------------------
    // Clock generation
    //-------------------------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------------------------------
    // Device Under Test (DUT)
    //-------------------------------------------------------------------------
    pcm_to_dsd #(
        .SAMPLE_WIDTH(SAMPLE_WIDTH),
        .CLK_FREQ_HZ (100_000_000),
        .DSD_FREQ_HZ (DSD_FREQ_HZ),
        .OSR         (OSR)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .pcm_sample (pcm_sample),
        .pcm_valid  (pcm_valid),
        .pcm_ready  (pcm_ready),
        .dsd_bit    (dsd_bit),
        .dsd_ce     (dsd_ce)
    );

    //-------------------------------------------------------------------------
    // Waveform dump configuration
    //-------------------------------------------------------------------------
    initial begin
        // Dump waveform data to sim/build directory
        $dumpfile("sim/build/pcm_to_dsd_tb.vcd");
        $dumpvars(0, pcm_to_dsd_tb);
    end

    //-------------------------------------------------------------------------
    // PCM sine-wave source
    // Description:
    //   Generates a sine-wave PCM signal. The sample is updated only when
    //   pcm_ready is asserted by the modulator, ensuring proper synchronization
    //   with the oversampling ratio.
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            pcm_sample <= 0;
            pcm_valid  <= 1'b0;
            phase      <= 0.0;
        end else begin
            pcm_valid <= 1'b0;
            if (pcm_ready) begin
                phase = phase + (TWO_PI * TONE_HZ / PCM_FS_HZ);
                pcm_sample <= $rtoi($sin(phase) * AMP);
                pcm_valid  <= 1'b1;
            end
        end
    end

    //-------------------------------------------------------------------------
    // Test sequence
    //-------------------------------------------------------------------------
    initial begin
        // Release reset
        #(20*CLK_PERIOD);
        rst <= 1'b0;

        // Run simulation long enough to observe several milliseconds of DSD data
        #(5_000_000);

        // End simulation
        $finish;
    end

endmodule
