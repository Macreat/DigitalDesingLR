// top_pwm_uart.v
// Added full system integration: UART RX, parser, UART TX, PWM core,
// debug registers, and top-level signal routing.

module top_pwm_uart #(
    parameter CLK_FREQ = 50_000_000
)(
    input  wire clk,
    input  wire rstn,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire pwm_o,
    output wire [6:0] duty_percent_o,   // new: exposed control values
    output wire [1:0] pow2_o,
    output wire [1:0] pow5_o,
    output wire eostr_flag_o,           // new: parser end-of-string indicator
    output wire [7:0] dbg_tx_byte,      // new: debug output
    output wire dbg_tx_accept
);

    // new: interconnect wires
    wire        rx_valid;
    wire [7:0]  rx_byte;
    wire        start_pulse;
    wire        framing_error;

    wire        tx_ready;
    wire        tx_start;
    wire [7:0]  tx_byte;
    wire        tx_accept;

    wire [6:0]  duty_percent;
    wire [1:0]  pow2;
    wire [1:0]  pow5;

    // new: instantiated UART RX
    uart_rx #(.CLK_FREQ(CLK_FREQ)) u_rx (
        .clk(clk),
        .rstn(rstn),
        .rx(uart_rx_i),
        .rx_valid(rx_valid),
        .rx_byte(rx_byte),
        .start_pulse(start_pulse),
        .framing_error(framing_error)
    );

    // new: command parser instance wired to RX/TX
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

    // new: UART TX instance
    uart_tx #(.CLK_FREQ(CLK_FREQ)) u_tx (
        .clk(clk),
        .rstn(rstn),
        .tx_start(tx_start),
        .tx_byte(tx_byte),
        .tx(uart_tx_o),
        .tx_ready(tx_ready),
        .tx_accept(tx_accept)
    );

    // new: PWM core driven by parsed parameters
    pwm_core #(.CLK_FREQ(CLK_FREQ)) u_pwm (
        .clk(clk),
        .rstn(rstn),
        .duty_percent_in(duty_percent),
        .pow2(pow2),
        .pow5(pow5),
        .pwm_out(pwm_o),
        .period_count()
    );

    // new: debug latch for transmitted bytes
    reg [7:0] dbg_tx_byte_r;
    always @(posedge clk) begin
        if (!rstn) dbg_tx_byte_r <= 8'h00;
        else if (tx_accept) dbg_tx_byte_r <= tx_byte;
    end

    // new: exported status signals
    assign duty_percent_o = duty_percent;
    assign pow2_o         = pow2;
    assign pow5_o         = pow5;
    assign dbg_tx_byte    = dbg_tx_byte_r;
    assign dbg_tx_accept  = tx_accept;

endmodule
