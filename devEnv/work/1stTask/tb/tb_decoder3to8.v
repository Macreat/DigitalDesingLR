`timescale 1ns/1ps
module tb_decoder3to8;
    reg  [2:0] sel;
    wire [7:0] y;

    decoder3to8 dut(.sel(sel), .y(y));

`ifdef WAVES
    initial begin
        $dumpfile("results/tb_decoder3to8.vcd");
        $dumpvars(0, tb_decoder3to8);
    end
`endif

    integer i;
    initial begin
        $display("[tb_decoder3to8] Start");
        for (i = 0; i < 8; i = i + 1) begin
            sel = i[2:0];
            #1;
            if (y !== (8'b0000_0001 << sel)) begin
                $fatal(1, "Decoder mismatch at sel=%0d: y=%b", sel, y);
            end
        end
        $display("[tb_decoder3to8] PASS");
        $finish;
    end
endmodule
