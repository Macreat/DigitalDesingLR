# 1st task desing specifications:

Devise a verilog project containing four modules, each one of them with its respective test bench. The modules are:

- A combinational module that implements a three bit decoder (demux, one hot).
- A sequential module that implements a state machine that implements a four bit up/down counter with asynchronous reset and an count enable bit.
- A sequential module that implements a two-state state machine.
- A top module that connects the other three to implement a knight-rider-like sequence. The two-state machine will be used to change the direction of the hot bit of the decoder.
  Draw a block diagram depicting the structural architecture of the top module.
  Write a document describing the modules, and the test strategy chosen to assess the suitability of the implementation.
  If you used an AI to help you write the code, please state which one was used, and include the chat and explain the strategy chosen for the prompts of the chat.

resource : classroom task assigned

---

# design :

## Project delivered under `devEnv/tasks/1stTask/`:

- results: `tasks/1stTask/results/ .jpg and .vcd`
- Sources: `devEnv/tasks/1stTask/src/*.v`
- Testbenches: `tasks/1stTask/tb/*.v`
- Makefile: `tasks/1stTask/Makefile`
- Docs: `tasks/1stTask/docs/`

  - Design and test plan: `tasks/1stTask/docs/DESIGNrules.md`
  - Block diagram (Graphviz): `tasks/1stTask/docs/block_diagram.dot/.svg/.png`
  - AI usage notes: `tasks/1stTask/docs/AI_USAGE.md`

## How to run tests:

- Prereqs: `iverilog` and `vvp` in PATH.
- From `tasks/1stTask/`: run `make test`.

## Notes :

- The Knight Rider pattern is implemented by bouncing a hot (one‑hot) bit across 8 LEDs. A two‑state FSM decides the direction (right/left ; count up / down) at the ends (0 and 7), the 4‑bit counter is used with `dir` and `en`, and the 3‑to‑8 decoder converts the position `pos=count[2:0]` to LEDs.

- For real hardware, add a clock divider in the top module to visualize the movement.
