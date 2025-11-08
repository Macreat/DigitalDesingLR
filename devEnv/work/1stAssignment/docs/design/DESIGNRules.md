# Knight Rider Verilog Project — Design and Test Strategy

## Overview

This project implements four modules and their testbenches to create a Knight Rider–style one-hot moving light across 8 LEDs:

- `decoder3to8`: combinational 3-to-8 one-hot decoder.
- `updown_counter4`: 4-bit up/down counter with asynchronous reset and enable.
- `two_state_fsm`: two-state FSM controlling direction (RIGHT/LEFT) based on position at boundaries.
- `top_knightrider`: structural top that wires the above to produce a bouncing one-hot pattern.

All modules are under `src/`, testbenches under `tb/`, and a `Makefile` is provided.

## Workflow summarize:

- Modular design: first, clear interfaces for the 4 modules were defined.
- Implementation: the modules were coded in `src/` with minimal, well-separated logic.
- Verification: self-checking testbenches were created in `tb/` for each module and for the top-level.
- Automation: a `Makefile` was added using a prompt, in order to build and run all tests.
- Documentation: `docs/DESIGNRules.md` was written with the structural diagram and the testing strategy, plus `docs/AI_USAGE.md` with the AI usage statement and sources.

## Module Descriptions

### decoder3to8 (`src/decoder3to8.v`)

- Inputs: `sel[2:0]`
- Outputs: `y[7:0]` (one-hot)
- Behavior: `y = 1 << sel`. Purely combinational.
- Rationale: Clean one-line implementation; synthesizes well to standard decode logic.

### updown_counter4 (`src/updown_counter4.v`)

- Inputs: `clk`, `arst` (async active-high), `en`, `dir`
- Outputs: `q[3:0]`
- Behavior: On `arst=1`, `q<=0`. When `en=1`, increment or decrement by 1 depending on `dir`.
- Rationale: Generic 4-bit counter per spec. The top limits motion to 0..7 via FSM policy, so no extra bounds logic needed inside the counter.

### two_state_fsm (`src/two_state_fsm.v`)

- Inputs: `clk`, `arst`, `pos[2:0]`
- Outputs: `dir`
- States: `RIGHT` (dir=1), `LEFT` (dir=0)
- Transitions:
  - RIGHT -> LEFT when `pos==7`
  - LEFT -> RIGHT when `pos==0`
  - otherwise hold
- Rationale: Minimal 2-state policy; next-state depends on position at boundaries to create a bounce.

### top_knightrider (`src/top_knightrider.v`)

- Inputs: `clk`, `arst`, `en`
- Outputs: `leds[7:0]`
- Structure:
  - `updown_counter4` produces `count[3:0]`; `pos=count[2:0]`.
  - `two_state_fsm` uses `pos` to select `dir`.
  - `updown_counter4` consumes `dir` to step up/down.
  - `decoder3to8` converts `pos` to `leds` (one-hot).
- Rationale: Keeps functionality modular and testable; top glues modules without duplicating logic.

## Block Diagram (Structural) TOP MODULE

```
        +-----------------+        +------------------+
        |                 |  dir   |                  |
clk --->| updown_counter4 |------->|  two_state_fsm   |
arst -->|       (q[3:0])  |        |   (uses pos)     |
en   --->                 |        +------------------+
        |                 |                 ^
        +-----------------+                 |
                  |                         |
                 q[2:0] = pos --------------+
                  |
                  v
        +-----------------+
        |   decoder3to8   |
        |   (sel=pos)     |
        +-----------------+
                  |
                leds[7:0]
```

## Test Strategy

Unit tests are self-checking using `iverilog`/`vvp`:

- `tb_decoder3to8`: Iterates `sel=0..7` and checks `y==(1<<sel)`.
- `tb_updown_counter4`: Verifies async reset, count up for 5 cycles, count down for 3, and enable gating.
- `tb_two_state_fsm`: Asserts initial RIGHT, flips to LEFT at `pos=7`, flips to RIGHT at `pos=0`.
- `tb_top_knightrider`: Observes full bounce pattern from LSB to MSB and back, verifying no double-dwell at ends.

Run all tests with `make test`.

## Notes on Synthesis/Timing

- All sequential logic uses synchronous clocks and async resets.
- `two_state_fsm` uses state held in the output `dir` itself to keep it minimal.
- For real hardware, add a clock divider in `top` to slow the LED scan rate; the current design assumes a simulation timescale.

## AI Usage Disclosure

- Assistant: OpenAI Codex CLI–based agent.
- Prompt strategy: define clear module specs and interfaces; tie behavior to boundaries; insist on self-checking testbenches and a Makefile; iterate structure-first, then tests, then docs, finally prompt help with theoric and basis analysis.

- Included: task statement (see `work/1stTask/README.md`) and this design rationale.
