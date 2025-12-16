`timescale 1ns/1ps
// ----------------------------------------------------------------------
// uart_packet_decoder.v
// Decodifica paquetes de 2 bytes provenientes del receptor UART.
//   Byte 1: índice  (0–8)
//   Byte 2: valor   (0–127)
// Valida los rangos y entrega index, value y packet_ready.
// ----------------------------------------------------------------------

module uart_packet_decoder(
    input  wire clk,
    input  wire rstn,
    input  wire rx_done,          // Byte recibido desde UART
    input  wire [7:0] rx_data,    // Contenido del byte recibido

    output reg [3:0] index,       // Índice decodificado
    output reg [6:0] value,       // Valor decodificado
    output reg packet_ready,      // Paquete válido listo
    output reg error              // Error por índices o valores inválidos
);

    reg waiting_second = 0;       // Estado interno: esperando 2do byte
    reg [7:0] first_byte;         // Guarda el primer byte (índice)

    always @(posedge clk) begin
        packet_ready <= 0;
        error <= 0;

        if (!rstn) begin
            waiting_second <= 0;
        end
        
        else if (rx_done) begin
            if (!waiting_second) begin
                // Primer byte recibido
                first_byte <= rx_data;
                waiting_second <= 1;
            end
            else begin
                // Segundo byte: procesar paquete
                waiting_second <= 0;

                // Validar índice (0–8)
                if (first_byte > 8) begin
                    error <= 1;
                end
                else begin
                    index <= first_byte[3:0];
                end

                // Validar valor (0–127)
                if (rx_data > 127) begin
                    error <= 1;
                end
                else begin
                    value <= rx_data[6:0];
                end

                // Si no hubo errores, marcar paquete listo
                packet_ready <= ~error;
            end
        end
    end

endmodule
