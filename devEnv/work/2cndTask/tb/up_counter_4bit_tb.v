`timescale 1ns/1ps

// Testbench for up_counter.v
module up_counter_4bit_tb;
    reg clk;
    reg en;
    wire [3:0] q;

    // Instantiate the Unit Under Test
    up_counter uut (
        .clk(clk),
        .en(en),
        .q(q)
    );

    initial begin
        $dumpfile("up_counter_tb.vcd");
        $dumpvars(0, uut);

        // Initialize signals
        clk = 0;
        en  = 0;

        // Enable counting after a few cycles
        #10 en = 1;

        // Toggle enable during simulation to test gating
        #200 en = 0;
        #40 en = 1;

        // Finish after enough time
        #300 $display("Simulation finished");
        $finish;
    end

    // Simple clock: 10 ns period (100 MHz) - only for simulation speed
    always #5 clk = ~clk;

    // Optional monitoring
    initial begin
        $display("time\tclk en q");
        $monitor("%0t\t%b   %b  %b", $time, clk, en, q);
    end

endmodule
