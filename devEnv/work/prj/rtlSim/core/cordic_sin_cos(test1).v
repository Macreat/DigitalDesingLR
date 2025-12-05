//
// CORDIC Sine/Cosine Generator (Pipelined)
//
module cordic_sin_cos #(
    parameter DATA_WIDTH = 16,
    parameter ITERATIONS = 16
)(
    input                            clk,
    input                            reset,
    input      signed [DATA_WIDTH-1:0] i_phase,   // Input phase in radians (Q2.14 format)
    output     signed [DATA_WIDTH-1:0] o_sin,
    output     signed [DATA_WIDTH-1:0] o_cos
);

    // CORDIC operates on angles from -pi/2 to +pi/2. For a full circle,
    // range reduction logic would be needed. This example assumes input is in range.

    // Table of pre-calculated arctan(2^-i) values in Q2.14 format
    // angle = round(atan(2**-i) * (2**14))
    reg signed [DATA_WIDTH-1:0] atan_lut [0:ITERATIONS-1];

    initial begin
        atan_lut[0]  = 16'd12868; // atan(2^0)  * 2^14
        atan_lut[1]  = 16'd7596;  // atan(2^-1) * 2^14
        atan_lut[2]  = 16'd4011;  // atan(2^-2) * 2^14
        atan_lut[3]  = 16'd2037;  // atan(2^-3) * 2^14
        atan_lut[4]  = 16'd1022;  // atan(2^-4) * 2^14
        atan_lut[5]  = 16'd511;   // atan(2^-5) * 2^14
        atan_lut[6]  = 16'd256;   // atan(2^-6) * 2^14
        atan_lut[7]  = 16'd128;   // atan(2^-7) * 2^14
        atan_lut[8]  = 16'd64;    // atan(2^-8) * 2^14
        atan_lut[9]  = 16'd32;    // atan(2^-9) * 2^14
        atan_lut[10] = 16'd16;    // atan(2^-10)* 2^14
        atan_lut[11] = 16'd8;     // atan(2^-11)* 2^14
        atan_lut[12] = 16'd4;     // atan(2^-12)* 2^14
        atan_lut[13] = 16'd2;     // atan(2^-13)* 2^14
        atan_lut[14] = 16'd1;     // atan(2^-14)* 2^14
        atan_lut[15] = 16'd0;     // atan(2^-15)* 2^14
    end

    // Pipeline registers for x, y (coordinates) and z (phase accumulator)
    reg signed [DATA_WIDTH-1:0] x_pipe [0:ITERATIONS];
    reg signed [DATA_WIDTH-1:0] y_pipe [0:ITERATIONS];
    reg signed [DATA_WIDTH-1:0] z_pipe [0:ITERATIONS];

    // Initial value of X is 1/K, where K is the CORDIC gain (~1.647)
    // 1/K ~= 0.60725. In Q2.14, this is round(0.60725 * 2**14) = 9950
    localparam CORDIC_GAIN_INV = 16'd9950;

    // First stage of the pipeline
    always @(posedge clk) begin
        if (reset) begin
            x_pipe[0] <= 0;
            y_pipe[0] <= 0;
            z_pipe[0] <= 0;
        end else begin
            x_pipe[0] <= CORDIC_GAIN_INV;
            y_pipe[0] <= 0;
            z_pipe[0] <= i_phase;
        end
    end

    // Generate the rest of the pipeline stages
    genvar i;
    generate
        for (i = 0; i < ITERATIONS; i = i + 1) begin : cordic_stages
            
            wire signed [DATA_WIDTH-1:0] x_shifted = $signed(x_pipe[i]) >>> i;
            wire signed [DATA_WIDTH-1:0] y_shifted = $signed(y_pipe[i]) >>> i;
            wire                          direction = z_pipe[i][DATA_WIDTH-1]; // MSB is the sign bit

            always @(posedge clk) begin
                if (reset) begin
                    x_pipe[i+1] <= 0;
                    y_pipe[i+1] <= 0;
                    z_pipe[i+1] <= 0;
                end else begin
                    if (direction) begin // If z is negative, rotate counter-clockwise
                        x_pipe[i+1] <= x_pipe[i] + y_shifted;
                        y_pipe[i+1] <= y_pipe[i] - x_shifted;
                        z_pipe[i+1] <= z_pipe[i] + atan_lut[i];
                    end else begin      // If z is positive, rotate clockwise
                        x_pipe[i+1] <= x_pipe[i] - y_shifted;
                        y_pipe[i+1] <= y_pipe[i] + x_shifted;
                        z_pipe[i+1] <= z_pipe[i] - atan_lut[i];
                    end
                end
            end
        end
    endgenerate

    // Assign final outputs from the end of the pipeline
    assign o_cos = x_pipe[ITERATIONS];
    assign o_sin = y_pipe[ITERATIONS];

endmodule