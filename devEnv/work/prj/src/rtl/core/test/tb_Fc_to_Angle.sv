`timescale 1ns / 1ps

module tb_acumulador_msb_Fc;

    // --------------------------------------------------------
    // 1. Inputs and Outputs , given the range of 435 to 7000 
    // --------------------------------------------------------
    reg clk;
    reg rst;
    reg [12:0] f;       // 13-bit input
    wire [15:0] q_out;  // 16-bit output

    // --------------------------------------------------------
    // 2. Instantiate the Device Under Test (DUT)
    // --------------------------------------------------------
    acumulador_msb_Fc uut (
        .clk(clk),
        .rst(rst),
        .f(f),
        .q_out(q_out)
    );

    // --------------------------------------------------------
    // 3. Constants matching the DUT
    // --------------------------------------------------------
    localparam integer K = 402;
    localparam integer L = 24;
    
    // --------------------------------------------------------
    // 4. Verification Logic (The "Golden Model")
    // --------------------------------------------------------
    // We simulate the exact same math here to compare against the hardware.
    reg [39:0] expected_accumulator;
    wire [15:0] expected_q_out;

    assign expected_q_out = expected_accumulator[39:24];

    always @(posedge clk) begin
        if (rst) begin
            expected_accumulator = 0;
        end else begin
            // Behavioral description of what the hardware should do
            expected_accumulator = expected_accumulator + (f * K);
        end
    end

    // --------------------------------------------------------
    // 5. Clock Generation (100 MHz)
    // --------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle every 5ns
    end

    // --------------------------------------------------------
    // 6. Test Stimulus
    // --------------------------------------------------------
    initial begin
        // --- Initialization ---
        rst = 1;
        f = 0;
        $display("-------------------------------------------------------------");
        $display("Time (ns) | Input f | Real Output | Exp Output | Status");
        $display("-------------------------------------------------------------");

        // --- Release Reset ---
        #20;
        rst = 0;
        
        // ==========================================================
        // TEST CASE 1: Low Bound (f = 435)
        // ==========================================================
        // Calc: 435 * 402 = 174,870 added per cycle.
        // It takes ~96 cycles for the top 16 bits to change by 1.
        // ==========================================================
        @(posedge clk);
        f = 13'd435;
        $display("\n[TEST START] Testing Low Bound: f = 435");
        
        // Wait 200 cycles to watch it accumulate slowly
        repeat (200) begin
            @(posedge clk); 
            // Optional: Uncomment to see every cycle
            // $display("%t | %d | %d | %d", $time, f, q_out, expected_q_out);
        end
        check_result();

        // ==========================================================
        // TEST CASE 2: High Bound (f = 7000)
        // ==========================================================
        // Calc: 7000 * 402 = 2,814,000 added per cycle.
        // The output should increment much faster (approx every 6 cycles).
        // ==========================================================
        @(posedge clk);
        f = 13'd7000;
        $display("\n[TEST START] Testing High Bound: f = 7000");

        repeat (50) begin
            @(posedge clk);
        end
        check_result();

        // ==========================================================
        // TEST CASE 3: Mid-Range Sweep
        // Change f dynamically to see if accumulator adapts
        // ==========================================================
        $display("\n[TEST START] Dynamic Sweep (435 -> 7000)");
        
        f = 13'd2000;
        repeat(20) @(posedge clk);
        check_result();

        f = 13'd4000;
        repeat(20) @(posedge clk);
        check_result();

        f = 13'd6000;
        repeat(20) @(posedge clk);
        check_result();

        // End Simulation
        $display("\n-------------------------------------------------------------");
        $display("SIMULATION COMPLETE");
        $finish;
    end

    // --------------------------------------------------------
    // Task: Compare Hardware vs Expected
    // --------------------------------------------------------
    task check_result;
        begin
            // Allow a tiny delta for simulation update ordering
            #1; 
            if (q_out === expected_q_out) begin
                $display("%t | %5d   |    %5d    |    %5d     | PASS", 
                         $time, f, q_out, expected_q_out);
            end else begin
                $display("%t | %5d   |    %5d    |    %5d     | FAIL !!!", 
                         $time, f, q_out, expected_q_out);
            end
        end
    endtask

endmodule