`timescale 1ns / 1ps
// Delta-Sigma modulator: signed PCM to 1-bit DSD stream.
// Designed for ~3 MHz bit rate with OSR=64 (about 48 kHz PCM) on a 100 MHz clock.
module pcm_to_dsd #(
    parameter integer SAMPLE_WIDTH = 24,
    parameter integer CLK_FREQ_HZ  = 100_000_000,
    parameter integer DSD_FREQ_HZ  = 3_125_000,   // use an integer divider of CLK_FREQ_HZ
    parameter integer OSR          = 64,          // oversampling ratio (DSD ticks per PCM sample)
    parameter integer GUARD_BITS   = 6            // headroom bits for integrators
) (
    input  wire                         clk,
    input  wire                         rst,
    input  wire signed [SAMPLE_WIDTH-1:0] pcm_sample,
    input  wire                         pcm_valid,
    output reg                          pcm_ready,
    output reg                          dsd_bit,
    output reg                          dsd_ce      // 1-cycle strobe at DSD bit rate
);

    localparam integer DSD_DIV = CLK_FREQ_HZ / DSD_FREQ_HZ;
    localparam integer DSD_DIV_REM = CLK_FREQ_HZ % DSD_FREQ_HZ;
    localparam integer DSD_DIV_WIDTH = (DSD_DIV <= 1) ? 1 : $clog2(DSD_DIV);
    localparam integer OSR_WIDTH = (OSR <= 1) ? 1 : $clog2(OSR);
    localparam integer ACC_WIDTH = SAMPLE_WIDTH + GUARD_BITS;

    // Enforce integer division so the DSD CE stays uniform.
    initial begin
        if (DSD_DIV_REM != 0) begin
            $error("pcm_to_dsd: CLK_FREQ_HZ (%0d) must be an integer multiple of DSD_FREQ_HZ (%0d)", CLK_FREQ_HZ, DSD_FREQ_HZ);
            $finish;
        end
    end

    reg [DSD_DIV_WIDTH-1:0] div_count;
    reg [OSR_WIDTH-1:0]     osr_count;

    reg signed [SAMPLE_WIDTH-1:0] pcm_latched;

    reg signed [ACC_WIDTH-1:0] acc1;
    reg signed [ACC_WIDTH-1:0] acc2;

    // Feedback level represents full-scale of the incoming PCM.
    localparam signed [ACC_WIDTH-1:0] FEEDBACK_LEVEL =
        {{(ACC_WIDTH - SAMPLE_WIDTH){1'b0}}, 1'b1, {SAMPLE_WIDTH-1{1'b0}}};

    wire signed [ACC_WIDTH-1:0] pcm_ext = {{GUARD_BITS{pcm_latched[SAMPLE_WIDTH-1]}}, pcm_latched};
    wire signed [ACC_WIDTH-1:0] fb_value = dsd_bit ? FEEDBACK_LEVEL : -FEEDBACK_LEVEL;

    always @(posedge clk) begin
        if (rst) begin
            div_count  <= {DSD_DIV_WIDTH{1'b0}};
            osr_count  <= {OSR_WIDTH{1'b0}};
            pcm_latched <= {SAMPLE_WIDTH{1'b0}};
            acc1       <= {ACC_WIDTH{1'b0}};
            acc2       <= {ACC_WIDTH{1'b0}};
            dsd_bit    <= 1'b0;
            dsd_ce     <= 1'b0;
            pcm_ready  <= 1'b0;
        end else begin
            dsd_ce    <= 1'b0;
            pcm_ready <= 1'b0;

            if (div_count == DSD_DIV-1) begin
                div_count <= {DSD_DIV_WIDTH{1'b0}};
                dsd_ce    <= 1'b1;

                // Request/consume next PCM sample once per OSR ticks.
                if (osr_count == OSR-1) begin
                    osr_count <= {OSR_WIDTH{1'b0}};
                    pcm_ready <= 1'b1;
                    if (pcm_valid) begin
                        pcm_latched <= pcm_sample;
                    end
                end else begin
                    osr_count <= osr_count + 1'b1;
                end

                // 2nd-order loop: two cascaded integrators with 1-bit DAC feedback.
                acc1    <= acc1 + pcm_ext - fb_value;
                acc2    <= acc2 + acc1 - fb_value;
                dsd_bit <= ~acc2[ACC_WIDTH-1]; // MSB is the sign; invert to map >=0 -> 1
            end else begin
                div_count <= div_count + 1'b1;
            end
        end
    end
endmodule
