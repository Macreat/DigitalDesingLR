// Simple self-running sine generator (offset-binary + PCM)
module sine_wave_ob #(
    parameter TABLE_BITS = 16,   // 2^6 = 64 samples
    parameter AMP_BITS   = 8    // 8 bits (0..255)
)(
    input  wire                   clk,
    input  wire                   rst,        // active high
    output reg  [AMP_BITS-1:0]    sine_out,   // offset-binary: 0..255
    output wire signed [23:0]     pcm_sample  // signed PCM: -32768..+32767
);

    localparam integer TABLE_SIZE = (1 << TABLE_BITS);

    // ROM: 64 samples, center 128 (offset-binary)
    reg [AMP_BITS-1:0] rom [0:TABLE_SIZE-1];

    // Simple index counter
    reg [TABLE_BITS-1:0] idx;

    integer i;
    real ang;
    initial begin
        // Build the sine lookup table (simulation only) /
        // build the sine loop with another strategie (TABLE mapping)z
        for (i = 0; i < TABLE_SIZE; i = i + 1) begin
            ang = 2.0 * 3.141592653589793 * i / TABLE_SIZE;
            // offset-binary: center 128, amplitude 127
            rom[i] = $rtoi(128.0 + 127.0 * $sin(ang));
        end
    end

    // Counter (fixed increment of 1 each clock)
    always @(posedge clk or posedge rst) begin
        if (rst)
            idx <= {TABLE_BITS{1'b0}}; // instead of sum idx , i can divide or sample with a window, were 
            // most significant array are saved and continue with the iteration 
            // , we cant representate a lot of frequencies. ¿ So, how can i do with other strategies ?
        else
            idx <= idx + 1'b1;  // increment every cycle
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst)
            sine_out <= rom[idx];
        else
            sine_out <= rom[idx];
    end

    // PCM conversion (offset-binary -> signed 24-bit)
    assign pcm_sample = { {16{sine_out[7]}}, sine_out } - 24'd32768;

endmodule
