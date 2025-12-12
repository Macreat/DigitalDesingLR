`timescale 1ns / 1ps

module tb_main_sine;

    // -------------------------------------------------------------
    // 1. Signal Declarations
    // -------------------------------------------------------------
    reg clk;
    reg rst;
    
    // Inputs to DUT
    reg [8:0]  Fm;
    reg [12:0] Fc;
    reg [7:0]  Beta;
    
    // Output from DUT
    wire signed [15:0] out;

    // -------------------------------------------------------------
    // 2. Instantiate the Device Under Test (DUT)
    // -------------------------------------------------------------
    main_sine uut (
        .clk(clk),
        .rst(rst),
        .Fm(Fm),
        .Fc(Fc),
        .Beta(Beta),
        .out(out)
    );

    // -------------------------------------------------------------
    // 3. Clock Generation (125 MHz)
    // -------------------------------------------------------------
    // Period = 8ns (1/125MHz = 8ns)
    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    // -------------------------------------------------------------
    // 4. Test Stimulus
    // -------------------------------------------------------------
    initial begin
        // Initialize Inputs
        rst = 1;
        Fm = 0;
        Fc = 0;
        Beta = 0;

        // --- Reset Phase ---
        $display("--- [0.0 ms] System Reset ---");
        #200;       // Hold reset
        rst = 0;    // Release reset
        #200;

        // -------------------------------------------------------------
        // TEST CASE 1: Minimum Values / Pure Sine Test
        // Fm = 8 Hz (Very slow modulation)
        // Fc = 435 Hz (Low Carrier)
        // Beta = 0 (No Modulation -> Output should be pure 435Hz sine)
        // -------------------------------------------------------------
        $display("--- [Time %t] Case 1: Min Values / Pure Carrier (Beta=0) ---", $time);
        Fm   = 9'd8;
        Fc   = 13'd435;
        Beta = 8'd0;
        
        // Wait for 3ms (enough to see ~1 full cycle of 435Hz)
        #3000000; 


        // -------------------------------------------------------------
        // TEST CASE 2: Mid-Range / Standard FM
        // Fm = 100 Hz
        // Fc = 1000 Hz
        // Beta = 50 (Moderate modulation)
        // -------------------------------------------------------------
        $display("--- [Time %t] Case 2: Mid-Range (Beta=50) ---", $time);
        Fm   = 9'd100;
        Fc   = 13'd1000;
        Beta = 8'd50;

        // Wait for 3ms
        #3000000;


        // -------------------------------------------------------------
        // TEST CASE 3: Peak/Stress Values
        // Fm = 435 Hz (Fast modulation)
        // Fc = 7000 Hz (High Carrier)
        // Beta = 100 (Heavy modulation -> Complex Waveform)
        // -------------------------------------------------------------
        $display("--- [Time %t] Case 3: Peak Values (Beta=100) ---", $time);
        Fm   = 9'd435;
        Fc   = 13'd7000;
        Beta = 8'd100;

        // Wait for 2ms (7000Hz is fast, we will see many cycles)
        #2000000;

        // -------------------------------------------------------------
        // TEST CASE 4: Dynamic Change (Testing Beta sweep)
        // Keep frequencies, drop Beta suddenly
        // -------------------------------------------------------------
        $display("--- [Time %t] Case 4: Drop Beta to 10 ---", $time);
        Beta = 8'd10;
        
        #1000000;

        $display("--- Simulation Complete ---");
        $finish;
    end

    // -------------------------------------------------------------
    // Optional: Output Monitor
    // Prints the output value occasionally so you know it's alive
    // -------------------------------------------------------------
    reg [31:0] sample_counter = 0;
    always @(posedge clk) begin
        sample_counter <= sample_counter + 1;
        // Print every ~10,000 clocks (approx every 4-5 audio samples)
        if (sample_counter == 10000) begin
            sample_counter <= 0;
            // Only print if not in reset
            if (!rst) $display("Time: %t | Out: %d", $time, out);
        end
    end

endmodule