`timescale 1ns / 1ps

module tb_wrap_rad_L8;

    // Inputs
    reg clk;
    reg rst;
    reg en;
    reg signed [7:0] angle_in;

    // Outputs
    wire [15:0] angle_out;
    wire ready;

    // Instantiate the Unit Under Test (UUT)
    wrap_rad_L8 uut (
        .clk(clk), 
        .rst(rst), 
        .en(en), 
        .angle_in(angle_in), 
        .angle_out(angle_out), 
        .ready(ready)
    );

    // Clock generation (100MHz equivalent)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        en = 0;
        angle_in = 0;

        // Wait 100 ns for global reset to finish
        #100;
        rst = 0;
        #20;

        // -------------------------------------------------
        // TEST CASE 1: Zero Input
        // -------------------------------------------------
        $display("--- Test Case 1: Input 0 ---");
        drive_input(0);
        check_result(0); // Expect 0

        // -------------------------------------------------
        // TEST CASE 2: No Wrap Needed (Input 3)
        // 3 radians is < 2pi (6.28), so output should be 3
        // -------------------------------------------------
        $display("--- Test Case 2: Input 3 (No Wrap) ---");
        drive_input(3);
        check_result(3); 

        // -------------------------------------------------
        // TEST CASE 3: Positive Wrap (Input 7)
        // 7 radians is > 2pi (6.28). 
        // 7 - 6.28 = 0.72. 
        // Logic: 0.72 * 256 = 184. 184 >> 8 = 0.
        // Expect output 0 due to integer truncation
        // -------------------------------------------------
        $display("--- Test Case 3: Input 7 (Just over 2pi) ---");
        drive_input(7);
        // Explanation: 7 is wrapped to ~0.71. 
        // The module shifts right by 8 bits, effectively acting as floor().
        // floor(0.71) = 0.
        check_result(0);

        // -------------------------------------------------
        // TEST CASE 4: Negative Wrap (Input -1)
        // -1 radians + 6.28 = 5.28
        // Floor(5.28) = 5
        // -------------------------------------------------
        $display("--- Test Case 4: Input -1 (Negative) ---");
        drive_input(-1);
        check_result(5);

        // -------------------------------------------------
        // TEST CASE 5: Max Limit (Input 100)
        // 100 / 2pi = 15.91 cycles.
        // Remainder = 0.91 * 2pi = 5.76 radians
        // Floor(5.76) = 5
        // -------------------------------------------------
        $display("--- Test Case 5: Input 100 (Max Positive) ---");
        drive_input(100);
        check_result(5);

        // -------------------------------------------------
        // TEST CASE 6: Min Limit (Input -100)
        // -100 radians. 
        // -100 + (16 * 2pi) = -100 + 100.53 = 0.53 radians
        // Floor(0.53) = 0
        // -------------------------------------------------
        $display("--- Test Case 6: Input -100 (Max Negative) ---");
        drive_input(-100);
        check_result(0);

        $display("--- All Tests Completed ---");
        $finish;
    end

    // Task to drive inputs comfortably
    task drive_input;
        input signed [7:0] val;
        begin
            @(posedge clk);
            angle_in = val;
            en = 1;
            @(posedge clk);
            en = 0;
            // Wait for ready
            wait(ready);
            @(posedge clk); // one extra cycle to settle
        end
    endtask

    // Task to check results
    task check_result;
        input [15:0] expected;
        begin
            if (angle_out == expected)
                $display("PASS: Input %d -> Output %d", angle_in, angle_out);
            else
                $display("FAIL: Input %d -> Output %d (Expected %d)", angle_in, angle_out, expected);
        end
    endtask

endmodule