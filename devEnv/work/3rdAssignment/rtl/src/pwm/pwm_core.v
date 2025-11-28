// pwm_core.v
// Extended from skeleton: full PWM period computation, duty handling,
// centered-PWM arithmetic, and output generation were added.
// Output period = 50 kHz / (2^pow2 * 5^pow5) at 50 MHz.

module pwm_core #(
    parameter CLK_FREQ = 50_000_000
)(
    input  wire clk,
    input  wire rstn,
    input  wire [6:0] duty_percent_in, // new: external duty request
    input  wire [1:0] pow2,            // new: 2^pow2 period scaling
    input  wire [1:0] pow5,            // new: 5^pow5 period scaling
    output reg  pwm_out,               // new: PWM waveform output
    output reg [31:0] period_count     // updated: computed period in clk cycles
);

    // Base divider added earlier: 50e6 / 1000 = 50 kHz core frequency
    localparam integer BASE_DIV = 1000;

    // Added working registers: internal duty, counter, ON duration, center offset
    reg [6:0]  duty_percent;
    reg [31:0] count;
    reg [31:32] on_ticks;
    reg [31:0] start_offset;

    // Added: maps pow5 into correct multiplication factor (5^0..5^3)
    function [31:0] pow5_factor(input [1:0] p5);
        case (p5)
            2'd0: pow5_factor = 1;
            2'd1: pow5_factor = 5;
            2'd2: pow5_factor = 25;
            default: pow5_factor = 125;
        endcase
    endfunction

    // Added: duty capture with range limit (0–99 only)
    always @(posedge clk) begin
        if (!rstn) begin
            duty_percent <= 7'd0;
        end else if (duty_percent_in <= 7'd99) begin
            duty_percent <= duty_percent_in;  // ignore >99
        end
    end

    // Added: compute full PWM period and ON-time; center PWM around midpoint
    always @(*) begin
        period_count = (BASE_DIV << pow2) * pow5_factor(pow5); // full period
        on_ticks     = (period_count * duty_percent) / 100;    // ON duration
        start_offset = (period_count - on_ticks) >> 1;         // centering offset
    end

    // Added: counter and PWM generation (centered window)
    always @(posedge clk) begin
        if (!rstn) begin
            count   <= 0;
            pwm_out <= 1'b0;
        end else begin
            // period wrap
            if (count == period_count - 1) count <= 0;
            else count <= count + 1;

            // waveform generation
            if (on_ticks == 0) pwm_out <= 1'b0;    // duty = 0%
            else if (count >= start_offset && 
                     count < start_offset + on_ticks)
                     pwm_out <= 1'b1;              // inside ON window
            else pwm_out <= 1'b0;                 // OFF region
        end
    end

endmodule
