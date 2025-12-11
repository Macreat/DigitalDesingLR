// ==========================================================
// IMPLEMENTACIÓN (con índice y contador para cambio suave)
// ==========================================================
module sine_wave_ob #(
    parameter integer TABLE_BITS = 6,   // 1/4 de ciclo: 2^TABLE_BITS valores (p.ej. 64)
    parameter integer AMP_BITS   = 16,  // resolución de salida (con signo)
    parameter integer INDEX_BITS = 18   // Bits extra para resolución de frecuencia
)(
    input  wire                     clk,
    input  wire                     rst,                  // activo en alto
    input  wire [INDEX_BITS-1:0]    step,                 // incremento de fase (ahora más bits)
    output reg signed [AMP_BITS-1:0] sine_out              // -32768..32767, centro=0
);
    localparam integer QSIZE   = 1 << TABLE_BITS;         // tamaño del cuarto de ciclo
    localparam signed [AMP_BITS-1:0] CENTER = 0;          // centro con signo
    
    // Bits totales para el índice (incluyendo cuadrante y bits fraccionales)
    localparam integer TOTAL_INDEX_BITS = TABLE_BITS + 2 + INDEX_BITS;

    // ----------------------------------------------------
    // ROM: 1/4 de ciclo (0..90°), valores con signo
    // ----------------------------------------------------
    reg signed [AMP_BITS-1:0] quarter_rom [0:QSIZE-1];

    // Tabla precalculada (64 valores, 16 bits, con signo)
    integer k;
    initial begin
        quarter_rom[0]  = 16'sd0;
        quarter_rom[1]  = 16'sd817;
        quarter_rom[2]  = 16'sd1633;
        quarter_rom[3]  = 16'sd2449;
        quarter_rom[4]  = 16'sd3263;
        quarter_rom[5]  = 16'sd4074;
        quarter_rom[6]  = 16'sd4884;
        quarter_rom[7]  = 16'sd5690;
        quarter_rom[8]  = 16'sd6493;
        quarter_rom[9]  = 16'sd7291;
        quarter_rom[10] = 16'sd8085;
        quarter_rom[11] = 16'sd8875;
        quarter_rom[12] = 16'sd9658;
        quarter_rom[13] = 16'sd10436;
        quarter_rom[14] = 16'sd11207;
        quarter_rom[15] = 16'sd11971;
        quarter_rom[16] = 16'sd12728;
        quarter_rom[17] = 16'sd13477;
        quarter_rom[18] = 16'sd14217;
        quarter_rom[19] = 16'sd14949;
        quarter_rom[20] = 16'sd15671;
        quarter_rom[21] = 16'sd16384;
        quarter_rom[22] = 16'sd17086;
        quarter_rom[23] = 16'sd17778;
        quarter_rom[24] = 16'sd18458;
        quarter_rom[25] = 16'sd19128;
        quarter_rom[26] = 16'sd19785;
        quarter_rom[27] = 16'sd20430;
        quarter_rom[28] = 16'sd21062;
        quarter_rom[29] = 16'sd21681;
        quarter_rom[30] = 16'sd22287;
        quarter_rom[31] = 16'sd22879;
        quarter_rom[32] = 16'sd23457;
        quarter_rom[33] = 16'sd24020;
        quarter_rom[34] = 16'sd24568;
        quarter_rom[35] = 16'sd25101;
        quarter_rom[36] = 16'sd25618;
        quarter_rom[37] = 16'sd26120;
        quarter_rom[38] = 16'sd26605;
        quarter_rom[39] = 16'sd27073;
        quarter_rom[40] = 16'sd27525;
        quarter_rom[41] = 16'sd27960;
        quarter_rom[42] = 16'sd28377;
        quarter_rom[43] = 16'sd28777;
        quarter_rom[44] = 16'sd29158;
        quarter_rom[45] = 16'sd29522;
        quarter_rom[46] = 16'sd29867;
        quarter_rom[47] = 16'sd30194;
        quarter_rom[48] = 16'sd30502;
        quarter_rom[49] = 16'sd30791;
        quarter_rom[50] = 16'sd31061;
        quarter_rom[51] = 16'sd31311;
        quarter_rom[52] = 16'sd31542;
        quarter_rom[53] = 16'sd31754;
        quarter_rom[54] = 16'sd31945;
        quarter_rom[55] = 16'sd32117;
        quarter_rom[56] = 16'sd32269;
        quarter_rom[57] = 16'sd32401;
        quarter_rom[58] = 16'sd32513;
        quarter_rom[59] = 16'sd32604;
        quarter_rom[60] = 16'sd32675;
        quarter_rom[61] = 16'sd32726;
        quarter_rom[62] = 16'sd32757;
        quarter_rom[63] = 16'sd32767;
    end

    // -----------------------------------
    // Contador de fase extendido
    // -----------------------------------
    reg [TOTAL_INDEX_BITS-1:0] phase_index;

    always @(posedge clk or posedge rst) begin
        if (rst) 
            phase_index <= {TOTAL_INDEX_BITS{1'b0}};
        else     
            phase_index <= phase_index + step;
    end

    // ---------------------------
    // Simetrías por cuadrante
    // ---------------------------
    wire [1:0]              quad = phase_index[TOTAL_INDEX_BITS-1:TOTAL_INDEX_BITS-2];
    wire [TABLE_BITS-1:0]   idx  = phase_index[TOTAL_INDEX_BITS-3:TOTAL_INDEX_BITS-3-TABLE_BITS+1];

    wire                     reverse   = quad[0];
    wire [TABLE_BITS-1:0]    rom_addr  = reverse ? (QSIZE - 1'b1 - idx) : idx;

    wire signed [AMP_BITS-1:0] raw_value = quarter_rom[rom_addr];
    wire                     invert    = quad[1];
    wire signed [AMP_BITS-1:0] inv_value = -raw_value;
    wire signed [AMP_BITS-1:0] next_value = invert ? inv_value : raw_value;

    // Salida registrada
    always @(posedge clk or posedge rst) begin
        if (rst)   sine_out <= CENTER;
        else       sine_out <= next_value;
        end
endmodule
