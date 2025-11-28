`timescale 1ns / 1ps

module pcm_to_dsd_tb;
    localparam integer SAMPLE_WIDTH = 24;
    localparam integer CLK_PERIOD   = 10;          // 100 MHz
    localparam integer DSD_FREQ_HZ  = 3_125_000;
    localparam integer OSR          = 64;
    localparam real    TONE_HZ      = 1000.0;
    localparam real    PCM_FS_HZ    = DSD_FREQ_HZ / real'(OSR); // ~48.8 kHz
    localparam real    TWO_PI       = 6.283185307179586;
    localparam integer AMP          = (1 << (SAMPLE_WIDTH-1)) - 1;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg signed [SAMPLE_WIDTH-1:0] pcm_sample = 0;
    reg pcm_valid = 1'b0;
    wire pcm_ready;
    wire dsd_bit;
    wire dsd_ce;

    real phase = 0.0;

    always #(CLK_PERIOD/2) clk = ~clk;

    pcm_to_dsd #(
        .SAMPLE_WIDTH(SAMPLE_WIDTH),
        .CLK_FREQ_HZ (100_000_000),
        .DSD_FREQ_HZ (DSD_FREQ_HZ),
        .OSR         (OSR)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .pcm_sample(pcm_sample),
        .pcm_valid (pcm_valid),
        .pcm_ready (pcm_ready),
        .dsd_bit   (dsd_bit),
        .dsd_ce    (dsd_ce)
    );

    initial begin
        $dumpfile("sim/build/pcm_to_dsd_tb.vcd");
        $dumpvars(0, pcm_to_dsd_tb);
    end

    // Simple sine source (updates when the modulator asks for a new PCM sample).
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

    initial begin
        #(20*CLK_PERIOD);
        rst <= 1'b0;
        #(5_000_000); // run long enough to observe several ms of DSD stream
        $finish;
    end
endmodule
