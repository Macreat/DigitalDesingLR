# AI Usage

This UART-controlled PWM project (3rdAssignment) was built with assistance from ChatGPT (GPT-5) via the OpenAI Codex CLI agent in a terminal harness. AI was used to:

- Structure Verilog modules and interconnections for UART RX/TX, command parser, PWM core, and top integration.
- Develop self-checking testbenches (UART bit-level stimulus, PWM period checking, FAIL/OK command responses).
- Draft documentation (design note, README, workflow) and interpret waveforms for debugging.
- Iterate prompts to debug module-by-module based on simulation results.

Source prompts included the Spanish requests to scaffold the project and describe the workflow, and the functional requirements in `devEnv/work/3rdAssignment/PWM UART Functional requirements.md`.

AI support focused on acceleration, not substitution of engineering judgment. All outputs were reviewed and refined before inclusion.

Prompting strategy:

- Clarify interfaces and responsibilities up front (UART framing, parser rules, PWM scaling).
- Implement core RTL first, then layered self-checking TB.
- Provide reproducible run script (`scripts/run_sim.ps1`) for iverilog/vvp.
- Document architecture, test plan, and edge cases (invalid parameters, buffer overflow).

Example prompts:

- “Act as a digital design and verification expert. Define the UART-controlled PWM modules (uart_rx, uart_tx, cmd_parser, pwm_core, top) and the testing methodology.”
- “Generate a PowerShell script to compile and execute all Verilog testbenches with Icarus Verilog.”
- “Interpret this GTKWave output from the top module and provide a concise technical summary.”
