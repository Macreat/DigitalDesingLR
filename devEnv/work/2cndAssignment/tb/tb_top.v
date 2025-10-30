`timescale 1ns/1ps
module tb_top;

  // Señales de estímulo
  reg clk = 0;
  reg rst_n = 0;
  reg rx = 1;

  // Señales de salida observadas
  wire match;
  wire framing_error;
  wire [7:0] shift_window;
  wire frame_done;
  wire bit_strobe;

  // Instanciación del DUT
  uart_pattern_top #(
    .CLK_FREQ_HZ(1_600_000),
    .BAUD_RATE(100_000),
    .ID_LAST_DIGIT(6)
  ) DUT (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .match(match),
    .framing_error(framing_error),
    .shift_window(shift_window),
    .frame_done(frame_done),
    .bit_strobe(bit_strobe)
  );

  // Generación de reloj de 1.6 MHz (periodo 625 ns)
  always #312.5 clk = ~clk;

  // Inicialización
  initial begin
    $dumpfile("results/tb_top.vcd");
    $dumpvars(0, tb_top);
    rst_n = 0; #2000;  // reset activo bajo
    rst_n = 1;

    // Enviar un byte UART que contenga el patrón 0110
//    send_uart_byte(8'b01100101);
    //
    send_uart_byte(8'b01100110); // LSB primero: 0 1 1 0 0 1 1 0
    #200000; // 200 µs de espera

    send_uart_byte(8'b01100110); // contiene 0110 → debe activar match
    send_uart_byte(8'b10101100); // contiene 1100 → no debe activar match
    #200000; // 200 µs de espera

    send_uart_byte(8'b01100110); // otra vez 0110 → otro match
    send_uart_byte(8'b11100110); // contiene 0110 dentro → match también
    #5000000; // esperar unos ciclos
    $finish;
  end

  // Task de envío de byte UART (1 start + 8 data + 1 stop)
  task send_uart_byte(input [7:0] data);
    integer i;
    begin
      rx = 0; #(10000); // start bit (1/100000 baud = 10 us)
      for (i = 0; i < 8; i = i + 1) begin
        rx = data[i];
        #(10000);
      end
      rx = 1; #(10000); // stop bit
    end
  endtask

  


endmodule
