// Top Module: Connects Frequency Divider and 4-bit Up Counter
module top(
    input wire clk_in,   // 50MHz clock input
    input wire en,       // Enable for counter
    output wire [3:0] q  // Counter output
);
    wire clk_1hz;

    freq_divider u_divider(
        .clk_in(clk_in),
        .clk_out(clk_1hz)
    );

    up_counter u_counter(
        .clk(clk_1hz),
        .en(en),
        .q(q)
    );
endmodule
