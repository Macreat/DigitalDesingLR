`timescale 1ns / 1ps

module midi_uart_rx_tb;
    localparam integer CLK_FREQ_HZ = 10_000_000;
    localparam integer BAUD_RATE   = 31_250;
    localparam integer CLK_PERIOD  = 100;      // 10 MHz
    localparam integer BIT_PERIOD  = 32_000;   // 31.25 kbaud

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg rx  = 1'b1;

    wire [7:0] data_out;
    wire       data_valid;
    wire       busy;
    wire       framing_error;

    always #(CLK_PERIOD/2) clk = ~clk;

    midi_uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE  (BAUD_RATE)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .rx           (rx),
        .data_out     (data_out),
        .data_valid   (data_valid),
        .busy         (busy),
        .framing_error(framing_error)
    );

    initial begin
        $dumpfile("sim/build/midi_uart_rx_tb.vcd");
        $dumpvars(0, midi_uart_rx_tb);
    end

    task send_byte(input [7:0] value);
        integer i;
        begin
            rx <= 1'b0;
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx <= value[i];
                #(BIT_PERIOD);
            end
            rx <= 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    initial begin
        #(10*CLK_PERIOD);
        rst <= 1'b0;
        #(10*CLK_PERIOD);

        send_byte(8'h90); // Note on
        send_byte(8'd64); // velocity
        #(BIT_PERIOD*5);

        send_byte(8'hB0); // knob change
        send_byte(8'd100);

        #(BIT_PERIOD*20);
        $finish;
    end
endmodule
