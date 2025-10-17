# 1st code DIR

## 8-bit PISO Shift Register (SN74LS165-like)

### Overview

Implements an **8-bit Parallel-In Serial-Out (PISO)** register with:

- **Async parallel load** (active-low `sh_ld_n`)
- **Shift on `posedge clk`** when not inhibited (`clk_inh=0`)
- **Serial input** `ser` enters at MSB; **serial output** `qh` is LSB

### Interface

- `clk` → system clock
- `clk_inh` → when `1`, shifting is blocked
- `ser` → serial bit that enters on each shift
- `sh_ld_n` → **0=load now**, **1=shift mode**
- `parallel_in[7:0]` → value to load
- `q[7:0]` → current register contents
- `qh` → serial output = `q[0]`

### Intended Behavior

- **Async load:** if `sh_ld_n=0` ⇒ `q ← parallel_in` immediately (no clock).
- **Shift right (on `posedge clk`):** if `sh_ld_n=1` and `clk_inh=0`  
  `q <= {ser, q[7:1]}`; the LSB flows out on `qh`.
