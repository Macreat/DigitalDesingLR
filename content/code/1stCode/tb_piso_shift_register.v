`timescale 1ns/1ps

module tb_piso_shift_register;

    reg clk;
    reg clk_inh;
    reg ser;
    reg sh_ld_n;
    reg [7:0] parallel_in;
    wire qh;
    wire [7:0] q;

    // Instantiate DUT
    piso_shift_register dut (
        .clk(clk),
        .clk_inh(clk_inh),
        .ser(ser),
        .sh_ld_n(sh_ld_n),
        .parallel_in(parallel_in),
        .qh(qh),
        .q(q)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock period = 10ns
    end

    initial begin
        $display("=== Parallel-In Serial-Out Shift Register Test ===");

        // Initialize
        clk_inh = 0;
        ser = 0;
        sh_ld_n = 1;
        parallel_in = 8'b00000000;

        // 1) Parallel load
        #2 sh_ld_n = 0;
        parallel_in = 8'b10110110;
        #2 sh_ld_n = 1;  // release load
        $display("Loaded value = %b", q);

        // 2) Shift 8 cycles
        repeat (8) @(posedge clk);
        $display("After shifting = %b", q);

        // 3) Clock inhibit test
        clk_inh = 1;
        ser = 1;
        @(posedge clk); // should not shift
        $display("With inhibit, reg = %b", q);

        // 4) Enable again, shift with serial input = 1
        clk_inh = 0;
        repeat (4) @(posedge clk);
        $display("After shifting in 1s, reg = %b", q);

        #20 $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t | SH/LD=%b | INH=%b | SER=%b | Q=%b | QH=%b",
                  $time, sh_ld_n, clk_inh, ser, q, qh);
    end

    // Waveform dump
    initial begin
        $dumpfile("waves.vcd");           
        $dumpvars(0, tb_piso_shift_register); 
    end

endmodule
