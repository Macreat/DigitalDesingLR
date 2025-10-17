`timescale 1ns/1ps
module tb_two_state_fsm;
    reg clk;
    reg arst;
    reg [2:0] pos;
    wire dir;

    two_state_fsm dut(.clk(clk), .arst(arst), .pos(pos), .dir(dir));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("[tb_two_state_fsm] Start");
        arst = 1; pos = 0; @(posedge clk); #1; arst = 0;
        // Expect RIGHT initially
        if (dir !== 1) $fatal(1, "Initial dir not RIGHT");
        // Move to boundary 7; should flip to LEFT
        pos = 7; @(posedge clk); #1;
        if (dir !== 0) $fatal(1, "Did not flip to LEFT at pos=7");
        // Move to boundary 0; should flip to RIGHT
        pos = 0; @(posedge clk); #1;
        if (dir !== 1) $fatal(1, "Did not flip to RIGHT at pos=0");
        $display("[tb_two_state_fsm] PASS");
        $finish;
    end
endmodule

