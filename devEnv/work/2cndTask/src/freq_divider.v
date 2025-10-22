// Frequency Divider Module
// Divides 50MHz input clock to 1Hz output clock
module freq_divider(
    input wire clk_in,      // 50MHz clock input
    output reg clk_out      // 1Hz clock output
);
    // 50,000,000 cycles for 1Hz
    localparam DIVISOR = 50000000;
    reg [25:0] count;

    // Initialize registers so divider starts deterministically (no reset port)
    initial begin
        count = 0;
        clk_out = 0;
    end

    always @(posedge clk_in) begin
        if (count == (DIVISOR/2 - 1)) begin
            clk_out <= ~clk_out;
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end
endmodule
