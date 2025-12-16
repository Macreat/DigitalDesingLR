`timescale 1ns / 1ps
//=============================================================================
// File         : pcm_to_dsd.v
// Author       : Mateo Almeida
// Description  :
//   This module implements a second-order delta-sigma (ΔΣ) modulator that
//   converts signed PCM samples into a 1-bit DSD bitstream.
//
//   The design targets a DSD bit rate of approximately 3 MHz with an
//   oversampling ratio (OSR) of 64, corresponding to a PCM sample rate of
//   about 48 kHz when driven by a 100 MHz system clock.
//
//   The modulator uses:
//     - An integer clock divider to generate a uniform DSD bit strobe
//     - Two cascaded integrators (second-order loop)
//     - A 1-bit DAC feedback path representing full-scale PCM
//
//   Handshaking is provided so that a new PCM sample is requested exactly
//   once per OSR DSD ticks.
//
// Parameters:
//   SAMPLE_WIDTH : Bit width of the input PCM sample.
//   CLK_FREQ_HZ  : System clock frequency in Hz.
//   DSD_FREQ_HZ  : Target DSD bit frequency (must divide CLK_FREQ_HZ).
//   OSR          : Oversampling ratio (DSD bits per PCM sample).
//   GUARD_BITS   : Extra headroom bits for integrator accumulators.
//
// Inputs:
//   clk         : System clock.
//   rst         : Active-high synchronous reset.
//   pcm_sample  : Signed PCM input sample.
//   pcm_valid   : Indicates that pcm_sample is valid.
//
// Outputs:
//   pcm_ready   : One-cycle pulse requesting the next PCM sample.
//   dsd_bit     : 1-bit DSD output stream.
//   dsd_ce      : One-cycle strobe at the DSD bit rate.
//
//=============================================================================

module pcm_to_dsd #(
    parameter integer SAMPLE_WIDTH = 24,
    parameter integer CLK_FREQ_HZ  = 100_000_000,
    parameter integer DSD_FREQ_HZ  = 3_125_000,   // Must be an integer divisor of CLK_FREQ_HZ
    parameter integer OSR          = 64,          // DSD ticks per PCM sample
    parameter integer GUARD_BITS   = 6            // Integrator headroom
) (
    input  wire                           clk,
    input  wire                           rst,
    input  wire signed [SAMPLE_WIDTH-1:0] pcm_sample,
    input  wire                           pcm_valid,
    output reg                            pcm_ready,
    output reg                            dsd_bit,
    output reg                            dsd_ce
);

    //-------------------------------------------------------------------------
    // Derived constants
    //-------------------------------------------------------------------------
    localparam integer DSD_DIV       = CLK_FREQ_HZ / DSD_FREQ_HZ;
    localparam integer DSD_DIV_REM   = CLK_FREQ_HZ % DSD_FREQ_HZ;
    localparam integer DSD_DIV_WIDTH = (DSD_DIV <= 1) ? 1 : $clog2(DSD_DIV);
    localparam integer OSR_WIDTH     = (OSR <= 1) ? 1 : $clog2(OSR);
    localparam integer ACC_WIDTH     = SAMPLE_WIDTH + GUARD_BITS;

    //-------------------------------------------------------------------------
    // Enforce exact integer division for a uniform DSD clock enable
    //-------------------------------------------------------------------------
    initial begin
        if (DSD_DIV_REM != 0) begin
            $error(
                "pcm_to_dsd: CLK_FREQ_HZ (%0d) must be an integer multiple of DSD_FREQ_HZ (%0d)",
                CLK_FREQ_HZ, DSD_FREQ_HZ
            );
            $finish;
        end
    end

    //-------------------------------------------------------------------------
    // Internal registers
    //-------------------------------------------------------------------------
    reg [DSD_DIV_WIDTH-1:0] div_count;
    reg [OSR_WIDTH-1:0]     osr_count;

    reg signed [SAMPLE_WIDTH-1:0] pcm_latched;

    reg signed [ACC_WIDTH-1:0] acc1;
    reg signed [ACC_WIDTH-1:0] acc2;

    //-------------------------------------------------------------------------
    // Feedback level corresponding to full-scale PCM
    //-------------------------------------------------------------------------
    localparam signed [ACC_WIDTH-1:0] FEEDBACK_LEVEL =
        {{(ACC_WIDTH - SAMPLE_WIDTH){1'b0}}, 1'b1, {SAMPLE_WIDTH-1{1'b0}}};

    // Sign-extended PCM and feedback values
    wire signed [ACC_WIDTH-1:0] pcm_ext =
        {{GUARD_BITS{pcm_latched[SAMPLE_WIDTH-1]}}, pcm_latched};

    wire signed [ACC_WIDTH-1:0] fb_value =
        dsd_bit ? FEEDBACK_LEVEL : -FEEDBACK_LEVEL;

    //-------------------------------------------------------------------------
    // Main sequential logic
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // Reset initialization
            div_count   <= {DSD_DIV_WIDTH{1'b0}};
            osr_count   <= {OSR_WIDTH{1'b0}};
            pcm_latched <= {SAMPLE_WIDTH{1'b0}};
            acc1        <= {ACC_WIDTH{1'b0}};
            acc2        <= {ACC_WIDTH{1'b0}};
            dsd_bit     <= 1'b0;
            dsd_ce      <= 1'b0;
            pcm_ready   <= 1'b0;
        end else begin
            // Default outputs
            dsd_ce    <= 1'b0;
            pcm_ready <= 1'b0;

            // DSD clock enable generation
            if (div_count == DSD_DIV - 1) begin
                div_count <= {DSD_DIV_WIDTH{1'b0}};
                dsd_ce    <= 1'b1;

                // Request a new PCM sample once per OSR DSD bits
                if (osr_count == OSR - 1) begin
                    osr_count <= {OSR_WIDTH{1'b0}};
                    pcm_ready <= 1'b1;
                    if (pcm_valid) begin
                        pcm_latched <= pcm_sample;
                    end
                end else begin
                    osr_count <= osr_count + 1'b1;
                end

                // Second-order delta-sigma loop
                acc1    <= acc1 + pcm_ext - fb_value;
                acc2    <= acc2 + acc1    - fb_value;

                // Output bit: sign of second integrator
                dsd_bit <= ~acc2[ACC_WIDTH-1];
            end else begin
                div_count <= div_count + 1'b1;
            end
        end
    end

endmodule
