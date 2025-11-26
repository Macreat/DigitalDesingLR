// top_pwm_uart.v
// Integrates UART RX/TX, command parser, and centered PWM generator.
module top_pwm_uart #(
    parameter CLK_FREQ = 50_000_000
)(
    input  wire clk,
    input  wire rstn,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire pwm_o,
    output wire [6:0] duty_percent_o,
    output wire [1:0] pow2_o,
    output wire [1:0] pow5_o,
    output wire eostr_flag_o,
    output wire [7:0] dbg_tx_byte,
    output wire dbg_tx_accept
);
    wire rx_valid;
    wire [7:0] rx_byte;
    wire start_pulse;
    wire framing_error;

    wire tx_ready;
    wire tx_start;
    wire [7:0] tx_byte;
    wire tx_accept;

    wire [6:0] duty_percent;
    wire [1:0] pow2;
    wire [1:0] pow5;

    uart_rx #(.CLK_FREQ(CLK_FREQ)) u_rx (
        .clk(clk),
        .rstn(rstn),
        .rx(uart_rx_i),
        .rx_valid(rx_valid),
        .rx_byte(rx_byte),
        .start_pulse(start_pulse),
        .framing_error(framing_error)
    );

    cmd_parser u_parser (
        .clk(clk),
        .rstn(rstn),
        .rx_byte(rx_byte),
        .rx_valid(rx_valid),
        .start_pulse(start_pulse),
        .tx_ready(tx_ready),
        .tx_accept(tx_accept),
        .tx_start(tx_start),
        .tx_byte(tx_byte),
        .duty_percent(duty_percent),
        .pow2(pow2),
        .pow5(pow5),
        .eostr_flag(eostr_flag_o),
        .buffer_full()
    );

    uart_tx #(.CLK_FREQ(CLK_FREQ)) u_tx (
        .clk(clk),
        .rstn(rstn),
        .tx_start(tx_start),
        .tx_byte(tx_byte),
        .tx(uart_tx_o),
        .tx_ready(tx_ready),
        .tx_accept(tx_accept)
    );

    pwm_core #(.CLK_FREQ(CLK_FREQ)) u_pwm (
        .clk(clk),
        .rstn(rstn),
        .duty_percent_in(duty_percent),
        .pow2(pow2),
        .pow5(pow5),
        .pwm_out(pwm_o),
        .period_count()
    );

    reg [7:0] dbg_tx_byte_r;

endmodule
