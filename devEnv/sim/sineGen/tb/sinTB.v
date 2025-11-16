`timescale 1ns/1ps
module tb_sine_wave_ob;
    reg clk, rst;
    wire [7:0] sine_out;
    wire signed [23:0] pcm_sample;

    // DUT
    sine_wave_ob #(.TABLE_BITS(6), .AMP_BITS(8)) dut (
        .clk(clk),
        .rst(rst),
        .sine_out(sine_out),
        .pcm_sample(pcm_sample)
    );

    // 50 MHz clock
    initial begin clk = 0; forever #10 clk = ~clk; end

    initial begin
        $dumpfile("sine_wave_self.vcd");
        $dumpvars(0, tb_sine_wave_ob);
        rst = 1; #100; rst = 0;

        // run long enough to see several cycles
        #10000;
        $finish;
    end

    initial begin
        $display("t(ns)\tidx\tsine_out\tpcm_sample");
        $monitor("%0t\t%0d\t%0d\t%d", 
                 $time, dut.idx, sine_out, pcm_sample);
    end
endmodule
