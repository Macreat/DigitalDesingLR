`timescale 1ns/1ps
// ----------------------------------------------------------------------
// tb_top_input.v
// Testbench: envía 3 paquetes por UART y observa cómo se actualizan
// los registros y las salidas escaladas.
// ----------------------------------------------------------------------

module tb_top_input;

    localparam CLK_FREQ   = 10000000;        
    localparam BAUD_RATE  = 115200;
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE;
    localparam BYTE_TIME  = BIT_PERIOD * 10;

    reg clk = 0;
    reg rstn = 0;
    reg uart_rx = 1;

    wire [6:0] R0, R1, R2, R3, R4, R5, R6, R7, R8;
    wire [15:0] fm, fc, beta, decay, gain;
    wire [7:0] b1, b2, b3, b4;

    top_input DUT(
        .clk(clk),
        .rstn(rstn),
        .uart_rx(uart_rx),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4),
        .R5(R5), .R6(R6), .R7(R7), .R8(R8),
        .fm(fm), .fc(fc), .beta(beta),
        .decay(decay), .gain(gain),
        .b1(b1), .b2(b2), .b3(b3), .b4(b4)
    );

    always #50 clk = ~clk;  // 10 MHz -> periodo 100 ns

    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            uart_rx <= 0; #(BIT_PERIOD);

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx <= data[i];
                #(BIT_PERIOD);
            end

            uart_rx <= 1; #(BIT_PERIOD);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top_input);

        rstn = 0; #500;
        rstn = 1; #500;

        $display("Enviando paquete 1: index=3, value=77");
        send_uart_byte(8'd3);
        #(BYTE_TIME * 2);
        send_uart_byte(8'd77);
        #(BYTE_TIME * 3);

        $display("Enviando paquete 2: index=6, value=25");
        send_uart_byte(8'd6);
        #(BYTE_TIME * 2);
        send_uart_byte(8'd25);
        #(BYTE_TIME * 3);

        $display("Enviando paquete 3: index=8, value=120");
        send_uart_byte(8'd8);
        #(BYTE_TIME * 2);
        send_uart_byte(8'd120);
        #(BYTE_TIME * 3);

        $finish;
    end

endmodule
