module mul_u8_s16_shifted (
    input      [7:0]     u8,        // unsigned
    input signed [15:0]  s16,       // signed
    output signed [15:0] result     // shifted, signed 16-bit
);

    // zero-extend the unsigned value to 16 bits
    wire [15:0] u8_ext = {8'b0, u8};

    // 16×8 = 24-bit signed product
    wire signed [23:0] product = $signed(s16) * $signed(u8_ext);

    // shift right by 16 (arithmetic shift is NOT used here)
    wire signed [23:0] shifted = product >>> 16;

    // take the lower 16 bits as signed result
    assign result = shifted[15:0];

endmodule