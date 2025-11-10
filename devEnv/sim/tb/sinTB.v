`timescale 1ns/1ps
module tb_sine_wave_ob;
    reg clk, rst;
    reg  [5:0] step;
    wire [7:0] sine_out;
    wire signed [23:0] pcm_sample;

    // DUT
    sine_wave_ob #(.TABLE_BITS(6), .AMP_BITS(8)) dut (
        .clk(clk),
        .rst(rst),
        .step(step),
        .sine_out(sine_out),
        .pcm_sample(pcm_sample)
    );

    // 50 MHz
    initial begin clk = 0; forever #10 clk = ~clk; end

    initial begin
        $dumpfile("sine_wave.vcd");
        $dumpvars(0, tb_sine_wave_ob);

        // reset
        rst = 1; step = 6'd0;
        #100; rst = 0;

        // test several frequencies
        step = 6'd1;   #4000;
        step = 6'd2;   #4000;
        step = 6'd4;   #4000;
        step = 6'd8;   #4000;

        $finish;
    end

    initial begin
        $display("t(ns)\tstep\tindex\tsine_out\tpcm_sample");
        $monitor("%0t\t%0d\t%0d\t%0d\t%d", 
                 $time, step, dut.index, sine_out, pcm_sample);
    end
endmodule
