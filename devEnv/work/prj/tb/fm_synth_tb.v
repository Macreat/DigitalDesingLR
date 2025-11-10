`timescale 1ns / 1ps

module fm_synth_tb;
    localparam integer CLK_PERIOD = 10; // 100 MHz

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg gate = 1'b0;

    reg [31:0] phase_inc_base = 32'd18516068;
    reg [31:0] phase_inc_mod  = 32'd46380170;
    reg signed [15:0] beta    = 16'd2048;
    reg signed [15:0] feedback= 16'd512;
    reg [15:0] gain           = 16'd2048;
    reg [15:0] attack_rate    = 16'd256;
    reg [15:0] decay_rate     = 16'd64;
    reg [15:0] sustain_level  = 16'd2048;

    wire signed [15:0] sample;
    wire sample_valid;

    always #(CLK_PERIOD/2) clk = ~clk;

    fm_synth dut (
        .clk           (clk),
        .rst           (rst),
        .gate          (gate),
        .phase_inc_base(phase_inc_base),
        .phase_inc_mod (phase_inc_mod),
        .beta          (beta),
        .feedback      (feedback),
        .gain          (gain),
        .attack_rate   (attack_rate),
        .decay_rate    (decay_rate),
        .sustain_level (sustain_level),
        .sample        (sample),
        .sample_valid  (sample_valid)
    );

    initial begin
        $dumpfile("sim/build/fm_synth_tb.vcd");
        $dumpvars(0, fm_synth_tb);
    end

    initial begin
        #(20*CLK_PERIOD);
        rst <= 1'b0;
        #(20*CLK_PERIOD);
        gate <= 1'b1;
        #(2000*CLK_PERIOD);
        gate <= 1'b0;
        #(500*CLK_PERIOD);
        beta <= 16'd1024;
        gate <= 1'b1;
        #(2000*CLK_PERIOD);
        $finish;
    end
endmodule
