`timescale 1ns/1ps

module uart_pattern_top #(
    parameter integer CLK_FREQ_HZ = 1_600_000,
    parameter integer BAUD_RATE   = 100_000,
    parameter integer ID_LAST_DIGIT = 6
) (
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

    initial begin
        if (ID_LAST_DIGIT < 0 || ID_LAST_DIGIT > 9) begin
            $error("ID_LAST_DIGIT must be in the range 0..9 (decimal digit).");
        end
    end

    wire baud_tick;
    wire sampler_align;
    wire sampler_bit_valid;
    wire sampler_bit;
    wire sampler_busy;
    wire match_comb;
    wire [3:0] window_next;

    reg match_toggle;
    reg [1:0] match_sync;
    reg match_pending;

    baud_gen #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) u_baud_gen (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (sampler_busy),
        .align (sampler_align),
        .tick  (baud_tick)
    );

    uart_sampler #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) u_uart_sampler (
        .clk          (clk),
        .rst_n        (rst_n),
        .rx           (rx),
        .tick         (baud_tick),
        .align        (sampler_align),
        .bit_valid    (sampler_bit_valid),
        .bit_data     (sampler_bit),
        .framing_error(framing_error),
        .frame_done   (frame_done),
        .busy         (sampler_busy)
    );

    sipo_reg #(
        .WIDTH (8)
    ) u_sipo (
        .clk      (clk),
        .rst_n    (rst_n),
        .shift_en (sampler_bit_valid),
        .bit_in   (sampler_bit),
        .data_out (shift_window)
    );

    detector u_detector (
        .window  (shift_window[3:0]),
        .pattern (PATTERN),
        .match   (match_comb)
    );

    assign window_next = {shift_window[2:0], sampler_bit};

    // Latch the comparator result so the toggle runs one clock after the shift.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_pending <= 1'b0;
        end else if (sampler_bit_valid) begin
            match_pending <= (window_next == PATTERN);
        end else begin
            match_pending <= 1'b0;
        end
    end

    wire match_tick = match_pending;
    assign bit_strobe = sampler_bit_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_toggle <= 1'b0;
        end else if (match_tick) begin
            match_toggle <= ~match_toggle;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_sync <= 2'b00;
        end else begin
            match_sync <= {match_sync[0], match_toggle};
        end
    end

    assign match = match_sync[1] ^ match_sync[0];
endmodule
