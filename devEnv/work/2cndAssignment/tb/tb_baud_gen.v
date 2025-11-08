`timescale 1ns/1ps

module tb_baud_gen;
    localparam integer CLK_FREQ_HZ = 1_000_000;
    localparam integer BAUD_RATE   = 115_200;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg en = 1'b0;
    reg align = 1'b0;
    wire tick;

    real target_interval;
    real half_interval;
    real first_diff;
    integer cycle_count;
    integer last_tick_cycle;
    integer first_interval;
    integer interval_sum;
    integer interval_count;
    integer min_interval;
    integer max_interval;
    reg tick_prev;

    baud_gen #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .align (align),
        .tick  (tick)
    );

    always #20 clk = ~clk;  // 25 MHz notional period.

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0;
            tick_prev   <= 1'b0;
        end else begin
            cycle_count <= cycle_count + 1;
            tick_prev   <= tick;

            if (tick_prev && tick) begin
                $fatal(1, "[%0t] Tick width longer than 1 cycle detected.", $time);
            end
        end
    end

    always @(posedge clk) begin
        if (tick) begin
            integer interval;
            interval = cycle_count - last_tick_cycle;

            if (interval_count == 0) begin
                first_interval = interval;
            end else begin
                interval_sum += interval;
                if (interval < min_interval) min_interval = interval;
                if (interval > max_interval) max_interval = interval;
            end

            last_tick_cycle = cycle_count;
            interval_count  = interval_count + 1;

            if (interval_count == 40) begin
                real avg_interval;
                avg_interval = interval_sum / real'(interval_count - 1);

                if (avg_interval < target_interval - 0.1 || avg_interval > target_interval + 0.1) begin
                    $fatal(1, "Average interval %0f deviates from expected %0f cycles.", avg_interval, target_interval);
                end

                if (min_interval < $floor(target_interval) - 1 || max_interval > $ceil(target_interval) + 1) begin
                    $fatal(1, "Interval bounds out of range. min=%0d max=%0d target=%0f", min_interval, max_interval, target_interval);
                end

                half_interval = target_interval / 2.0;
                first_diff    = first_interval - half_interval;
                if (first_diff < 0) first_diff = -first_diff;
                if (first_diff > 3.0) begin
                    $fatal(1, "First interval (%0d) deviates more than 3 cycles from half-bit (%0f).", first_interval, half_interval);
                end

                en <= 1'b0;
            end
        end
    end

    initial begin
        target_interval = real'(CLK_FREQ_HZ) / real'(BAUD_RATE);
        last_tick_cycle = 0;
        first_interval  = 0;
        interval_sum    = 0;
        interval_count  = 0;
        min_interval    = 1_000_000;
        max_interval    = 0;

        repeat (5) @(posedge clk);
        rst_n <= 1'b1;

        @(posedge clk);
        en    <= 1'b1;
        align <= 1'b1;
        last_tick_cycle = cycle_count;
        @(posedge clk);
        align <= 1'b0;

        // Allow collector to disable generator once checks are done.
        wait (interval_count == 40);
        repeat (10) @(posedge clk);

        if (tick) begin
            $fatal(1, "Tick asserted after generator disabled.");
        end

        $display("tb_baud_gen: PASS");
        $finish;
    end

    initial begin 
        $dumpfile("results/tb_baud_gen.vcd");
        $dumpvars(0, tb_baud_gen);
    end




endmodule
