// 4-bit up/down counter with async reset and enable
module updown_counter4 (
    input  wire       clk,
    input  wire       arst,    // asynchronous active-high reset
    input  wire       en,      // count enable
    input  wire       dir,     // 1 = up, 0 = down
    output reg  [3:0] q
);
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            q <= 4'd0;
        end else if (en) begin
            if (dir) q <= q + 4'd1;
            else     q <= q - 4'd1;
        end
    end
endmodule

