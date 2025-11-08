`timescale 1ns/1ps
`default_nettype none

module tb_uart_sampler;

    localparam integer CLK_FREQ_HZ = 1_600_000;
    localparam integer BAUD_RATE   = 100_000;
    localparam integer BIT_PERIOD  = CLK_FREQ_HZ / BAUD_RATE; // 16 cycles/bit

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg rx = 1'b1;

    wire tick;
    wire align;
    wire bit_valid;
    wire bit_data;
    wire framing_error;
    wire frame_done;
    wire busy;

    baud_gen #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) u_baud_gen (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (busy),
        .align (align),
        .tick  (tick)
    );

    uart_sampler #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .rx           (rx),
        .tick         (tick),
        .align        (align),
        .bit_valid    (bit_valid),
        .bit_data     (bit_data),
        .framing_error(framing_error),
        .frame_done   (frame_done),
        .busy         (busy)
    );

    always #20 clk = ~clk; // 25 MHz

    integer align_count;
    integer frame_done_count;
    integer framing_error_pulses;
    integer total_bit_valid;

    reg [7:0] captured_bits;
    integer bit_index;
    integer bits_this_frame;
    integer last_bits_per_frame;
    reg last_frame_error;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            align_count          <= 0;
            frame_done_count     <= 0;
            framing_error_pulses <= 0;
            total_bit_valid      <= 0;
            captured_bits        <= 8'd0;
            bit_index            <= 0;
            bits_this_frame      <= 0;
            last_bits_per_frame  <= 0;
            last_frame_error     <= 1'b0;
        end else begin
            if (align)
                align_count <= align_count + 1;

            if (frame_done) begin
                frame_done_count    <= frame_done_count + 1;
                last_bits_per_frame <= bits_this_frame;
                last_frame_error    <= framing_error;
            end

            if (framing_error && !frame_done)
                framing_error_pulses <= framing_error_pulses + 1;

            if (!busy) begin
                bit_index       <= 0;
                bits_this_frame <= 0;
            end

            if (bit_valid) begin
                total_bit_valid <= total_bit_valid + 1;
                bits_this_frame <= bits_this_frame + 1;

                if (bit_index < 8)
                    captured_bits[bit_index] <= bit_data;
                else
                    $fatal(1, "Received more than 8 data bits in a frame.");

                bit_index <= bit_index + 1;
            end
        end
    end

    task automatic wait_idle;
        begin
            @(posedge clk);
            while (busy) @(posedge clk);
        end
    endtask

    task automatic send_frame(
        input [7:0] data_byte,
        input bit   stop_high,
        input integer idle_cycles
    );
        integer i;
        begin
            wait_idle();

            rx <= 1'b1;
            repeat (idle_cycles) @(posedge clk);

            rx <= 1'b0; // start bit
            repeat (BIT_PERIOD) @(posedge clk);

            for (i = 0; i < 8; i = i + 1) begin
                rx <= data_byte[i];
                repeat (BIT_PERIOD) @(posedge clk);
            end

            rx <= stop_high;
            repeat (BIT_PERIOD) @(posedge clk);

            rx <= 1'b1; // idle line
        end
    endtask

    task automatic expect_frame(
        input [7:0] data_byte,
        input bit   stop_high,
        input bit   expect_error,
        input integer idle_cycles
    );
        begin
            send_frame(data_byte, stop_high, idle_cycles);
            wait (frame_done);
            @(posedge clk);

            if (last_bits_per_frame != 8)
                $fatal(1, "Expected 8 data bits, observed %0d", last_bits_per_frame);

            if (captured_bits !== data_byte)
                $fatal(1, "Captured byte %b does not match expected %b", captured_bits, data_byte);

            if (last_frame_error !== expect_error)
                $fatal(1, "Framing error flag mismatch. expected %0b got %0b", expect_error, last_frame_error);
        end
    endtask

    task automatic inject_start_glitch(input integer low_cycles);
        integer prev_align;
        integer prev_bit_valid;
        integer prev_frame_done;
        integer prev_error_pulses;
        begin
            wait_idle();
            prev_align         = align_count;
            prev_bit_valid     = total_bit_valid;
            prev_frame_done    = frame_done_count;
            prev_error_pulses  = framing_error_pulses;

            rx <= 1'b0;
            repeat (low_cycles) @(posedge clk);
            rx <= 1'b1;

            repeat (BIT_PERIOD * 2) @(posedge clk);

            if (align_count != prev_align + 1)
                $fatal(1, "Glitch should produce a single align pulse.");

            if (frame_done_count != prev_frame_done)
                $fatal(1, "Glitch must not complete a frame.");

            if (total_bit_valid != prev_bit_valid)
                $fatal(1, "Glitch must not emit data bits.");

            if (framing_error_pulses != prev_error_pulses + 1)
                $fatal(1, "Glitch should raise exactly one framing_error pulse.");
        end
    endtask

    initial begin
        repeat (10) @(posedge clk);
        rst_n <= 1'b1;

        expect_frame(8'hA5, 1'b1, 1'b0, BIT_PERIOD * 2);
        expect_frame(8'h3C, 1'b1, 1'b0, BIT_PERIOD);
        expect_frame(8'h55, 1'b0, 1'b1, BIT_PERIOD * 2); // stop bit low → framing error

        inject_start_glitch(BIT_PERIOD / 4);

        if (align_count != frame_done_count + 1)
            $fatal(1, "Align/frame_done mismatch: align=%0d frame_done=%0d",
                   align_count, frame_done_count);
        
        $display("tb_uart_sampler: PASS");
        $finish;
    end

`ifdef WAVES
    initial begin
        $dumpfile("results/tb_uart_sampler.vcd");
        $dumpvars(1, tb_uart_sampler);
    end
`endif

endmodule

`default_nettype wire


