`timescale 1ns/1ps
module tb_top_knightrider;
    reg clk;
    reg arst;
    reg en;
    wire [7:0] leds;

    top_knightrider dut(
        .clk(clk), .arst(arst), .en(en), .leds(leds)
    );

    initial clk = 0; always #5 clk = ~clk; // 100MHz simulated

`ifdef WAVES
    initial begin
        $dumpfile("results/tb_top_knightrider.vcd");
        $dumpvars(0, tb_top_knightrider);
    end
`endif

    // Check that pattern bounces: 0000_0001 -> ... -> 1000_0000 -> 0100_0000 -> ...
    reg [7:0] expected;
    integer i;
    initial begin
        $display("[tb_top_knightrider] Start");
        arst = 1; en = 0; @(posedge clk); #1; arst = 0; en = 1;

        // Immediately after releasing reset and enabling, LED should be at LSB
        expected = 8'b0000_0001;
        #1;
        if (leds !== expected) $fatal(1, "Initial mismatch: leds=%b exp=%b", leds, expected);

        // First ascend 1..7 (since we already checked position 0)
        expected = 8'b0000_0010;
        for (i = 1; i < 8; i = i + 1) begin
            @(posedge clk); #1;
            if (leds !== expected) $fatal(1, "Ascend mismatch at step %0d: leds=%b exp=%b", i, leds, expected);
            expected = (i < 7) ? (expected << 1) : (8'b0100_0000); // after reaching MSB, next should be one step left
        end
        // Descend 6..0
        for (i = 6; i >= 0; i = i - 1) begin
            @(posedge clk); #1;
            if (leds !== expected) $fatal(1, "Descend mismatch at pos %0d: leds=%b exp=%b", i, leds, expected);
            expected = (i > 0) ? (expected >> 1) : (8'b0000_0010); // next cycle would go right again
        end

        $display("[tb_top_knightrider] PASS");
        $finish;
    end
endmodule
