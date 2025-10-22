SIM project - 4-bit up counter driven by frequency divider

This project reproduces the example in `proof/2cndTask/2ncdDesign`.

Structure:

- src/: RTL sources (`freq_divider.v`, `up_counter.v`, `top.v`)
- tb/: testbenches (`up_counter_4bit_tb.v`)
- devEnv/: helper scripts for building/running simulations

How to run (PowerShell + Icarus Verilog):

1. Open PowerShell and change to this folder's `devEnv` directory.
2. Run the helper script: `.
un_sim.ps1`

The script compiles the RTL and testbench with `iverilog` and runs the produced simulation (`vvp`). A `up_counter_tb.vcd` file is produced.

