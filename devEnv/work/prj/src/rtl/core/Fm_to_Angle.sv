/**
 * @brief Accumulator module for Fm to Angle conversion, performing multiplication and accumulation with MSB output.
 * @author Santiago Bustamante Montoya, Juan Esteban Granada Cardona
 * @param clk Clock input
 * @param rst Reset input
 * @param f 9-bit input frequency value
 * @param q_out 16-bit MSB output from the accumulator
 */
module acumulador_msb (
    input  wire         clk,    // Reloj
    input  wire         rst,    // Reset
    input  wire [8:0]   f,      // Entrada f (9 bits)
    output wire [15:0]  q_out   // Salida (Solo los 16 bits más significativos)
);

    // --- Parámetros ---
    localparam integer K = 402;
    localparam integer L = 24;          // Bits "ocultos" o fraccionarios
    localparam integer OUT_WIDTH = 16;  // Bits de salida deseados
    
    // El ancho total del acumulador debe ser la suma de L + bits de salida
    // 24 + 16 = 40 bits en total.
    localparam ACC_WIDTH = L + OUT_WIDTH; 

    // --- Señales Internas ---
    reg  [ACC_WIDTH-1:0] acumulador;    // Registro de 40 bits
    wire [17:0]          producto;      // Resultado de f * k
    wire [ACC_WIDTH-1:0] next_value;    // Siguiente valor del acumulador

    // --- Lógica ---

    // 1. Multiplicación (f * k)
    // Máximo valor: 511 * 402 = 205,422 (cabe en 18 bits)
    assign producto = f * K;

    // 2. Sumador
    // Sumamos el producto al valor actual del acumulador.
    // El producto se suma alineado a la derecha (bits menos significativos).
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
    // Tomamos solo los 16 bits MÁS significativos (MSB).
    // Esto es matemáticamente equivalente a hacer (acumulador >> L)
    // y quedarse con la parte baja del resultado si el ancho coincidiera,
    // pero seleccionar los bits directamente es más eficiente y claro.
    assign q_out = acumulador[ACC_WIDTH-1 : L]; 
    // En este caso: acumulador[39 : 24]

endmodule