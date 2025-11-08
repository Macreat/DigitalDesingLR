`timescale 1ns/1ps
module uart_sampler #(
    parameter integer CLK_FREQ_HZ = 1_600_000,
    parameter integer BAUD_RATE   = 100_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rx,
    input  wire tick,
    output reg  align,
    output reg  bit_valid,
    output reg  bit_data,
    output reg  framing_error,
    output reg  frame_done,
    output reg  busy
);
    localparam integer BIT_TOTAL = 8;
    reg [3:0] bit_count;
    reg rx_d, rx_q;

    // sincroniza rx al clk
    always @(posedge clk) begin
        rx_q <= rx_d;
        rx_d <= rx;
    end

    wire start_detected = (rx_q == 1 && rx_d == 0); // flanco 1→0

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 0;
            align <= 0;
            bit_valid <= 0;
            frame_done <= 0;
            framing_error <= 0;
            bit_count <= 0;
        end else begin
            align <= 0;
            bit_valid <= 0;
            frame_done <= 0;

            if (!busy && start_detected) begin
                busy <= 1;
                align <= 1;     // reinicia baud_gen
                bit_count <= 0;
            end else if (busy && tick) begin
                bit_data <= rx_d;
                bit_valid <= 1;
                bit_count <= bit_count + 1;

                if (bit_count == BIT_TOTAL - 1) begin
                    busy <= 0;
                    frame_done <= 1;
                end
            end
        end
    end
endmodule
