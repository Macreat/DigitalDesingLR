# 1st task dev

Devise a verilog project containing four modules, each one of them with its respective test bench. The modules are:

- A combinational module that implements a three bit decoder (demux, one hot).
- A sequential module that implements a state machine that implements a four bit up/down counter with asynchronous reset and an count enable bit.
- A sequential module that implements a two-state state machine.
- A top module that connects the other three to implement a knight-rider-like sequence. The two-state machine will be used to change the direction of the hot bit of the decoder.
  Draw a block diagram depicting the structural architecture of the top module.
  Write a document describing the modules, and the test strategy chosen to assess the suitability of the implementation.
  If you used an AI to help you write the code, please state which one was used, and include the chat and explain the strategy chosen for the prompts of the chat.

---

# design :

Project delivered under `proof/1stTask/`:

- Sources: `proof/1stTask/src/*.v`
- Testbenches: `proof/1stTask/tb/*.v`
- Makefile: `proof/1stTask/Makefile`
- Docs: `proof/1stTask/docs/`
  - Design and test plan: `proof/1stTask/docs/DESIGN.md`
  - Block diagram (Graphviz): `proof/1stTask/docs/block_diagram.dot`
  - AI usage notes: `proof/1stTask/docs/AI_USAGE.md`

How to run tests:

- Prereqs: `iverilog` and `vvp` in PATH.
- From `proof/1stTask/`: run `make test`.

Workflow resumen (flujo de trabajo):

- Diseño modular: primero se definieron interfaces claras de los 4 módulos.
- Implementación: se codificaron los módulos en `src/` con lógica mínima y bien separada.
- Verificación: se crearon testbenches auto‑verificables en `tb/` para cada módulo y para el top.
- Automatización: se añadió un `Makefile` para compilar y ejecutar todas las pruebas.
- Documentación: se escribió `docs/DESIGN.md` con el diagrama estructural y la estrategia de pruebas, además de `docs/AI_USAGE.md` con la declaración de uso de IA.

Notas:

- El patrón Knight Rider se implementa haciendo rebotar un bit caliente (one‑hot) sobre 8 LEDs. El FSM de dos estados decide la dirección (derecha/izquierda) en los extremos (0 y 7), el contador de 4 bits se usa con `dir` y `en`, y el decodificador 3‑a‑8 convierte la posición `pos=count[2:0]` a LEDs.
- Para hardware real, agregue un divisor de reloj en el top para visualizar el movimiento.
