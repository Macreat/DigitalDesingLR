`timescale 1ns/1ps

module tb_top;
    localparam integer CLK_FREQ_HZ = 0_600_000;
    localparam integer BAUD_RATE   = 100_000;
    localparam integer BIT_PERIOD  = CLK_FREQ_HZ / BAUD_RATE;
    localparam [3:0]  PATTERN      = 4'd7;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg rx = 1'b1;

    wire match;
    wire framing_error;
    wire [7:0] shift_window;
    wire frame_done;
    wire bit_strobe;

    uart_pattern_top #(
        .CLK_FREQ_HZ    (CLK_FREQ_HZ),
        .BAUD_RATE      (BAUD_RATE),
        .ID_LAST_DIGIT  (PATTERN)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .rx           (rx),
        .match        (match),
        .framing_error(framing_error),
        .shift_window (shift_window),
        .frame_done   (frame_done),
        .bit_strobe   (bit_strobe)
    );

    always #20 clk = ~clk;

    // Expected bit queue.
    reg expected_bits [0:1023];
    integer write_ptr;
    integer read_ptr;

    reg [7:0] expected_shift;
    reg [7:0] expected_shift_next;
    integer bit_counter;

    integer expected_match_indices [0:1023];
    integer observed_match_indices [0:1023];
    integer expected_match_count;
    integer observed_match_count;
    integer last_bit_index_seen;

    reg match_prev;

    integer frame_done_count;
    reg last_frame_error;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_shift       <= 8'd0;
            expected_shift_next  <= 8'd0;
            bit_counter          <= 0;
            write_ptr            <= 0;
            read_ptr             <= 0;
            expected_match_count <= 0;
            observed_match_count <= 0;
            last_bit_index_seen  <= -1;
            match_prev           <= 1'b0;
            frame_done_count     <= 0;
            last_frame_error     <= 1'b0;
        end else begin
            if (bit_strobe) begin
                bit sampled_bit;
                if (read_ptr >= write_ptr) begin
                    $fatal(1, "Bit strobe queue underflow (read_ptr=%0d write_ptr=%0d).", read_ptr, write_ptr);
                end

                sampled_bit = expected_bits[read_ptr];
                read_ptr    <= read_ptr + 1;

                expected_shift_next = {expected_shift[6:0], sampled_bit};

                if (shift_window !== expected_shift_next) begin
                    $fatal(1, "Shift window mismatch. Expected %b got %b", expected_shift_next, shift_window);
                end

                expected_shift <= expected_shift_next;

                if (bit_counter >= 3 && expected_shift_next[3:0] == PATTERN) begin
                    expected_match_indices[expected_match_count] = bit_counter;
                    expected_match_count <= expected_match_count + 1;
                end

                last_bit_index_seen <= bit_counter;
                bit_counter         <= bit_counter + 1;
            end

            match_prev <= match;

            if (match && match_prev) begin
                $fatal(1, "Match pulse wider than one cycle detected.");
            end

            if (match) begin
                if (last_bit_index_seen < 0) begin
                    $fatal(1, "Match without preceding bit sample.");
                end
                observed_match_indices[observed_match_count] = last_bit_index_seen;
                observed_match_count <= observed_match_count + 1;
            end

            if (frame_done) begin
                frame_done_count <= frame_done_count + 1;
                last_frame_error <= framing_error;
            end
        end
    end

    task automatic queue_bit(input bit value);
        begin
            if (write_ptr >= 1024) begin
                $fatal(1, "Expected bit queue overflow.");
            end
            expected_bits[write_ptr] = value;
            write_ptr = write_ptr + 1;
        end
    endtask

    task automatic wait_frames_idle;
        begin
            @(posedge clk);
            repeat (BIT_PERIOD) @(posedge clk);
        end
    endtask

    task automatic send_byte(
        input [7:0] data_byte,
        input bit   stop_high,
        input integer idle_cycles
    );
        integer i;
        begin
            repeat (idle_cycles) @(posedge clk);

            rx <= 1'b0; // start bit
            repeat (BIT_PERIOD) @(posedge clk);

            for (i = 0; i < 8; i = i + 1) begin
                rx <= data_byte[i];
                queue_bit(data_byte[i]);
                repeat (BIT_PERIOD) @(posedge clk);
            end

            rx <= stop_high;
            repeat (BIT_PERIOD) @(posedge clk);

            rx <= 1'b1;
        end
    endtask

    task automatic reset_scoreboard;
        begin
            expected_shift       = 8'd0;
            expected_shift_next  = 8'd0;
            bit_counter          = 0;
            write_ptr            = 0;
            read_ptr             = 0;
            expected_match_count = 0;
            observed_match_count = 0;
            last_bit_index_seen  = -1;
            match_prev           = 1'b0;
            frame_done_count     = 0;
            last_frame_error     = 1'b0;
        end
    endtask

    task automatic inject_start_glitch(input integer low_cycles);
        integer queue_start;
        begin
            queue_start = write_ptr;
            rx <= 1'b0;
            repeat (low_cycles) @(posedge clk);
            rx <= 1'b1;
            repeat (BIT_PERIOD * 2) @(posedge clk);

            if (write_ptr != queue_start) begin
                $fatal(1, "Start glitch should not enqueue data bits.");
            end
        end
    endtask
    initial begin
        reset_scoreboard();

        repeat (12) @(posedge clk);
        rst_n <= 1'b1;

        send_byte(8'hCE, 1'b1, BIT_PERIOD * 2);
        send_byte(8'hEE, 1'b1, BIT_PERIOD);
        send_byte(8'hF0, 1'b1, BIT_PERIOD * 2);

        wait (frame_done_count == 3);
        @(posedge clk);

        if (expected_match_count != 4 || observed_match_count != 4) begin
            $fatal(1, "Mismatch in match counts. expected=%0d observed=%0d", expected_match_count, observed_match_count);
        end

        if (expected_match_indices[0] !== 3 || expected_match_indices[1] !== 8 ||
            expected_match_indices[2] !== 15 || expected_match_indices[3] !== 22) begin
            $fatal(1, "Unexpected expected-match indices: %0d %0d %0d %0d",
                   expected_match_indices[0], expected_match_indices[1],
                   expected_match_indices[2], expected_match_indices[3]);
        end

        if (observed_match_indices[0] !== 3 || observed_match_indices[1] !== 8 ||
            observed_match_indices[2] !== 15 || observed_match_indices[3] !== 22) begin
            $fatal(1, "Unexpected observed-match indices: %0d %0d %0d %0d",
                   observed_match_indices[0], observed_match_indices[1],
                   observed_match_indices[2], observed_match_indices[3]);
        end

        if (last_frame_error !== 1'b0) begin
            $fatal(1, "Unexpected framing error during nominal frames.");
        end

        // Reset and test "no match" path.
        rst_n <= 1'b0;
        rx    <= 1'b1;
        repeat (5) @(posedge clk);
        reset_scoreboard();
        rst_n <= 1'b1;
        repeat (2) @(posedge clk);

        send_byte(8'hFF, 1'b1, BIT_PERIOD * 2);
        wait (frame_done_count == 1);
        @(posedge clk);

        if (expected_match_count != 0 || observed_match_count != 0) begin
            $fatal(1, "Matches detected when none expected.");
        end

        // Stop-bit noise check.
        reset_scoreboard();
        send_byte(8'hA5, 1'b0, BIT_PERIOD * 2); // stop bit forced low
        wait (frame_done_count == 1);
        @(posedge clk);

        if (last_frame_error !== 1'b1) begin
            $fatal(1, "Framing error not asserted on bad stop bit.");
        end

        // Start glitch scenario.
        inject_start_glitch(BIT_PERIOD / 4);
        if (write_ptr != read_ptr) begin
            $fatal(1, "Glitch should not produce pending data bits.");
        end
        if (expected_match_count != 0 || observed_match_count != 0) begin
            $fatal(1, "Glitch produced unexpected matches.");
        end

        $display("tb_top: PASS");
        $dumpfile("dump.vcd"); 
        $dumpvars;
        $finish;
      
    end

    initial begin 
        $dumpfile("results/tb_top.vcd");
        $dumpvars(0, tb_top);
    end
    
   
endmodule
