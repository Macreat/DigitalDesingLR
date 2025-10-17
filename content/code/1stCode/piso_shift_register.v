//=============================================
// 8-bit Parallel-In Serial-Out Shift Register
// Based on SN74LS165
//=============================================
module piso_shift_register (
    input wire clk,               // clock input
    input wire clk_inh,           // clock inhibit
    input wire ser,               // serial input
    input wire sh_ld_n,           // shift/load control (active low)
    input wire [7:0] parallel_in, // parallel input
    output wire qh,               // serial output (LSB)
    output wire [7:0] q           // internal register outputs
);

    reg [7:0] shift_reg;

    // Asynchronous parallel load
    always @(*) begin
        if (~sh_ld_n) begin
            shift_reg = parallel_in;   // immediate load
        end
    end

    // Shifting (on rising edge of CLK if enabled)
    always @(posedge clk) begin
        if (sh_ld_n && !clk_inh) begin
            shift_reg <= {ser, shift_reg[7:1]};
        end
    end

    // Outputs
    assign q = shift_reg;
    assign qh = shift_reg[0];  // LSB is serial output

endmodule
