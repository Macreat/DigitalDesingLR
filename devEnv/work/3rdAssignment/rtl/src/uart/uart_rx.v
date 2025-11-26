// uart_rx.v
// Added full RX implementation: synchronizer, state machine, mid-bit sampling,
// data shifting, stop-bit check, framing error detection, and gap enforcement.

module uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rstn,
    input  wire rx,
    output reg  rx_valid,
    output reg [7:0] rx_byte,
    output reg  start_pulse,     // new: 1-cycle marker when start bit is detected
    output reg  framing_error    // new: high when stop bit is invalid
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD;   // new: baud counter base
    localparam integer MID_CNT  = BAUD_DIV / 2;      // new: mid-start sample

    // new: synchronizer, counters, bit index, data shift reg
    reg rx_meta, rx_sync;
    reg [9:0] baud_cnt;
    reg [3:0] bit_idx;
    reg [7:0] shreg;

    // new: full RX FSM
    typedef enum reg [2:0] {IDLE, START, DATA, STOP, WAIT_GAP} state_t;
    state_t state;

    always @(posedge clk) begin
        if (!rstn) begin
            rx_meta       <= 1'b1;
            rx_sync       <= 1'b1;
            baud_cnt      <= 0;
            bit_idx       <= 0;
            shreg         <= 0;
            rx_valid      <= 1'b0;
            rx_byte       <= 8'h00;
            start_pulse   <= 1'b0;
            framing_error <= 1'b0;
            state         <= IDLE;
        end else begin
            // synchronize incoming rx
            rx_meta <= rx;
            rx_sync <= rx_meta;

            // single-cycle outputs
            rx_valid    <= 1'b0;
            start_pulse <= 1'b0;

            case (state)

                IDLE: begin
                    framing_error <= 1'b0;
                    if (!rx_sync) begin
                        state       <= START;
                        baud_cnt    <= MID_CNT;
                        start_pulse <= 1'b1;
                        $display("UART_RX start detect");
                    end
                end

                START: begin
                    if (baud_cnt == 0) begin
                        if (!rx_sync) begin
                            baud_cnt <= BAUD_DIV - 1;
                            bit_idx  <= 0;
                            state    <= DATA;
                        end else begin
                            state <= IDLE;  // false start
                        end
                    end else baud_cnt <= baud_cnt - 1;
                end

                DATA: begin
                    if (baud_cnt == 0) begin
                        shreg[bit_idx] <= rx_sync;     // LSB first
                        baud_cnt       <= BAUD_DIV - 1;
                        if (bit_idx == 7) state <= STOP;
                        else bit_idx <= bit_idx + 1;
                    end else baud_cnt <= baud_cnt - 1;
                end

                STOP: begin
                    if (baud_cnt == 0) begin
                        rx_byte       <= shreg;
                        rx_valid      <= 1'b1;
                        $display("UART_RX byte %02x", shreg);
                        framing_error <= (rx_sync == 1'b0);
                        state         <= WAIT_GAP;
                        baud_cnt      <= BAUD_DIV - 1;
                    end else baud_cnt <= baud_cnt - 1;
                end

                WAIT_GAP: begin
                    if (baud_cnt == 0) state <= IDLE;
                    else baud_cnt <= baud_cnt - 1;
                end

            endcase
        end
    end
endmodule
