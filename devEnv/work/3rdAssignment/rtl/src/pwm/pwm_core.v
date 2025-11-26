// pwm_core.v
// Generates a centered PWM waveform whose period is 50 kHz/(2^pow2*5^pow5) at 50 MHz.
// duty_percent accepted range 0..99; values above 99 are ignored (no change).
module pwm_core #(
    parameter CLK_FREQ = 50_000_000
)(
    input  wire clk,
    input  wire rstn,
    input  wire [6:0] duty_percent_in,
    input  wire [1:0] pow2,
    input  wire [1:0] pow5,
    output reg  pwm_out,
    output reg [31:0] period_count   // number of clk cycles per PWM period
);
    localparam integer BASE_DIV = 1000; // 50 MHz / 1000 = 50 kHz

    reg [6:0] duty_percent;
    reg [31:0] count;
    reg [31:0] on_ticks;
    reg [31:0] start_off;


endmodule