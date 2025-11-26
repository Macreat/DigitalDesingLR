`timescale 1ns/1ps
module uart_tb;

    localparam CLK_FREQ = 50_000_000;
    localparam BAUD     = 115200;

    reg clk = 0;
    reg rstn = 0;

    reg tx_start = 0;
    reg [7:0] tx_byte = 0;
    wire tx_ready;
    wire tx_accept;
    wire line;

    wire rx_valid;
    wire [7:0] rx_byte;
    wire start_pulse;
    wire framing_error;

    assign line = tx;

    always #10 clk = ~clk;

    uart_tx #(.CLK_FREQ(CLK_FREQ)) TX (
        .clk(clk),
        .rstn(rstn),
        .tx_start(tx_start),
        .tx_byte(tx_byte),
        .tx_ready(tx_ready),
        .tx_accept(tx_accept),
        .tx(tx)
    );

    uart_rx #(.CLK_FREQ(CLK_FREQ)) RX (
        .clk(clk),
        .rstn(rstn),
        .rx(line),
        .rx_valid(rx_valid),
        .rx_byte(rx_byte),
        .start_pulse(start_pulse),
        .framing_error(framing_error)
    );

    task send(input [7:0] b);
        begin
            @(posedge clk);
            while (!tx_ready) @(posedge clk);
            tx_byte  = b;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;
        end
    endtask

    initial begin
        $dumpfile("buildTemp/gtkWaveVCDFiles/uart_tb.vcd");
        $dumpvars(0, uart_tb);

        #100 rstn = 1;

        send(8'h41);
        send(8'h30);
        send(8'h7A);

        #300_000;
        $finish;
    end
endmodule
