`timescale 1ns/1ps
module pwm_core_full_tb;

    localparam CLK_FREQ = 50_000_000;
    localparam BAUD     = 115200;

    reg clk  = 0;
    reg rstn = 0;

    reg  [6:0] duty_percent_in = 0;
    reg  [1:0] pow2 = 0;
    reg  [1:0] pow5 = 0;

    wire tick;
    wire pwm_out;
    wire [31:0] period_count;

    always #10 clk = ~clk; // 50 MHz

    pwm_divider #(.CLK_FREQ(CLK_FREQ)) DIV (
        .clk(clk),
        .rstn(rstn),
        .pow2(pow2),
        .pow5(pow5),
        .tick(tick)
    );

    pwm_core #(.CLK_FREQ(CLK_FREQ)) CORE (
        .clk(clk),
        .rstn(rstn),
        .duty_percent_in(duty_percent_in),
        .pow2(pow2),
        .pow5(pow5),
        .pwm_out(pwm_out),
        .period_count(period_count)
    );

    initial begin
        $dumpfile("buildTemp/gtkWaveVCDFiles/pwm_core_full_tb.vcd");
        $dumpvars(0, pwm_core_full_tb);

        #200 rstn = 1;

        duty_percent_in = 30; pow2 = 0; pow5 = 0;
        #200_000;

        duty_percent_in = 50; pow2 = 1; pow5 = 0;
        #200_000;

        duty_percent_in = 75; pow2 = 1; pow5 = 1;
        #300_000;

        duty_percent_in = 10; pow2 = 2; pow5 = 1;
        #300_000;

        $finish;
    end
endmodule
