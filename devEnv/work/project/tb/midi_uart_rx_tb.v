`timescale 1ns / 1ps
//=============================================================================
// File         : midi_uart_rx_tb.v
// Author       : Mateo Almeida
// Description  :
//   Testbench for the midi_uart_rx module. This testbench verifies correct
//   reception of MIDI UART data at the standard MIDI baud rate (31.25 kbaud).
//
//   The testbench:
//     - Generates a system clock
//     - Applies a reset sequence
//     - Simulates UART serial input on the rx line
//     - Sends example MIDI bytes (Note On and Control Change)
//     - Dumps waveform data for offline analysis
//
//   The UART framing follows standard 8-N-1 format:
//     - 1 start bit (0)
//     - 8 data bits (LSB first)
//     - 1 stop bit (1)
//
//   Waveform output is written to:
//     sim/build/midi_uart_rx_tb.vcd
//
//=============================================================================

module midi_uart_rx_tb;

    //-------------------------------------------------------------------------
    // Testbench parameters
    //-------------------------------------------------------------------------
    localparam integer CLK_FREQ_HZ = 10_000_000; // 10 MHz system clock
    localparam integer BAUD_RATE   = 31_250;     // Standard MIDI baud rate
    localparam integer CLK_PERIOD  = 100;        // Clock period in ns (10 MHz)
    localparam integer BIT_PERIOD  = 32_000;     // UART bit period in ns

    //-------------------------------------------------------------------------
    // Testbench signals
    //-------------------------------------------------------------------------
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg rx  = 1'b1; // UART idle state is logic high

    wire [7:0] data_out;
    wire       data_valid;
    wire       busy;
    wire       framing_error;

    //-------------------------------------------------------------------------
    // Clock generation
    //-------------------------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------------------------------
    // Device Under Test (DUT)
    //-------------------------------------------------------------------------
    midi_uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE  (BAUD_RATE)
    ) dut (
        .clk           (clk),
        .rst           (rst),
        .rx            (rx),
        .data_out      (data_out),
        .data_valid    (data_valid),
        .busy          (busy),
        .framing_error (framing_error)
    );

    //-------------------------------------------------------------------------
    // Waveform dump configuration
    //-------------------------------------------------------------------------
    initial begin
        // Dumpfile stored in sim/build directory for easy access
        $dumpfile("sim/build/midi_uart_rx_tb.vcd");
        $dumpvars(0, midi_uart_rx_tb);
    end

    //-------------------------------------------------------------------------
    // Task: send_byte
    // Description:
    //   Sends one UART-formatted byte on the rx line using:
    //     - 1 start bit
    //     - 8 data bits (LSB first)
    //     - 1 stop bit
    //-------------------------------------------------------------------------
    task send_byte(input [7:0] value);
        integer i;
        begin
            // Start bit
            rx <= 1'b0;
            #(BIT_PERIOD);

            // Data bits
            for (i = 0; i < 8; i = i + 1) begin
                rx <= value[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            rx <= 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    //-------------------------------------------------------------------------
    // Test sequence
    //-------------------------------------------------------------------------
    initial begin
        // Initial reset period
        #(10*CLK_PERIOD);
        rst <= 1'b0;
        #(10*CLK_PERIOD);

        // Send MIDI Note On message
        send_byte(8'h90); // Note On, channel 0
        send_byte(8'd64); // Velocity
        #(BIT_PERIOD*5);

        // Send MIDI Control Change message
        send_byte(8'hB0); // Control Change, channel 0
        send_byte(8'd100);
        #(BIT_PERIOD*20);

        // End simulation
        $finish;
    end

endmodule
