`timescale 1ns / 1ps
module pwm_audio_out #(
    parameter integer SAMPLE_WIDTH      = 16,
    parameter integer PWM_COUNTER_WIDTH = 10
) (
    input  wire                        clk,
    input  wire                        rst,
    input  wire signed [SAMPLE_WIDTH-1:0] sample_in,
    output reg                         pwm_out_p,
    output wire                        pwm_out_n
);

    reg [PWM_COUNTER_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= {PWM_COUNTER_WIDTH{1'b0}};
        end else begin
            counter <= counter + 1'b1;
        end
    end

    wire [SAMPLE_WIDTH:0] bias_sum =
        {1'b0, sample_in} + (1'b1 << (SAMPLE_WIDTH-1));
    wire [PWM_COUNTER_WIDTH-1:0] threshold =
        bias_sum[SAMPLE_WIDTH - 1 -: PWM_COUNTER_WIDTH];

    always @(posedge clk) begin
        pwm_out_p <= (counter < threshold);
    end

    assign pwm_out_n = ~pwm_out_p;
endmodule
