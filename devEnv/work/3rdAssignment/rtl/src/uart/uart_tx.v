// uart_tx.v
// UART transmitter: loads one byte with tx_start and emits start + 8 data bits LSB-first + stop.
// Assumes clk = 50 MHz, baud = 115200 (BAUD_DIV about 434). Exposes tx_ready when idle.
module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rstn,
    input  wire tx_start,
    input  wire [7:0] tx_byte,
    output reg  tx,
    output wire tx_ready,
    output reg  tx_accept
);
    localparam integer BAUD_DIV = CLK_FREQ / BAUD; // 434

    reg [9:0] baud_cnt;
    reg [3:0] bit_idx;
    reg [9:0] shreg; // start + data + stop
    reg busy;

    assign tx_ready = !busy;

endmodule