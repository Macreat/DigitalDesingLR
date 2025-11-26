// pwm_divider.v
// Generates a tick at 50 kHz/(2^pow2*5^pow5) from a 50 MHz clock.
module pwm_divider #(
    parameter CLK_FREQ = 50_000_000
)(
    input  wire clk,
    input  wire rstn,
    input  wire [1:0] pow2,
    input  wire [1:0] pow5,
    output reg  tick     // one-cycle pulse at desired PWM base frequency
);
    localparam integer BASE_DIV = 1000; // 50 MHz / 1000 = 50 kHz

    reg [31:0] counter;
    reg [31:0] limit;

endmodule