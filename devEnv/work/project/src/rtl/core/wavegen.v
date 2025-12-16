

// Output frequency can be adjusted using the frequency of the input clock.
/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNUSEDPARAM */
module sine_wave_gen(input bit clk,
                       input bit unsigned [15:0] angle,
                       input bit en,
                       output bit signed [15:0] wave,
                       output bit ready);

  // LUT. One quarter wave, 16 positions, signed 16 bit each.
  bit signed [15:0] LUT[16];
  initial
  begin
    $readmemh("./src/SINE_LUT.hex", LUT);
  end
  // Index LUT. Holds only one quarter of a cycle.
  bit signed [15:0] index;
  bit sign;

  // Quarter detection; direction selection and
  assign index = {2'b0, (angle[14] == 1'b1) ? ~(angle[13:0]) : angle[13:0]};
  assign sign = angle[15];

  // Comparison arrays. Use range.
  bit [15:0] comp;
  bit [15:0] range;
  assign comp[0] = {2'b0,index[13:0]}<1024;
  assign comp[1] = {2'b0,index[13:0]}<2048;
  assign comp[2] = {2'b0,index[13:0]}<3072;
  assign comp[3] = {2'b0,index[13:0]}<4096;
  assign comp[4] = {2'b0,index[13:0]}<5120;
  assign comp[5] = {2'b0,index[13:0]}<6144;
  assign comp[6] = {2'b0,index[13:0]}<7168;
  assign comp[7] = {2'b0,index[13:0]}<8192;
  assign comp[8] = {2'b0,index[13:0]}<9216;
  assign comp[9] = {2'b0,index[13:0]}<10240;
  assign comp[10] = {2'b0,index[13:0]}<11264;
  assign comp[11] = {2'b0,index[13:0]}<12288;
  assign comp[12] = {2'b0,index[13:0]}<13312;
  assign comp[13] = {2'b0,index[13:0]}<14336;
  assign comp[14] = {2'b0,index[13:0]}<15360;
  assign comp[15] = {2'b0,index[13:0]}<16384;
  assign range[0] = comp[0];
  assign range[1] = comp[1] & ~comp[0];
  assign range[2] = comp[2] & ~comp[1];
  assign range[3] = comp[3] & ~comp[2];
  assign range[4] = comp[4] & ~comp[3];
  assign range[5] = comp[5] & ~comp[4];
  assign range[6] = comp[6] & ~comp[5];
  assign range[7] = comp[7] & ~comp[6];
  assign range[8] = comp[8] & ~comp[7];
  assign range[9] = comp[9] & ~comp[8];
  assign range[10] = comp[10] & ~comp[9];
  assign range[11] = comp[11] & ~comp[10];
  assign range[12] = comp[12] & ~comp[11];
  assign range[13] = comp[13] & ~comp[12];
  assign range[14] = comp[14] & ~comp[13];
  assign range[15] = comp[15] & ~comp[14];

  // OUTPUT CALCULATION.
  bit signed [15:0] interm[15:0];
  bit signed [15:0] s_LUT[15:0];
  bit signed [15:0] TOP = (sign == 1'b1) ? -32767: 32767;
  // Quarted-adjusted version of the LUT information.
  assign s_LUT[0] = LUT[0];
  assign s_LUT[1] = (sign == 1'b1) ? -LUT[1] : LUT[1];
  assign s_LUT[2] = (sign == 1'b1) ? -LUT[2] : LUT[2];
  assign s_LUT[3] = (sign == 1'b1) ? -LUT[3] : LUT[3];
  assign s_LUT[4] = (sign == 1'b1) ? -LUT[4] : LUT[4];
  assign s_LUT[5] = (sign == 1'b1) ? -LUT[5] : LUT[5];
  assign s_LUT[6] = (sign == 1'b1) ? -LUT[6] : LUT[6];
  assign s_LUT[7] = (sign == 1'b1) ? -LUT[7] : LUT[7];
  assign s_LUT[8] = (sign == 1'b1) ? -LUT[8] : LUT[8];
  assign s_LUT[9] = (sign == 1'b1) ? -LUT[9] : LUT[9];
  assign s_LUT[10] = (sign == 1'b1) ? -LUT[10] : LUT[10];
  assign s_LUT[11] = (sign == 1'b1) ? -LUT[11] : LUT[11];
  assign s_LUT[12] = (sign == 1'b1) ? -LUT[12] : LUT[12];
  assign s_LUT[13] = (sign == 1'b1) ? -LUT[13] : LUT[13];
  assign s_LUT[14] = (sign == 1'b1) ? -LUT[14] : LUT[14];
  assign s_LUT[15] = (sign == 1'b1) ? -LUT[15] : LUT[15];
  // Index-based interpolation.
  assign interm[0] = 16'((32'(index*s_LUT[1]))>>>10);
  assign interm[1] = ((index-1024)*s_LUT[2] + (2048-index)*s_LUT[1])>>>10;
  assign interm[2] = ((index-2048)*s_LUT[3] + (3072-index)*s_LUT[2])>>>10;
  assign interm[3] = ((index-3072)*s_LUT[4] + (4096-index)*s_LUT[3])>>>10;
  assign interm[4] = ((index-4096)*s_LUT[5] + (5120-index)*s_LUT[4])>>>10;
  assign interm[5] = ((index-5120)*s_LUT[6] + (6144-index)*s_LUT[5])>>>10;
  assign interm[6] = ((index-6144)*s_LUT[7] + (7168-index)*s_LUT[6])>>>10;
  assign interm[7] = ((index-7168)*s_LUT[8] + (8192-index)*s_LUT[7])>>>10;
  assign interm[8] = ((index-8192)*s_LUT[9] + (9216-index)*s_LUT[8])>>>10;
  assign interm[9] = ((index-9216)*s_LUT[10] + (10240-index)*s_LUT[9])>>>10;
  assign interm[10] = ((index-10240)*s_LUT[11] + (11264-index)*s_LUT[10])>>>10;
  assign interm[11] = ((index-11264)*s_LUT[12] + (12288-index)*s_LUT[11])>>>10;
  assign interm[12] = ((index-12288)*s_LUT[13] + (13312-index)*s_LUT[12])>>>10;
  assign interm[13] = ((index-13312)*s_LUT[14] + (14336-index)*s_LUT[13])>>>10;
  assign interm[14] = ((index-14336)*s_LUT[15] + (15360-index)*s_LUT[14])>>>10;
  assign interm[15] = ((index-15360)*TOP + (16384-index)*s_LUT[15])>>>10;

  // It is necessary to generate the output signal in a clocked process, in
  // order to avoid race conditions. The output signal is selected based on
  // the range in which the index falls.
  always @ (posedge clk)
  begin
    if (en)
    begin
      case(range)
        16'h0001:
          wave <= interm[0];
        16'h0002:
          wave <= interm[1];
        16'h0004:
          wave <= interm[2];
        16'h0008:
          wave <= interm[3];
        16'h0010:
          wave <= interm[4];
        16'h0020:
          wave <= interm[5];
        16'h0040:
          wave <= interm[6];
        16'h0080:
          wave <= interm[7];
        16'h0100:
          wave <= interm[8];
        16'h0200:
          wave <= interm[9];
        16'h0400:
          wave <= interm[10];
        16'h0800:
          wave <= interm[11];
        16'h1000:
          wave <= interm[12];
        16'h2000:
          wave <= interm[13];
        16'h4000:
          wave <= interm[14];
        16'h8000:
          wave <= interm[15];
        default:
          wave <= 16'b0;
      endcase
      ready <= 1'b1;
    end
    else
    begin
      ready <= 1'b0;
    end
  end

endmodule
