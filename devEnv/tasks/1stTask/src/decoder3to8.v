// 3-to-8 one-hot decoder (combinational)
module decoder3to8 (
    input  wire [2:0] sel,
    output wire [7:0] y
);
    assign y = 8'b0000_0001 << sel;
endmodule

