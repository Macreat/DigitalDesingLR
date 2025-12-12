`timescale 1ns/1ps
// ---------------------------------------------------------
// register_bank.v
// Banco de 9 registros de 7 bits para almacenar parámetros.
// Cuando packet_ready=1, almacena value en la posición index.
// ---------------------------------------------------------

module register_bank(
    input  wire clk,
    input  wire rstn,
    input  wire packet_ready,        // Señal que indica que llegó un paquete válido
    input  wire [3:0] index,         // Índice del registro a escribir (0-8)
    input  wire [6:0] value,         // Valor a almacenar
    output reg [6:0] R [0:8]         // Banco de registros
);

    integer i;

    always @(posedge clk) begin
        if (!rstn) begin
            // RESET: todos los registros se ponen en cero
            for (i = 0; i < 9; i = i + 1)
                R[i] <= 0;
        end
        else if (packet_ready) begin
            // Escritura del registro indicado
            R[index] <= value;
        end
    end

endmodule
