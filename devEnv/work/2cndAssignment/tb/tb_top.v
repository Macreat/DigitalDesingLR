`timescale 1ns/1ps
module tb_top;
  reg clk = 0;
  reg rst_n = 0;
  reg rx = 1;

  wire match, framing_error, frame_done, bit_strobe;
  wire [7:0] shift_window;

  top #(
    .CLK_FREQ_HZ(1_600_000),
    .BAUD_RATE(100_000),
    .ID_LAST_DIGIT(6)
  ) DUT (
    .clk(clk), .rst_n(rst_n), .rx(rx),
    .match(match), .framing_error(framing_error),
    .shift_window(shift_window),
    .frame_done(frame_done),
    .bit_strobe(bit_strobe)
  );

  always #312.5 clk = ~clk; // 1.6 MHz

  initial begin
    $dumpfile("results/tb_top.vcd");  
    $dumpvars(0, tb_top);
    rst_n = 0; #2000; rst_n = 1;

       //----------------------------------------------------------
    // CASO 1: Sin match
    // Byte 0xFF (11111111) no contiene "0110" → match = 0
    //----------------------------------------------------------
    send_uart_byte(8'b11111111);
    #200000; // esperar 200 µs

    //----------------------------------------------------------
    // CASO 2: Matches seguidos
    // 0x66 (01100110) contiene el patrón dos veces seguidas
    // Se esperan dos pulsos de match
    //----------------------------------------------------------
    send_uart_byte(8'b01100110);
    #200000; // separar un poco


    //----------------------------------------------------------
    // CASO 3: Match al inicio y otro al final
    // 0x66 produce match temprano
    // 0x60 (01100000) termina en "0110" también
    //----------------------------------------------------------
    send_uart_byte(8'b00000110);  // match al inicio
    send_uart_byte(8'b01100000);  // match al final
    #500000; // dejar tiempo al final

    $finish;
  end

  task send_uart_byte(input [7:0] data);
    integer i;
    begin
      rx = 0; #(10000); // start bit
      for (i = 0; i < 8; i = i + 1) begin
        rx = data[i]; #(10000);
      end
      rx = 1; #(10000); // stop bit
    end
  endtask
endmodule
