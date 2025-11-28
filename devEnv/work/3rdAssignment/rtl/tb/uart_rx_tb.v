`timescale 1ns/1ps
module uart_rx_tb;

    localparam CLK_FREQ = 50_000_000;
    localparam BAUD     = 115200;
    localparam BIT_TIME = 1_000_000_000 / BAUD; // ns per bit = 8680 ns approx

    reg clk = 0;
    reg rstn = 0;
    reg rx = 1;                // idle high

    wire rx_valid;
    wire [7:0] rx_byte;
    wire start_pulse;
    wire framing_error;

    // Clock 50 MHz
    always #10 clk = ~clk;

    uart_rx #(.CLK_FREQ(CLK_FREQ)) DUT (
        .clk(clk),
        .rstn(rstn),
        .rx(rx),
        .rx_valid(rx_valid),
        .rx_byte(rx_byte),
        .start_pulse(start_pulse),
        .framing_error(framing_error)
    );

    // UART byte sender (LSB-first)
    task send_uart_byte(input [7:0] b);
        integer i;
        begin
            rx <= 0; #(BIT_TIME);         // start bit
            for (i = 0; i < 8; i = i+1)
                begin rx <= b[i]; #(BIT_TIME); end
            rx <= 1; #(BIT_TIME);         // stop bit
        end
    endtask

    initial begin
        $dumpfile("buildTemp/gtkWaveVCDFiles/uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);

        #100 rstn = 1;

        // Send 'A' (0x41)
        send_uart_byte(8'h41);
        #200_000;

        // Send 'z' (0x7A)
        send_uart_byte(8'h7A);
        #200_000;

        $finish;
    end
endmodule
