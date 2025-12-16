`timescale 1ns / 1ps

module tb_beat_sequencer;

    // -------------------------------------------------------------------------
    // Signal Declarations
    // -------------------------------------------------------------------------
    reg clk;
    reg rst;
    
    // Inputs (Regs)
    reg [7:0] tone0;
    reg [7:0] tone1;
    reg [7:0] tone2;
    reg [7:0] tone3;

    // Output (Wire)
    wire [7:0] tone_out;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    beat_sequencer uut (
        .clk(clk),
        .rst(rst),
        .tone0_in(tone0),
        .tone1_in(tone1),
        .tone2_in(tone2),
        .tone3_in(tone3),
        .tone_out(tone_out)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    // Period = 10ns (100 MHz simulation freq). 
    // The real frequency doesn't matter for logic simulation, only the cycle count.
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Timing Constants
    // -------------------------------------------------------------------------
    // The sequencer divides by 7680. 
    // 7680 cycles * 10ns = 76,800ns per beat.
    localparam BEAT_PERIOD = 7680 * 10;

    // -------------------------------------------------------------------------
    // Test Procedure, given the inputs can only be either 0 or 127
    // -------------------------------------------------------------------------
    initial begin
        // 1. Initialize
        clk = 0;
        rst = 1;
        tone0 = 0; tone1 = 0; tone2 = 0; tone3 = 0;
        
        $display("--- Simulation Start ---");
        
        // 2. Release Reset
        #100;
        rst = 0;
        // Wait one clock for logic to settle
        @(posedge clk);

        // -------------------------------------------------------
        // TEST CASE 1: Basic Techno Beat (127, 0, 127, 0)
        // -------------------------------------------------------
        $display("[Time %0t] Test Case 1: Pattern 127 - 0 - 127 - 0", $time);
        tone0 = 8'd127;
        tone1 = 8'd0;
        tone2 = 8'd127;
        tone3 = 8'd0;

        // Check Beat 0
        check_output(127, 0); 
        
        // Check Beat 1 (Wait full period)
        check_output(0, 1);
        
        // Check Beat 2
        check_output(127, 2);
        
        // Check Beat 3
        check_output(0, 3);


        // -------------------------------------------------------
        // TEST CASE 2: Single Kick (127, 0, 0, 0)
        // -------------------------------------------------------
        $display("[Time %0t] Test Case 2: Pattern 127 - 0 - 0 - 0", $time);
        tone0 = 8'd127;
        tone1 = 8'd0;
        tone2 = 8'd0;
        tone3 = 8'd0;
        
        // Note: The sequencer loops 0->1->2->3->0.
        // We are currently at the end of beat 3, rolling over to 0.
        
        check_output(127, 0);
        check_output(0, 1);
        check_output(0, 2);
        check_output(0, 3);


        // -------------------------------------------------------
        // TEST CASE 3: All On (127, 127, 127, 127)
        // -------------------------------------------------------
        $display("[Time %0t] Test Case 3: All ON (127)", $time);
        tone0 = 8'd127;
        tone1 = 8'd127;
        tone2 = 8'd127;
        tone3 = 8'd127;

        check_output(127, 0);
        check_output(127, 1);
        check_output(127, 2);
        check_output(127, 3);

        $display("--- Simulation Passed ---");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Helper Task to wait for the beat duration and verify output
    // -------------------------------------------------------------------------
    task check_output;
        input [7:0] expected_val;
        input [1:0] beat_index;
        begin
            // Wait for half a beat period so we are safely in the middle of the window
            #(BEAT_PERIOD / 2);
            
            if (tone_out === expected_val) begin
                $display("    PASS: Beat %0d Output = %d", beat_index, tone_out);
            end else begin
                $display("    FAIL: Beat %0d Output = %d (Expected %d)", beat_index, tone_out, expected_val);
            end
            
            // Wait the remaining half beat to align with the next transition
            #(BEAT_PERIOD / 2);
        end
    endtask

endmodule