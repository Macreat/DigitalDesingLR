module acumulador_msb_Fc (
    input  wire         clk,    // Reloj
    input  wire         rst,    // Reset
    input  wire [12:0]  f,      // UPDATED: Entrada f (13 bits)
    output wire [15:0]  q_out   // Salida (16 bits MSB)
);

    // --- Parámetros ---
    localparam integer K = 402;
    localparam integer L = 24;          // Bits "ocultos" o fraccionarios
    localparam integer OUT_WIDTH = 16;  // Bits de salida deseados
    
    // Ancho total del acumulador (40 bits)
    localparam ACC_WIDTH = L + OUT_WIDTH; 

    // --- Señales Internas ---
    reg  [ACC_WIDTH-1:0] acumulador;
    
    // UPDATED: El wire del producto debe ser más ancho.
    // Max f (13 bits) * Max K (9 bits) = ~22 bits necesarios.
    // 8191 * 402 = 3,292,782 (Hex: 323FEE), que requiere 22 bits.
    wire [21:0]          producto;      
    
    wire [ACC_WIDTH-1:0] next_value;

    // --- Lógica ---

    // 1. Multiplicación (f * k)
    assign producto = f * K;

    // 2. Sumador
    // Sumamos el producto (22 bits) al acumulador (40 bits).
    // Verilog rellena automáticamente con ceros a la izquierda.
    assign next_value = acumulador + producto;

    // 3. Flip-Flop (Registro)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acumulador <= 0;
        end else begin
            acumulador <= next_value;
        end
    end

    // 4. Salida del Sistema
    // Tomamos los 16 bits superiores: [39:24]
    assign q_out = acumulador[ACC_WIDTH-1 : L]; 

endmodule