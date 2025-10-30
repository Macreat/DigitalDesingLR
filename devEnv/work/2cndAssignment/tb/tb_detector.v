`timescale 1ns/1ps

module tb_detector;
    reg [3:0] window;
    reg [3:0] pattern;
    wire match;

    detector dut (
        .window (window),
        .pattern(pattern),
        .match  (match)
    );

    integer i;
    integer j;

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            pattern = i[3:0];
            for (j = 0; j < 16; j = j + 1) begin
                window = j[3:0];
                #1;
                if (match !== (window == pattern)) begin
                    $fatal(1, "Mismatch for window=%0d pattern=%0d (match=%0b)", window, pattern, match);
                end
            end
        end

        $display("tb_detector: PASS");
        $finish;
    end
    
    initial begin 
        $dumpfile("results/tb_detector.vcd");
        $dumpvars(0, tb_detector);
    end

endmodule
