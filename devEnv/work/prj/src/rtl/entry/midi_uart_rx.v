`timescale 1ns / 1ps
// Simple MIDI UART receiver for 31.25 kbaud streams.
module midi_uart_rx #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE   = 31_250 //  Configure BAUD rate del receptor UART (detección de stop y bits¿?)
) (
    
    //
    input  wire clk,
    input  wire rst,
    input  wire rx,
    output reg  [7:0] data_out, // this is the data byte to deliver 
    output reg        data_valid, // 
    output reg        busy,
    output reg        framing_error
);

    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE; // 
    localparam integer CTR_WIDTH    = $clog2(CLKS_PER_BIT + 1); // 

    localparam [2:0] STATE_IDLE  = 3'd0;
    localparam [2:0] STATE_START = 3'd1;
    localparam [2:0] STATE_DATA  = 3'd2;
    localparam [2:0] STATE_STOP  = 3'd3;

    reg [2:0] state;
    reg [CTR_WIDTH-1:0] clk_count;
    reg [2:0] bit_index;
    reg rx_sync0;
    reg rx_sync1;

    // Synchronize RX line to clk domain.
    always @(posedge clk) begin
        rx_sync0 <= rx;
        rx_sync1 <= rx_sync0;
    end

    always @(posedge clk) begin
        if (rst) begin
            state         <= STATE_IDLE;
            clk_count     <= {CTR_WIDTH{1'b0}};
            bit_index     <= 3'd0;
            data_out      <= 8'd0;
            data_valid    <= 1'b0;
            busy          <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    if (~rx_sync1) begin // start bit detected
                        busy      <= 1'b1;
                        clk_count <= CLKS_PER_BIT[CTR_WIDTH-1:0] >> 1;
                        state     <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (clk_count == 0) begin
                        if (~rx_sync1) begin
                            clk_count <= CLKS_PER_BIT[CTR_WIDTH-1:0] - 1'b1;
                            bit_index <= 3'd0;
                            state     <= STATE_DATA;
                        end else begin
                            state <= STATE_IDLE; // false start
                        end
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                STATE_DATA: begin
                    if (clk_count == 0) begin
                        data_out[bit_index] <= rx_sync1;
                        clk_count           <= CLKS_PER_BIT[CTR_WIDTH-1:0] - 1'b1;
                        if (bit_index == 3'd7) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (clk_count == 0) begin
                        framing_error <= ~rx_sync1;
                        data_valid    <= rx_sync1;
                        state         <= STATE_IDLE;
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
