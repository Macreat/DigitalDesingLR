// cmd_parser.v
// Parses UART bytes into commands (HELP, STATUS, DC##, POW2#, POW5#) and emits responses.
// Tracks up to 32 bytes (stall when >=32) and latches end-of-string on CR/LF.
module cmd_parser (
    input  wire clk,
    input  wire rstn,
    input  wire [7:0] rx_byte,
    input  wire rx_valid,
    input  wire start_pulse,  // asserted by UART RX on start bit, used to clear eostr_flag
    input  wire tx_ready,
    input  wire tx_accept,
    output reg  tx_start,
    output reg [7:0] tx_byte,
    output reg [6:0] duty_percent,
    output reg [1:0] pow2,
    output reg [1:0] pow5,
    output reg  eostr_flag,
    output reg  buffer_full
);
    // store first 6 bytes (covers longest command)
    reg [7:0] b0,b1,b2,b3,b4,b5;
    reg [5:0] byte_count;     // counts up to 32
    reg [5:0] msg_len_capture;
    reg parse_pending;
    reg parsing;

    reg [7:0] resp_byte;
    reg [5:0] resp_idx;
    reg [5:0] resp_len;
    reg [2:0] resp_type; // 0=FAIL 1=OK 2=HELP 3=STATUS
    reg tx_accept_d;

endmodule