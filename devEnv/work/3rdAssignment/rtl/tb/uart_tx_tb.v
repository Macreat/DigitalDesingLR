`timescale 1ns/1ps
module uart_tx_tb;

    localparam CLK_FREQ = 50_000_000;
    localparam BAUD     = 115200;
    localparam BIT_TIME = 1_000_000_000 / BAUD;

    reg clk = 0;
    reg rstn = 0;
    reg tx_start = 0;
    reg [7:0] tx_byte = 0;

    wire tx_ready;
    wire tx_accept;
    wire tx;

    always #10 clk = ~clk;  // 50 MHz

    uart_tx #(.CLK_FREQ(CLK_FREQ)) DUT (
        .clk(clk),
        .rstn(rstn),
        .tx_start(tx_start),
        .tx_byte(tx_byte),
        .tx_ready(tx_ready),
        .tx_accept(tx_accept),
        .tx(tx)
    );

    task send_byte(input [7:0] b);
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
        $dumpfile("buildTemp/gtkWaveVCDFiles/uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        #100 rstn = 1;

        send_byte(8'h41);
        send_byte(8'h7A);

        #200_000;
        $finish;
    end
endmodule
