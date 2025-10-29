# AI Usage

- Assistant used: OpenAI Codex CLI–based agent in a terminal harness.
- Task prompt: see `tasks/1stTask/README.md` for the assignment text provided by the user, and the Spanish request to scaffold the project and describe the workflow.

AI tools were employed to support the engineering workflow, not to replace the design process. They assisted in:

\*Structuring the modular architecture (decoder, counter, FSM, and top module).

\*Writing and validating self-checking testbenches with $fatal conditions.

\*Creating an automated Makefile for reproducible Icarus Verilog runs.

\*Drafting technical documentation and the block diagram (.dot) of the system.

\*Interpreting GTKWave simulations to generate precise waveform analyses.

\*Improving clarity, consistency, and traceability of the deliverable.

All outputs were manually verified, reviewed for correctness, and refined before inclusion in the project repository.

- Prompting strategy:

  - Clarify module interfaces and responsibilities up front.
  - Implement core modules first, then self-checking testbenches.
  - Provide a Makefile to standardize runs.
  - Document the design, test plan, and include a block diagram.
  - Keep modules minimal and orthogonal to simplify verification.

- Example prompts:

  - “Act as a digital design and verification expert. Define a Verilog workflow with four modules (decoder, counter, FSM, top) and explain the testing methodology.”

  - “Generate a Makefile to compile and execute all Verilog testbenches in /src and /tb using Icarus Verilog.”

  - “Create a professional Graphviz .dot diagram for the top_knightrider module showing signal connectivity without overlaps.”

  - “Interpret this GTKWave output from the top module and provide a concise technical summary .”
