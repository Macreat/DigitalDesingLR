`timescale 1ns / 1ps

module tb_wavegen;

    reg clk;
    reg [15:0] angle;
    wire [15:0] angle2;
    reg en;

    wire signed [15:0] wave;
    wire signed [15:0] wave2;
    wire ready;

    sine_wave_gen dut (
        .clk   (clk),
        .angle (angle),
        .en    (en),
        .wave  (wave),
        .ready (ready)
    );

    sine_wave_gen dut2 (
        .clk   (clk),
        .angle (angle2),
        .en    (en),
        .wave  (wave2),
        .ready ( )
    );

    assign angle2 = 10 * angle + 5 * wave;

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("sim/build/wavegen_tb.vcd");
        $dumpvars(0, tb_wavegen);

        en = 1'b1;
        angle = 16'd0;

        #100;

        // Simple sweep
        repeat (120000) begin
            angle = angle + 1'b1;
            #10;
        end

        $finish;
    end

endmodule
