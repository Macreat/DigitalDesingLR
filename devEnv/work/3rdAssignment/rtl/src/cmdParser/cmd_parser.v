// cmd_parser.v
// Added full command-parsing implementation: input buffering, CR/LF detection,
// command matching, response generation, numeric extraction, parameter updates,
// and byte-by-byte TX serialization.

module cmd_parser (
    input  wire clk,
    input  wire rstn,
    input  wire [7:0] rx_byte,
    input  wire rx_valid,
    input  wire start_pulse,   // new: clears end-of-string flag
    input  wire tx_ready,
    input  wire tx_accept,
    output reg  tx_start,      // new: triggers TX module
    output reg [7:0] tx_byte,  // new: response byte stream
    output reg [6:0] duty_percent,
    output reg [1:0] pow2,
    output reg [1:0] pow5,
    output reg  eostr_flag,    // new: marks end-of-string reception
    output reg  buffer_full    // new: stalls when >=32 bytes
);

    // new: store first 6 received bytes (longest command)
    reg [7:0] b0,b1,b2,b3,b4,b5;
    reg [5:0] byte_count;          // count up to 32
    reg [5:0] msg_len_capture;     // final length at CR/LF
    reg parse_pending;             // new: signals command ready
    reg parsing;                   // new: busy flag for parsing

    // new: response machinery
    reg [7:0] resp_byte;
    reg [5:0] resp_idx;
    reg [5:0] resp_len;
    reg [2:0] resp_type;           // 0=FAIL 1=OK 2=HELP 3=STATUS
    reg tx_accept_d;

    // new: helper for case-insensitive compare
    function [7:0] to_upper(input [7:0] c);
        begin
            if (c >= "a" && c <= "z") to_upper = c - 8'h20;
            else to_upper = c;
        end
    endfunction

    // reused: pow5 lookup for STATUS calculation
    function integer pow5_factor(input [1:0] p5);
        begin
            case (p5)
                2'd0: pow5_factor = 1;
                2'd1: pow5_factor = 5;
                2'd2: pow5_factor = 25;
                default: pow5_factor = 125;
            endcase
        end
    endfunction

    // new: scratch variables for DC / STATUS parsing
    integer val, v, freq;
    integer d0,d1,d2,d3,d4;

    always @(posedge clk) begin
        if (!rstn) begin
            // full initialization added
            b0 <= 0; b1 <= 0; b2 <= 0; b3 <= 0; b4 <= 0; b5 <= 0;
            byte_count <= 0;
            msg_len_capture <= 0;
            parse_pending <= 0;
            parsing <= 0;
            eostr_flag <= 0;
            buffer_full <= 0;
            duty_percent <= 0;
            pow2 <= 0;
            pow5 <= 0;
            resp_idx <= 0;
            resp_len <= 0;
            resp_type <= 0;
            tx_start <= 0;
            tx_byte <= 0;
            tx_accept_d <= 0;

        end else begin
            tx_start <= 1'b0;
            tx_accept_d <= tx_accept;

            // new: reset end-of-string flag on UART start bit
            if (start_pulse) eostr_flag <= 1'b0;

            // -------------------------
            // new: byte accumulation
            // -------------------------
            if (rx_valid && !parsing) begin
                if (rx_byte == 8'h0A || rx_byte == 8'h0D) begin
                    // CR/LF: capture message
                    msg_len_capture <= byte_count;
                    parse_pending <= 1'b1;
                    eostr_flag <= 1'b1;
                    byte_count <= 0;
                    buffer_full <= 0;
                end else if (!buffer_full) begin
                    // store up to 6 bytes for command decoding
                    case (byte_count)
                        0: b0 <= rx_byte;
                        1: b1 <= rx_byte;
                        2: b2 <= rx_byte;
                        3: b3 <= rx_byte;
                        4: b4 <= rx_byte;
                        5: b5 <= rx_byte;
                    endcase

                    if (byte_count == 6'd31)
                        buffer_full <= 1'b1;     // new: overflow protection
                    else
                        byte_count <= byte_count + 1;
                end
            end

            // -------------------------
            // new: TX serialization
            // -------------------------
            if (!parsing && resp_idx < resp_len && tx_ready) begin
                tx_byte <= resp_byte;
                tx_start <= 1'b1;
                $display("TX_REQ idx=%0d len=%0d byte=%02x type=%0d",
                         resp_idx, resp_len, resp_byte, resp_type);
            end
            if (tx_accept_d)
                resp_idx <= resp_idx + 1;

            // -------------------------
            // new: response selection
            // -------------------------
            case (resp_type)
                3'd0: begin // FAIL\n
                    case (resp_idx)
                        0: resp_byte <= "F";
                        1: resp_byte <= "A";
                        2: resp_byte <= "I";
                        3: resp_byte <= "L";
                        4: resp_byte <= "\n";
                        default: resp_byte <= 8'h00;
                    endcase
                end

                3'd1: begin // OK\n
                    case (resp_idx)
                        0: resp_byte <= "O";
                        1: resp_byte <= "K";
                        2: resp_byte <= "\n";
                        default: resp_byte <= 8'h00;
                    endcase
                end

                3'd2: begin // HELP text
                    // full help message added
                    case (resp_idx)
                        0: resp_byte <= "H";
                        1: resp_byte <= "E";
                        2: resp_byte <= "L";
                        3: resp_byte <= "P";
                        4: resp_byte <= ":";
                        5: resp_byte <= " ";
                        6: resp_byte <= "D";
                        7: resp_byte <= "C";
                        8: resp_byte <= "#";
                        9: resp_byte <= "#";
                        10: resp_byte <= ",";
                        11: resp_byte <= " ";
                        12: resp_byte <= "P";
                        13: resp_byte <= "O";
                        14: resp_byte <= "W";
                        15: resp_byte <= "2";
                        16: resp_byte <= "#";
                        17: resp_byte <= ",";
                        18: resp_byte <= " ";
                        19: resp_byte <= "P";
                        20: resp_byte <= "O";
                        21: resp_byte <= "W";
                        22: resp_byte <= "5";
                        23: resp_byte <= "#";
                        24: resp_byte <= ",";
                        25: resp_byte <= " ";
                        26: resp_byte <= "S";
                        27: resp_byte <= "T";
                        28: resp_byte <= "A";
                        29: resp_byte <= "T";
                        30: resp_byte <= "U";
                        31: resp_byte <= "S";
                        32: resp_byte <= "\n";
                        default: resp_byte <= 8'h00;
                    endcase
                end

                3'd3: begin // STATUS response
                    // numeric formatting added
                    case (resp_idx)
                        0: resp_byte <= "F";
                        1: resp_byte <= "R";
                        2: resp_byte <= "E";
                        3: resp_byte <= "Q";
                        4: resp_byte <= "=";
                        5: resp_byte <= "0"+d0;
                        6: resp_byte <= "0"+d1;
                        7: resp_byte <= "0"+d2;
                        8: resp_byte <= "0"+d3;
                        9: resp_byte <= "0"+d4;
                        10: resp_byte <= "H";
                        11: resp_byte <= "Z";
                        12: resp_byte <= ",";
                        13: resp_byte <= "D";
                        14: resp_byte <= "C";
                        15: resp_byte <= "=";
                        16: resp_byte <= "0"+((duty_percent/10)%10);
                        17: resp_byte <= "0"+(duty_percent%10);
                        18: resp_byte <= "%";
                        19: resp_byte <= "\n";
                        default: resp_byte <= 8'h00;
                    endcase
                end

                default: resp_byte <= 8'h00;
            endcase

            // -------------------------
            // new: command parser
            // -------------------------
            if (parse_pending && !parsing) begin
                parsing <= 1'b1;
                parse_pending <= 1'b0;
                resp_idx <= 0;
                resp_len <= 5;       // FAIL default
                resp_type <= 3'd0;

                // HELP
                if (msg_len_capture == 4 &&
                    to_upper(b0)=="H" && to_upper(b1)=="E" &&
                    to_upper(b2)=="L" && to_upper(b3)=="P") begin
                    resp_type <= 3'd2;
                    resp_len <= 33;

                // STATUS
                end else if (msg_len_capture == 6 &&
                    to_upper(b0)=="S" && to_upper(b1)=="T" &&
                    to_upper(b2)=="A" && to_upper(b3)=="T" &&
                    to_upper(b4)=="U" && to_upper(b5)=="S") begin
                    resp_type <= 3'd3;
                    resp_len <= 20;
                    freq = 50000 / ((1 << pow2) * pow5_factor(pow5));
                    d0 = (freq / 10000) % 10;
                    d1 = (freq / 1000) % 10;
                    d2 = (freq / 100) % 10;
                    d3 = (freq / 10) % 10;
                    d4 = freq % 10;

                // DC##
                end else if (msg_len_capture == 4 &&
                    to_upper(b0)=="D" && to_upper(b1)=="C") begin
                    val = 0;
                    if (b2 >= "0" && b2 <= "9") val = b2 - "0"; else val = 200;
                    if (b3 >= "0" && b3 <= "9") val = val*10 + (b3 - "0");
                    else val = 200;
                    if (val <= 99) begin
                        duty_percent <= val[6:0];
                        resp_type <= 3'd1;
                        resp_len <= 3;
                    end

                // POW2#
                end else if (msg_len_capture == 5 &&
                    to_upper(b0)=="P" && to_upper(b1)=="O" &&
                    to_upper(b2)=="W" && b3=="2") begin
                    if (b4 >= "0" && b4 <= "3") begin
                        v = b4 - "0";
                        pow2 <= v[1:0];
                        resp_type <= 3'd1;
                        resp_len <= 3;
                    end

                // POW5#
                end else if (msg_len_capture == 5 &&
                    to_upper(b0)=="P" && to_upper(b1)=="O" &&
                    to_upper(b2)=="W" && b3=="5") begin
                    if (b4 >= "0" && b4 <= "3") begin
                        v = b4 - "0";
                        pow5 <= v[1:0];
                        resp_type <= 3'd1;
                        resp_len <= 3;
                    end
                end

            end else if (parsing) begin
                parsing <= 1'b0;
            end
        end
    end
endmodule
