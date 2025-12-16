`timescale 1ns/1ps

module tb_mul_u8_s16_shifted;

    // DUT inputs
    reg  [7:0]     u8;
    reg  signed [15:0] s16;

    // DUT output
    wire signed [15:0] result;

    // Instantiate the DUT
    mul_u8_s16_shifted dut (
        .u8(u8),
        .s16(s16),
        .result(result)
    );
    // given s16 will range from -32768 to 32768 , and u8 from 0 to 100 
    integer i;

    initial begin
        $display("Starting testbench...");
        $display("u8,      s16,        result");

        // ----------------------------------------
        // Test with u8 = 0
        // ----------------------------------------
        u8 = 0;
        for (i = -32768; i < 32768; i = i + 1) begin
            s16 = i;
            #1;
            $display("%3d , %7d , %7d", u8, s16, result);
        end

        // ----------------------------------------
        // Test with u8 = 100
        // ----------------------------------------
        u8 = 100;
        for (i = -32768; i < 32768; i = i + 1) begin
            s16 = i;
            #1;
            $display("%3d , %7d , %7d", u8, s16, result);
        end

        $display("Testbench finished.");
        $stop;
    end

endmodule