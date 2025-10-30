`timescale 1ns/1ps

module tb_sipo_reg;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg shift_en = 1'b0;
    reg bit_in = 1'b0;
    wire [7:0] data_out;
    reg [7:0] stimulus;
    reg [7:0] expected;
    integer i;

    sipo_reg #(.WIDTH(8)) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .shift_en (shift_en),
        .bit_in   (bit_in),
        .data_out (data_out)
    );

    always #5 clk = ~clk;

    task automatic apply_shift(input bit value);
        begin
            bit_in   <= value;
            shift_en <= 1'b1;
            @(posedge clk);
            shift_en <= 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n <= 1'b1;

        stimulus = 8'b1100_1011;
        expected = 8'd0;

        // Enviar MSB primero
        for (i = 7; i >= 0; i = i - 1) begin
            apply_shift(stimulus[i]);
            expected = {expected[6:0], stimulus[i]};
            if (data_out !== expected)
                $fatal(1, "Mismatch after shift %0d: expected %b got %b", i, expected, data_out);
        end

        if (data_out[3:0] !== stimulus[3:0])
            $fatal(1, "LS nibble should reflect last four inserted bits. expected %b got %b",
                   stimulus[3:0], data_out[3:0]);

        rst_n <= 1'b0;
        @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
        if (data_out !== 8'd0)
            $fatal(1, "Register did not clear on reset.");

        $display("tb_sipo_reg: PASS");
        $finish;
    end

`ifdef WAVES
    initial begin
        $dumpfile("results/tb_sipo_reg.vcd");
        $dumpvars(1, tb_sipo_reg);
    end
`endif



endmodule
