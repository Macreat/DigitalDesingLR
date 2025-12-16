`timescale 1ns/1ps
// ----------------------------------------------------------------------
// uart_receiver.v
// Receptor UART 8N1 (start - 8 bits - stop).
// Convierte la señal serial uart_rx en bytes paralelos.
// ----------------------------------------------------------------------

module uart_receiver #(
    parameter CLK_FREQ = 10000000,     // Frecuencia del reloj principal
    parameter BAUD_RATE = 115200       // Baud rate UART
)(
    input  wire clk,
    input  wire rstn,
    input  wire uart_rx,
    output reg  rx_done,               // Señal: byte completo recibido
    output reg [7:0] rx_data           // Byte reconstruido
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer CTR_WIDTH = $clog2(CLKS_PER_BIT);

    reg [CTR_WIDTH-1:0] clk_cnt = 0;
    reg [3:0] bit_idx = 0;
    reg [7:0] rx_shift = 0;
    reg rx_busy = 0;

    // Doble muestreo para eliminar metastabilidad
    reg rx_d1 = 1, rx_d2 = 1;
    
    always @(posedge clk) begin
        rx_d1 <= uart_rx;
        rx_d2 <= rx_d1;
    end

    always @(posedge clk) begin
        if (!rstn) begin
            rx_busy <= 0;
            clk_cnt <= 0;
            bit_idx <= 0;
            rx_done <= 0;
            rx_data <= 0;
        end
        else begin
            rx_done <= 0;

            if (!rx_busy) begin
                // Detecta start bit
                if (rx_d2 == 0) begin
                    rx_busy <= 1;
                    clk_cnt <= CLKS_PER_BIT/2;
                    bit_idx <= 0;
                end
            end
            else begin
                // Contador del bit
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    clk_cnt <= 0;

                    if (bit_idx < 8) begin
                        rx_shift[bit_idx] <= rx_d2;
                        bit_idx <= bit_idx + 1;
                    end
                    
                    else if (bit_idx == 8) begin
                        // Stop bit
                        bit_idx <= 9;
                    end
                    
                    else begin
                        // Byte completo
                        rx_busy <= 0;
                        rx_data <= rx_shift;
                        rx_done <= 1;
                    end

                end
                else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
        end
    end

endmodule
