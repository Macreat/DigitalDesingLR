`timescale 1ns/1ps

module uart_sampler #(
    parameter integer CLK_FREQ_HZ = 25_000_000,
    parameter integer BAUD_RATE   = 115_200
) (
    input  wire clk,
    input  wire rst_n,
    input  wire rx,
    input  wire tick,
    output reg  align,
    output reg  bit_valid,
    output reg  bit_data,
    output reg  framing_error,
    output reg  frame_done,
    output wire busy
);
    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;

    reg [1:0] state;
    reg [2:0] bit_index;
    reg [2:0] rx_pipe;

    wire rx_sync  = rx_pipe[2];
    wire rx_prev  = rx_pipe[1];
    wire start_edge = (rx_prev == 1'b1) && (rx_sync == 1'b0);

    assign busy = (state != STATE_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= STATE_IDLE;
            bit_index     <= 3'd0;
            rx_pipe       <= 3'b111;  // Idle line is high.
            align         <= 1'b0;
            bit_valid     <= 1'b0;
            bit_data      <= 1'b0;
            framing_error <= 1'b0;
            frame_done    <= 1'b0;
        end else begin
            // Synchronize RX line to internal clock domain.
            rx_pipe <= {rx_pipe[1:0], rx};

            // Default pulse outputs.
            align      <= 1'b0;
            bit_valid  <= 1'b0;
            frame_done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    framing_error <= 1'b0;
                    bit_index     <= 3'd0;

                    if (start_edge) begin
                        state     <= STATE_START;
                        align     <= 1'b1;
                    end
                end

                STATE_START: begin
                    if (tick) begin
                        if (rx_sync == 1'b0) begin
                            state     <= STATE_DATA;
                            bit_index <= 3'd0;
                        end else begin
                            // Start bit sampled high: treat as glitch.
                            framing_error <= 1'b1;
                            state         <= STATE_IDLE;
                        end
                    end
                end

                STATE_DATA: begin
                    if (tick) begin
                        bit_data  <= rx_sync;
                        bit_valid <= 1'b1;

                        if (bit_index == 3'd7) begin
                            state     <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end
                end

                STATE_STOP: begin
                    if (tick) begin
                        framing_error <= (rx_sync == 1'b0);
                        frame_done    <= 1'b1;
                        state         <= STATE_IDLE;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
