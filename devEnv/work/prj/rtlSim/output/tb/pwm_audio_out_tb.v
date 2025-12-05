`timescale 1ns / 1ps

module pwm_audio_out_tb;
    localparam integer CLK_PERIOD = 10;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg signed [15:0] sample = -16'sd32768;

    wire pwm_p;
    wire pwm_n;

    always #(CLK_PERIOD/2) clk = ~clk;

    pwm_audio_out dut (
        .clk      (clk),
        .rst      (rst),
        .sample_in(sample),
        .pwm_out_p(pwm_p),
        .pwm_out_n(pwm_n)
    );

    initial begin
        $dumpfile("sim/build/pwm_audio_out_tb.vcd");
        $dumpvars(0, pwm_audio_out_tb);
    end

    initial begin
        #(10*CLK_PERIOD);
        rst <= 1'b0;
        repeat (512) begin
            #(20*CLK_PERIOD);
            sample <= sample + 16'sd256;
        end
        $finish;
    end
endmodule
