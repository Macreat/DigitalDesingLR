`timescale 1ns / 1ps

module top (
    input  wire clk100,      // Reloj de 100 MHz de la Nexys Video
    output wire dsd_out      // Salida hacia PMOD JA1 (pin J1)
);

    // ------------------------------------------------------------
    // 1. Generador de seno PCM mediante sine_wave_ob
    // ------------------------------------------------------------
    wire signed [15:0] pcm16;
    reg  [17:0] step = 18'd5000;  // Frecuencia de la onda PCM

    sine_wave_ob #(
        .TABLE_BITS(6),
        .AMP_BITS(16),
        .INDEX_BITS(18)
    ) sine_gen_inst (
        .clk(clk100),
        .rst(1'b0),
        .step(step),
        .sine_out(pcm16)
    );

    // Expandir la onda de 16 bits → 24 bits para alimentar pcm_to_dsd
    wire signed [23:0] pcm24 = { pcm16[15], pcm16, 7'b0 };

    // ------------------------------------------------------------
    // 2. Delta-Sigma PCM → DSD
    // ------------------------------------------------------------
    wire pcm_ready;
    wire dsd_bit;
    wire dsd_ce;

    pcm_to_dsd #(
        .SAMPLE_WIDTH(24),
        .CLK_FREQ_HZ (100_000_000),
        .DSD_FREQ_HZ (3_125_000),
        .OSR         (64)
    ) dsd_mod_inst (
        .clk(clk100),
        .rst(1'b0),
        .pcm_sample(pcm24),
        .pcm_valid(1'b1),    // siempre válido
        .pcm_ready(pcm_ready),
        .dsd_bit(dsd_bit),
        .dsd_ce(dsd_ce)
    );

    // ------------------------------------------------------------
    // 3. Conectar dsd_bit a salida física
    // ------------------------------------------------------------
    assign dsd_out = dsd_bit;

endmodule
