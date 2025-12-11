module beat_sequencer (
    input  wire        clk,         // 2^16 = 65536 Hz clock
    input  wire        rst,         // synchronous reset

    // 8-bit inputs.
    // Expected values: 8'd0 or 8'd127 (0x7F)
    // Since this is unsigned, 127 is simply a positive integer.
    input  wire [7:0] tone0_in,
    input  wire [7:0] tone1_in,
    input  wire [7:0] tone2_in,
    input  wire [7:0] tone3_in,

    output reg  [7:0] tone_out      // current tone output
);

    // ----------------------------------------
    // Store tones
    // ----------------------------------------
    reg [7:0] tone_mem [0:3];

    always @(posedge clk) begin
        if (rst) begin
            tone_mem[0] <= 8'd0;
            tone_mem[1] <= 8'd0;
            tone_mem[2] <= 8'd0;
            tone_mem[3] <= 8'd0;
        end else begin
            // Capture inputs
            // If the input is 127 (01111111), it is stored exactly as is.
            tone_mem[0] <= tone0_in;
            tone_mem[1] <= tone1_in;
            tone_mem[2] <= tone2_in;
            tone_mem[3] <= tone3_in;
        end
    end

    // ----------------------------------------
    // Clock divider for 8.533 Hz
    // ----------------------------------------
    localparam integer DIVIDER = 7680;   // 65536 Hz / 8.533 Hz
    reg [15:0] div_cnt = 0;

    // index of current tone (0 -> 1 -> 2 -> 3 -> 0...)
    reg [1:0] tone_index = 0;

    always @(posedge clk) begin
        if (rst) begin
            div_cnt    <= 0;
            tone_index <= 0;
        end else begin
            if (div_cnt == DIVIDER - 1) begin
                div_cnt <= 0;
                // Move to next tone
                tone_index <= tone_index + 2'd1;
            end else begin
                div_cnt <= div_cnt + 16'd1;
            end
        end
    end

    // ----------------------------------------
    // Tone output mux
    // ----------------------------------------
    always @(posedge clk) begin
        case(tone_index)
            2'd0: tone_out <= tone_mem[0];
            2'd1: tone_out <= tone_mem[1];
            2'd2: tone_out <= tone_mem[2];
            2'd3: tone_out <= tone_mem[3];
        endcase
    end

endmodule