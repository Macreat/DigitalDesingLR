# AI Usage

This design and documentation were prepared with the assistance of ChatGPT (GPT-5) and OpenAI Codex CLI–based agent in a terminal harness. for:
Verilog code structure and module interconnection.

Testbench development for modular verification.

Documentation drafting and waveform interpretation.

Prompting strategy: iterative, module-by-module debugging and refinement based on simulation results.

Task prompt: see devEnv/work/2cndAssignment/docs/Assignment...md for the assignment text provided by the user, and the Spanish request to scaffold the project and describe the workflow.
AI tools were employed to support the engineering workflow, not to replace the design process. They assisted in:

\*Structuring the modular architecture.

- Modular debbugging.

\*Writing and validating self-checking testbenches with $fatal conditions.

\*Creating an automated Makefile for reproducible Icarus Verilog runs.

\*Interpreting GTKWave simulations to generate precise waveform analyses.

\*Improving clarity, consistency, and traceability of the deliverable.

All outputs were manually verified, reviewed for correctness, and refined before inclusion in the project repository.

Prompting strategy:

Clarify module interfaces and responsibilities up front.
Implement core modules first, then self-checking testbenches.
Provide a Makefile to standardize runs.
Document the design, test plan, and include a block diagram.
Keep modules minimal and orthogonal to simplify verification.
Example prompts:

“Act as a digital design and verification expert. Define a Verilog workflow with modules (baud generator, uart sampler ,serial parallel register ,detector and top ) and explain the testing methodology.”

“Generate a Makefile to compile and execute all Verilog testbenches in /src and /tb using Icarus Verilog.”

“Interpret this GTKWave output from the top module and provide a concise technical summary .”
