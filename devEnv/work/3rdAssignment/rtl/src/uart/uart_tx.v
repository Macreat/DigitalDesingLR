// uart_tx.v
// Added full TX implementation: baud-timed bit shifting, frame loading,
// ready/accept signaling, and busy control.

module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rstn,
    input  wire tx_start,
    input  wire [7:0] tx_byte,
    output reg  tx,          // new: driven bit output
    output wire tx_ready,    // new: !busy status
    output reg  tx_accept    // new: acknowledges load event
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD; // new: baud-rate divider

    // new: counters and shift register for UART framing
    reg [9:0] baud_cnt;
    reg [3:0] bit_idx;
    reg [9:0] shreg;         // {stop, data[7:0], start}
    reg busy;

    assign tx_ready = !busy;

    always @(posedge clk) begin
        if (!rstn) begin
            // added reset initialization
            baud_cnt  <= 0;
            bit_idx   <= 0;
            shreg     <= 10'b1111111111;  // idle line high
            tx        <= 1'b1;
            busy      <= 1'b0;
            tx_accept <= 1'b0;

        end else begin
            tx_accept <= 1'b0;   // single-cycle pulse

            // -------------------------
            // new: load byte into frame
            // -------------------------
            if (!busy) begin
                if (tx_start) begin
                    shreg     <= {1'b1, tx_byte, 1'b0};  // stop, data, start
                    busy      <= 1'b1;
                    baud_cnt  <= BAUD_DIV - 1;
                    bit_idx   <= 0;
                    tx_accept <= 1'b1;
                    $display("UART_TX load byte %02x", tx_byte);
                end

            // -------------------------
            // new: baud-timed bit output
            // -------------------------
            end else begin
                if (baud_cnt == 0) begin
                    tx       <= shreg[0];         // output LSB
                    shreg    <= {1'b1, shreg[9:1]}; // shift right, keep stop=1 at MSB
                    bit_idx  <= bit_idx + 1;
                    baud_cnt <= BAUD_DIV - 1;

                    if (bit_idx == 9) begin       // all bits sent
                        busy <= 1'b0;
                        tx   <= 1'b1;             // return to idle
                    end

                end else begin
                    baud_cnt <= baud_cnt - 1;
                end
            end
        end
    end
endmodule
