`timescale 1ns / 1ps

module tb_acumulador_msb;

    // --- Signal Declarations ---
    reg        clk;
    reg        rst;
    reg  [8:0] f;
    wire [15:0] q_out;

    // --- Instantiate the Device Under Test (DUT) ---
    acumulador_msb uut (
        .clk(clk),
        .rst(rst),
        .f(f),
        .q_out(q_out)
    );

    // --- Clock Generation ---
    // 10ns clock period (100 MHz)
    always begin
        #5 clk = ~clk;
    end

    // --- Test Stimulus ---
    initial begin
        // 1. Initialize Signals
        clk = 0;
        rst = 1;
        f   = 0;
        
        // Setup monitoring to print changes to console
        $monitor("Time=%0t | rst=%b | Input f=%d | Output q_out=%d", 
                 $time, rst, f, q_out);

        // 2. Apply Reset
        #20;
        rst = 0;
        $display("--- Reset Released ---");

        // ---------------------------------------------------------
        // CASE 1: Test Maximum Input (f = 435)
        // Expected behavior: Fast ramp up
        // Increment per cycle: 435 * 402 = 174,870
        // Cycles to increase Output by 1: ~96 cycles
        // ---------------------------------------------------------
        f = 9'd435;
        $display("--- Testing Max Value (f=435) ---");
        
        // Run for 2000 clock cycles (should see output increase by ~20)
        repeat (2000) @(posedge clk);


        // ---------------------------------------------------------
        // CASE 2: Test Minimum Input (f = 8)
        // Expected behavior: Very slow ramp up
        // Increment per cycle: 8 * 402 = 3,216
        // Cycles to increase Output by 1: ~5,217 cycles
        // ---------------------------------------------------------
        f = 9'd8;
        $display("--- Testing Min Value (f=8) ---");
        $display("--- Note: This takes ~5200 cycles to change output once ---");

        // Run for 12,000 clock cycles (should see output increase by ~2)
        repeat (12000) @(posedge clk);


        // ---------------------------------------------------------
        // CASE 3: Test Reset during operation
        // ---------------------------------------------------------
        $display("--- Testing Reset ---");
        rst = 1;
        #20;
        if (q_out == 0) 
            $display("SUCCESS: Output cleared on reset.");
        else 
            $display("FAILURE: Output did not clear.");
            
        rst = 0;
        #100;

        // End Simulation
        $display("--- End of Simulation ---");
        $finish;
    end

endmodule