// uart_rx.v
// UART receiver with start/stop framing, approximate 16x oversampling (single sample mid-bit),
// and start_pulse for downstream end-of-string flag clearing.
// Assumes clk = 50 MHz, baud = 115200 (BAUD_DIV about 434). One idle bit between bytes is expected.
module uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rstn,
    input  wire rx,
    output reg  rx_valid,
    output reg [7:0] rx_byte,
    output reg  start_pulse,   // asserted for 1 clk when a start bit is latched
    output reg  framing_error
);
    localparam integer BAUD_DIV = CLK_FREQ / BAUD;          // 434
    localparam integer MID_CNT  = BAUD_DIV / 2;

    reg rx_meta, rx_sync;
    reg [9:0] baud_cnt;
    reg [3:0] bit_idx;
    reg [7:0] shreg;

    typedef enum reg [2:0] {IDLE, START, DATA, STOP, WAIT_GAP} state_t;
    state_t state;
endmodule