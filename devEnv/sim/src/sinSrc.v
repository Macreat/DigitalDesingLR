module sine_wave_ob #(
    parameter TABLE_BITS = 6,   // 2^6 = 64 samples
    parameter AMP_BITS   = 8    // 8 bits (0..255)
)(
    input  wire                   clk,
    input  wire                   rst,        // active high
    input  wire [TABLE_BITS-1:0]  step,       // NCO frequency control
    output reg  [AMP_BITS-1:0]    sine_out,   // offset-binary: 0..255
    output wire signed [23:0]     pcm_sample  // signed PCM -32768..+32767 (24b)
);
    localparam integer TABLE_SIZE = (1 << TABLE_BITS);

    // ROM: 64 samples, center 128 (offset-binary)
    reg [AMP_BITS-1:0] rom [0:TABLE_SIZE-1];

    // Phase accumulator (6 bits): index = phase
    reg [TABLE_BITS-1:0] index;

    integer i;
    real ang;
    initial begin
        // generate sine lookup table (simulation only)
        for (i = 0; i < TABLE_SIZE; i = i + 1) begin
            ang = 2.0 * 3.141592653589793 * i / TABLE_SIZE;
            // offset-binary: center 128, amplitude 127
            rom[i] = $rtoi(128.0 + 127.0 * $sin(ang));
        end
    end

    // NCO phase accumulator
    always @(posedge clk or posedge rst) begin
        if (rst)
            index <= {TABLE_BITS{1'b0}};
        else
            index <= index + step;
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst)
            sine_out <= 8'd128;
        else
            sine_out <= rom[index];
    end

    // ---- PCM pipeline: convert offset-binary -> signed 24-bit ----
    // 0..255 -> -32768..+32767 -> 24-bit signed
    assign pcm_sample = { {16{sine_out[7]}}, sine_out } - 24'd32768;

endmodule
