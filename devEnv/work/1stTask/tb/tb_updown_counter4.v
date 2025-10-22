`timescale 1ns/1ps
module tb_updown_counter4;
    reg clk;
    reg arst;
    reg en;
    reg dir;
    wire [3:0] q;

    updown_counter4 dut(
        .clk(clk), .arst(arst), .en(en), .dir(dir), .q(q)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz -> 10ns period (scaled)

`ifdef WAVES
    initial begin
        $dumpfile("results/tb_updown_counter4.vcd");
        $dumpvars(0, tb_updown_counter4);
    end
`endif

    initial begin
        $display("[tb_updown_counter4] Start");
        arst = 1; en = 0; dir = 1; @(posedge clk); #1;
        if (q !== 4'd0) $fatal(1, "Reset failed");
        arst = 0; en = 1; dir = 1;
        repeat (5) @(posedge clk); #1; // allow NBA updates
        if (q !== 4'd5) $fatal(1, "Count up failed: q=%0d", q);
        dir = 0; // count down
        repeat (3) @(posedge clk); #1;
        if (q !== 4'd2) $fatal(1, "Count down failed: q=%0d", q);
        en = 0; repeat (2) @(posedge clk); #1;
        if (q !== 4'd2) $fatal(1, "Enable gating failed");
        $display("[tb_updown_counter4] PASS");
        $finish;
    end
endmodule
