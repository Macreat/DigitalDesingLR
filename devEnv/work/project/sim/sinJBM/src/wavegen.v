`timescale 1ns / 1ps
// ==========================================================
// Sine wave generator (Verilog-2012 compatible)
// ==========================================================
module sine_wave_gen (
    input  wire        clk,
    input  wire [15:0] angle,
    input  wire        en,
    output reg  signed [15:0] wave,
    output reg         ready
);

    // ------------------------------------------------------
    // LUT: quarter-wave, 16 entries
    // ------------------------------------------------------
    reg signed [15:0] LUT [0:15];

    initial begin
        $readmemh("./src/SINE_LUT.hex", LUT);
    end

    // ------------------------------------------------------
    // Quadrant logic
    // ------------------------------------------------------
    wire signed [15:0] index;
    wire               sign;

    assign index = {2'b00, (angle[14] ? ~angle[13:0] : angle[13:0])};
    assign sign  = angle[15];

    // ------------------------------------------------------
    // Range detection
    // ------------------------------------------------------
    wire [15:0] comp;
    wire [15:0] range;

    assign comp[0]  = index < 1024;
    assign comp[1]  = index < 2048;
    assign comp[2]  = index < 3072;
    assign comp[3]  = index < 4096;
    assign comp[4]  = index < 5120;
    assign comp[5]  = index < 6144;
    assign comp[6]  = index < 7168;
    assign comp[7]  = index < 8192;
    assign comp[8]  = index < 9216;
    assign comp[9]  = index < 10240;
    assign comp[10] = index < 11264;
    assign comp[11] = index < 12288;
    assign comp[12] = index < 13312;
    assign comp[13] = index < 14336;
    assign comp[14] = index < 15360;
    assign comp[15] = index < 16384;

    assign range[0]  = comp[0];
    assign range[1]  = comp[1]  & ~comp[0];
    assign range[2]  = comp[2]  & ~comp[1];
    assign range[3]  = comp[3]  & ~comp[2];
    assign range[4]  = comp[4]  & ~comp[3];
    assign range[5]  = comp[5]  & ~comp[4];
    assign range[6]  = comp[6]  & ~comp[5];
    assign range[7]  = comp[7]  & ~comp[6];
    assign range[8]  = comp[8]  & ~comp[7];
    assign range[9]  = comp[9]  & ~comp[8];
    assign range[10] = comp[10] & ~comp[9];
    assign range[11] = comp[11] & ~comp[10];
    assign range[12] = comp[12] & ~comp[11];
    assign range[13] = comp[13] & ~comp[12];
    assign range[14] = comp[14] & ~comp[13];
    assign range[15] = comp[15] & ~comp[14];

    // ------------------------------------------------------
    // Interpolation
    // ------------------------------------------------------
    wire signed [15:0] TOP = sign ? -16'sd32767 : 16'sd32767;

    wire signed [15:0] s_LUT [0:15];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : LUT_SIGN
            assign s_LUT[i] = sign ? -LUT[i] : LUT[i];
        end
    endgenerate

    wire signed [31:0] interm [0:15];

    assign interm[0]  = (index * s_LUT[1]) >>> 10;
    assign interm[1]  = ((index-1024)  * s_LUT[2]  + (2048-index)  * s_LUT[1])  >>> 10;
    assign interm[2]  = ((index-2048)  * s_LUT[3]  + (3072-index)  * s_LUT[2])  >>> 10;
    assign interm[3]  = ((index-3072)  * s_LUT[4]  + (4096-index)  * s_LUT[3])  >>> 10;
    assign interm[4]  = ((index-4096)  * s_LUT[5]  + (5120-index)  * s_LUT[4])  >>> 10;
    assign interm[5]  = ((index-5120)  * s_LUT[6]  + (6144-index)  * s_LUT[5])  >>> 10;
    assign interm[6]  = ((index-6144)  * s_LUT[7]  + (7168-index)  * s_LUT[6])  >>> 10;
    assign interm[7]  = ((index-7168)  * s_LUT[8]  + (8192-index)  * s_LUT[7])  >>> 10;
    assign interm[8]  = ((index-8192)  * s_LUT[9]  + (9216-index)  * s_LUT[8])  >>> 10;
    assign interm[9]  = ((index-9216)  * s_LUT[10] + (10240-index) * s_LUT[9])  >>> 10;
    assign interm[10] = ((index-10240) * s_LUT[11] + (11264-index) * s_LUT[10]) >>> 10;
    assign interm[11] = ((index-11264) * s_LUT[12] + (12288-index) * s_LUT[11]) >>> 10;
    assign interm[12] = ((index-12288) * s_LUT[13] + (13312-index) * s_LUT[12]) >>> 10;
    assign interm[13] = ((index-13312) * s_LUT[14] + (14336-index) * s_LUT[13]) >>> 10;
    assign interm[14] = ((index-14336) * s_LUT[15] + (15360-index) * s_LUT[14]) >>> 10;
    assign interm[15] = ((index-15360) * TOP       + (16384-index) * s_LUT[15]) >>> 10;

    // ------------------------------------------------------
    // Registered output
    // ------------------------------------------------------
    always @(posedge clk) begin
        if (en) begin
            case (range)
                16'h0001: wave <= interm[0];
                16'h0002: wave <= interm[1];
                16'h0004: wave <= interm[2];
                16'h0008: wave <= interm[3];
                16'h0010: wave <= interm[4];
                16'h0020: wave <= interm[5];
                16'h0040: wave <= interm[6];
                16'h0080: wave <= interm[7];
                16'h0100: wave <= interm[8];
                16'h0200: wave <= interm[9];
                16'h0400: wave <= interm[10];
                16'h0800: wave <= interm[11];
                16'h1000: wave <= interm[12];
                16'h2000: wave <= interm[13];
                16'h4000: wave <= interm[14];
                16'h8000: wave <= interm[15];
                default:  wave <= 16'sd0;
            endcase
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end

endmodule
