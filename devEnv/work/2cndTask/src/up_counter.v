// 4-bit Up Counter with Enable (no reset port)
module up_counter(
    input wire clk,
    input wire en,       // Enable (input port)
    output reg [3:0] q   // 4-bit output
);
    // Initialize counter to zero
    initial q = 4'b0000;

    always @(posedge clk) begin
        if (en)
            q <= q + 1;
    end
endmodule
