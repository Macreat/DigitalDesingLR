`timescale 1ns/1ps

module tb_pwm_uart;
    localparam CLK_PERIOD = 20; // 50 MHz
    localparam integer BAUD_DIV = 434; // matches RTL default

    reg clk = 0;
    reg rstn = 0;
    reg uart_rx_i = 1;
    wire uart_tx_o;
    wire pwm_o;
    wire [6:0] duty_percent_o;
    wire [1:0] pow2_o;
    wire [1:0] pow5_o;
    wire eostr_flag_o;
    wire [7:0] dbg_tx_byte;
    wire dbg_tx_accept;
    reg [8*64-1:0] line;
    integer len;
    reg [31:0] measured_period;

    top_pwm_uart dut (
        .clk(clk),
        .rstn(rstn),
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),
        .pwm_o(pwm_o),
        .duty_percent_o(duty_percent_o),
        .pow2_o(pow2_o),
        .pow5_o(pow5_o),
        .eostr_flag_o(eostr_flag_o),
        .dbg_tx_byte(dbg_tx_byte),
        .dbg_tx_accept(dbg_tx_accept)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // Debug monitor for stimulus line
    always @(uart_rx_i) begin
        $display("TB uart_rx_i change to %b at %0t", uart_rx_i, $time);
    end

    always @(negedge uart_tx_o) begin
        $display("TB saw uart_tx_o start at %0t", $time);
    end
    always @(posedge dbg_tx_accept) begin
        $display("DBG_TX_ACCEPT pulse %0t byte=%02x", $time, dbg_tx_byte);
    end

    integer clk_count;
    always @(posedge clk) begin
        if (!rstn) clk_count <= 0;
        else clk_count <= clk_count + 1;
    end

    task uart_send_byte(input [7:0] b);
        integer i;
        begin
            uart_rx_i <= 0; // start
            repeat (BAUD_DIV) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i <= b[i];
                repeat (BAUD_DIV) @(posedge clk);
            end
            uart_rx_i <= 1; // stop
            repeat (BAUD_DIV) @(posedge clk);
            uart_rx_i <= 1; // idle gap (1 bit)
            repeat (BAUD_DIV) @(posedge clk);
        end
    endtask

    task uart_send_string(input [8*64-1:0] str);
        integer i;
        reg [7:0] c;
        reg started;
        begin
            started = 0;
            for (i = 0; i < 64; i = i + 1) begin
                c = str[8*(63-i) +: 8];
                if (!started && c == 0) begin
                    // skip leading zeros
                end else if (started && c == 0) begin
                    i = 64; // done
                end else begin
                    started = 1'b1;
                    uart_send_byte(c);
                end
            end
        end
    endtask

    task uart_recv_line(output reg [8*64-1:0] line, output integer len);
        integer i;
        reg [7:0] b;
        reg done;
        integer guard;
        begin
            len = 0;
            line = 0;
            done = 0;
            guard = 0;
            while (uart_tx_o == 1'b1 && !done) begin
                @(posedge clk);
                guard = guard + 1;
                if (guard > 200000) begin
                    $display("Timeout waiting for UART start");
                    $finish;
                end
            end
            while (!done) begin
                guard = 0;
                while (uart_tx_o == 1'b1) begin
                    @(posedge clk);
                    guard = guard + 1;
                    if (guard > 200000) begin
                        $display("Timeout waiting for UART byte start");
                        $finish;
                    end
                end
                @(negedge uart_tx_o); // wait for start
                repeat (BAUD_DIV + BAUD_DIV/2) @(posedge clk); // mid data bit0
                b[0] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); b[1] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); b[2] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); b[3] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); b[4] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); b[5] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); b[6] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); b[7] = uart_tx_o;
                repeat (BAUD_DIV) @(posedge clk); // stop
                line[8*len +: 8] = b;
                len = len + 1;
                if (b == 8'h0A) done = 1'b1;
                repeat (BAUD_DIV) @(posedge clk); // idle gap
            end
        end
    endtask

    task capture_response(output reg [8*64-1:0] line, output integer len);
        begin : cap
            len = 0;
            line = 0;
            forever begin
                @(posedge dbg_tx_accept);
                line[8*len +:8] = dbg_tx_byte;
                len = len + 1;
                if (dbg_tx_byte == 8'h0A) disable cap;
            end
        end
    endtask

    task measure_period(output [31:0] period);
        reg prev;
        integer start_cnt;
        begin
            prev = pwm_o;
            // wait for rising edge
            @(posedge clk);
            while (!(pwm_o && !prev)) begin
                prev = pwm_o;
                @(posedge clk);
            end
            start_cnt = clk_count;
            prev = pwm_o;
            @(posedge clk);
            while (!(pwm_o && !prev)) begin
                prev = pwm_o;
                @(posedge clk);
            end
            period = clk_count - start_cnt;
        end
    endtask

    task expect_equals(input [8*64-1:0] expected, input [8*64-1:0] got, input integer len);
        integer i;
        reg match;
        begin
            match = 1'b1;
            for (i = 0; i < len; i = i + 1) begin
                if (expected[8*i +:8] == 8'h00) i = len;
                else if (expected[8*i +:8] !== got[8*i +:8]) match = 1'b0;
            end
            if (!match) begin
                $display("EXPECT MISMATCH\nexp=%s\ngot=%s", expected, got);
                $finish;
            end
        end
    endtask

    initial begin
        #5000000;
        $display("GLOBAL TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pwm_uart);
        $display("TB start");
        repeat (10) @(posedge clk);
        rstn = 1;
        repeat (10) @(posedge clk);

        // Defaults
        if (duty_percent_o !== 0 || pow2_o !== 0 || pow5_o !== 0) begin
            $display("Default registers not zero");
            $finish;
        end

        // HELP
        $display("Sending HELP");
        uart_send_string({"HELP\n",8'h00});
        $display("Waiting HELP response");
        capture_response(line, len);
        $display("Captured len=%0d first=%02x", len, line[7:0]);
        if (line[7:0] != "H") begin $display("HELP response missing"); $finish; end

        // DC50
        $display("Sending DC50");
        uart_send_string({"DC50\n",8'h00});
        capture_response(line, len);
        expect_equals({"OK\n",8'h00}, line, len);
        if (duty_percent_o != 7'd50) begin $display("Duty not updated to 50"); $finish; end
        measure_period(measured_period);
        if (measured_period != 1000) begin $display("PWM period not 1000 after DC50"); $finish; end

        // POW2=3
        $display("Sending POW2=3");
        uart_send_string({"POW23\n",8'h00});
        capture_response(line, len);
        expect_equals({"OK\n",8'h00}, line, len);
        if (pow2_o != 2'd3) begin $display("POW2 not 3"); $finish; end
        measure_period(measured_period);
        if (measured_period != 8000) begin $display("PWM period not scaled by POW2"); $finish; end

        // POW5=2 (factor 25 => total 200000)
        $display("Sending POW5=2");
        uart_send_string({"POW52\n",8'h00});
        capture_response(line, len);
        expect_equals({"OK\n",8'h00}, line, len);
        if (pow5_o != 2'd2) begin $display("POW5 not 2"); $finish; end
        measure_period(measured_period);
        if (measured_period != 200000) begin $display("PWM period not scaled by POW5"); $finish; end

        // STATUS
        $display("Sending STATUS");
        uart_send_string({"STATUS\n",8'h00});
        capture_response(line, len);
        if (line[8*0 +:8] != "F") begin $display("STATUS response malformed"); $finish; end

        // Valid DC99 then invalid DC100
        $display("Sending DC99");
        uart_send_string({"DC99\n",8'h00});
        capture_response(line, len);
        expect_equals({"OK\n",8'h00}, line, len);
        if (duty_percent_o != 7'd99) begin $display("Duty not 99"); $finish; end
        $display("Sending DC100");
        uart_send_string({"DC100\n",8'h00});
        capture_response(line, len);
        expect_equals({"FAIL\n",8'h00}, line, len);
        if (duty_percent_o != 7'd99) begin $display("Duty changed on invalid input"); $finish; end

        // Unknown command
        $display("Sending XYZ");
        uart_send_string({"XYZ\n",8'h00});
        capture_response(line, len);
        expect_equals({"FAIL\n",8'h00}, line, len);

        // Overflow (>32 bytes) should stall and still parse FAIL
        $display("Sending overflow");
        uart_send_string({"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n",8'h00});
        capture_response(line, len);
        expect_equals({"FAIL\n",8'h00}, line, len);

         // Sweep POW2 and POW5
        integer p2, p5;
        for (p2 = 0; p2 <= 3; p2 = p2 + 1) begin
            for (p5 = 0; p5 <= 3; p5 = p5 + 1) begin
                $display("Set POW2=%0d POW5=%0d", p2, p5);
                uart_send_string({"POW2", "0"+p2, "\n", 8'h00});
                capture_response(line, len);
                expect_equals({"OK\n",8'h00}, line, len);
                uart_send_string({"POW5", "0"+p5, "\n", 8'h00});
                capture_response(line, len);
                expect_equals({"OK\n",8'h00}, line, len);
                measure_period(measured_period);
                if (measured_period != 1000 * (1<<p2) * ( (p5==0)?1:(p5==1)?5:(p5==2)?25:125) )
                    begin $display("Bad period at POW2=%0d POW5=%0d", p2, p5); $finish; end
            end
        end

        $display("Sending invalid POW2=4");
        uart_send_string({"POW24\n",8'h00});
        capture_response(line, len);
        expect_equals({"FAIL\n",8'h00}, line, len);
        if (pow2_o != 2'd3) begin $display("POW2 changed on invalid"); $finish; end

                // POW2 test
        $display("Sending POW23 (pow2 = 3)");
        uart_send_string({"POW23\n",8'h00});
        capture_response(line, len);
        expect_equals({"OK\n",8'h00}, line, len);

        if (pow2_o != 2'd3) begin
            $display("ERROR: pow2_o expected 3 but got %0d", pow2_o);
            $finish;
        end

        measure_period(measured_period);
        if (measured_period != (1000 * 8)) begin  // 2^3 = 8
            $display("ERROR: PWM period incorrect for pow2=3. Measured=%0d", measured_period);
            $finish;
        end
        $display("POW2=3 OK, period=%0d", measured_period);

        // POW5 test
        $display("Sending POW52 (pow5 = 2)");
        uart_send_string({"POW52\n",8'h00});
        capture_response(line, len);
        expect_equals({"OK\n",8'h00}, line, len);

        if (pow5_o != 2'd2) begin
            $display("ERROR: pow5_o expected 2 but got %0d", pow5_o);
            $finish;
        end

        measure_period(measured_period);
        if (measured_period != (1000 * 25)) begin  // 5^2 = 25
            $display("ERROR: PWM period incorrect for pow5=2. Measured=%0d", measured_period);
            $finish;
        end
        $display("POW5=2 OK, period=%0d", measured_period);

        $display("All tests passed");
        $finish;
    end
endmodule
