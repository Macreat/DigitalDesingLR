Design Note - 4-bit up counter with frequency divider

Overview:

- `freq_divider.v` divides a 50 MHz input clock down to 1 Hz (for demonstration). It uses a 26-bit counter and toggles the output every DIVISOR/2 cycles.
- `up_counter.v` is a 4-bit up counter with enable input. It increments on the rising edge of the incoming clock when `en` is high.
- `top.v` connects the divider and counter so the counter ticks at the divided clock rate.

Design decisions:

- The divider uses an initial block to set deterministic startup values (no external reset is used in the original example).
- The testbench uses a faster clock period (10 ns) for simulation convenience; the divider's DIVISOR is large and will yield a long simulation time — for verification the design is best exercised by adjusting DIVISOR or by directly driving the counter clock in tests.

Verification:

- The testbench `up_counter_4bit_tb.v` toggles enable and prints the counter. It dumps `up_counter_tb.vcd` for waveform inspection.
