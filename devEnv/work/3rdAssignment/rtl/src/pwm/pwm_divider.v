// pwm_divider.v
// Extended from the initial skeleton: divider logic, limit computation,
// counter, and one-cycle tick generation were added.
// Output base freq: 50 kHz / (2^pow2 * 5^pow5) from 50 MHz.

module pwm_divider #(
    parameter CLK_FREQ = 50_000_000  // present in skeleton but unused there
)(
    input  wire clk,
    input  wire rstn,
    input  wire [1:0] pow2,   // new: 2^pow2 factor
    input  wire [1:0] pow5,   // new: 5^pow5 factor
    output reg  tick          // new: one-cycle pulse output
);

    // Added: base divider for 50 kHz from 50 MHz (50e6 / 1000 = 50 kHz)
    localparam integer BASE_DIV = 1000;

    // Added registers: counter and dynamic limit
    reg [31:0] counter;
    reg [31:0] limit;

    // Added function: maps pow5 to the proper 5^pow5 value
    function [31:0] pow5_factor(input [1:0] p5);
        case (p5)
            2'd0: pow5_factor = 1;    // 5^0
            2'd1: pow5_factor = 5;    // 5^1
            2'd2: pow5_factor = 25;   // 5^2
            default: pow5_factor = 125; // 5^3
        endcase
    endfunction

    // Added: combinational computation of final division limit
    always @(*) begin
        limit = (BASE_DIV << pow2);        // multiply by 2^pow2
        limit = limit * pow5_factor(pow5); // multiply by 5^pow5
    end

    // Added: sequential logic with counter and tick pulse generation
    always @(posedge clk) begin
        if (!rstn) begin
            counter <= 0;
            tick <= 1'b0;
        end else begin
            if (counter == limit - 1) begin
                counter <= 0;
                tick <= 1'b1;  // one-cycle pulse
            end else begin
                counter <= counter + 1;
                tick <= 1'b0;
            end
        end
    end

endmodule
