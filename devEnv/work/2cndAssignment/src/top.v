`timescale 1ns/1ps
module top #(
    parameter integer CLK_FREQ_HZ = 1_600_000,
    parameter integer BAUD_RATE   = 100_000,
    parameter integer ID_LAST_DIGIT = 6
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rx,
    output wire match,
    output wire framing_error,
    output wire [7:0] shift_window,
    output wire frame_done,
    output wire bit_strobe
);
    localparam [3:0] PATTERN = ID_LAST_DIGIT[3:0];

    wire baud_tick, sampler_align, sampler_bit_valid, sampler_bit, sampler_busy;
    wire match_comb;
    wire [3:0] window_next;
    reg match_toggle;
    reg [1:0] match_sync;
    reg match_pending;

    baud_gen #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD_RATE(BAUD_RATE)) U_BAUD (
        .clk(clk), .rst_n(rst_n),
        .en(sampler_busy), .align(sampler_align), .tick(baud_tick)
    );

    uart_sampler #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD_RATE(BAUD_RATE)) U_SAMPLER (
        .clk(clk), .rst_n(rst_n), .rx(rx),
        .tick(baud_tick), .align(sampler_align),
        .bit_valid(sampler_bit_valid),
        .bit_data(sampler_bit),
        .framing_error(framing_error),
        .frame_done(frame_done),
        .busy(sampler_busy)
    );

    sipo_reg #(.WIDTH(8)) U_SIPO (
        .clk(clk), .rst_n(rst_n),
        .shift_en(sampler_bit_valid),
        .bit_in(sampler_bit),
        .data_out(shift_window)
    );

    detector U_DETECTOR (
        .window(shift_window[3:0]),
        .pattern(PATTERN),
        .match(match_comb)
    );

    assign window_next = {shift_window[2:0], sampler_bit};
    assign bit_strobe = sampler_bit_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_pending <= 0;
        else if (sampler_bit_valid)
            match_pending <= (window_next == PATTERN);
        else
            match_pending <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_toggle <= 0;
        else if (match_pending)
            match_toggle <= ~match_toggle;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_sync <= 0;
        else
            match_sync <= {match_sync[0], match_toggle};
    end

    assign match = match_sync[1] ^ match_sync[0];
endmodule
