# Flujo de trabajo – Sintetizador Nexys Video A7

Este directorio contiene todo lo necesario para implementar y verificar el pipeline de síntesis solicitado en `designReq.md`, listo para ser simulado con **Icarus Verilog** y posteriormente migrado a la Nexys Video A7 (Artix‑7).

## Estructura

| Carpeta / Archivo | Contenido |
| --- | --- |
| `designReq.md` | Documento original con los requisitos entregados. |
| `src/rtl/entry` | UART MIDI (`midi_uart_rx`), decodificador de knobs y demultiplexor de parámetros. |
| `src/rtl/core` | Núcleo FM: `phase_accumulator`, `sine_lut`, `envelope_gen`, `fm_synth`. |
| `src/rtl/output` | Salida PWM y `dma_stub` (punto de inserción para AXI/MicroBlaze). |
| `src/rtl/top` | Integración `nexys_audio_top`. |
| `tb/` | Testbenches por módulo + TB de integración. |
| `sim/filelist.f` | Manifiesto para Icarus (se usa desde el `Makefile`). |
| `docs/` | Arquitectura, diagrama de bloques y plan de verificación. |
| `scripts/run_iverilog.sh` | Wrapper para lanzar `make run` con cualquier TB. |

## Flujo recomendado

1. **Configurar entorno** – Instala `iverilog`, `vvp` y opcionalmente `gtkwave`. Sitúate en `repo/DigitalDesingLR/devEnv/work/prj`.
2. **Simular un módulo** – `make run TB=tb/midi_uart_rx_tb.v`. Los artefactos (`.vvp`, `.vcd`) se guardan en `sim/build/`.
3. **Analizar ondas** – `make waves TB=tb/fm_synth_tb.v` abre GTKWave con el fichero VCD del test seleccionado.
4. **Iterar parámetros** – Ajusta los presets en `param_demux` o envía nuevos bytes MIDI desde la TB de integración (`tb/nexys_audio_top_tb.v`).
5. **Prepararse para FPGA** – Sustituye `dma_stub` por un AXI-DMA/MicroBlaze, conecta `audio_pwm_p/n` al amplificador de la Nexys y filtra con un LPF <20 kHz.

## Documentación

- `docs/architecture.md` resume la partición Entry/Core/Output e incluye el diagrama de bloques en formato Mermaid.
- `docs/verification_plan.md` detalla qué cubre cada testbench y los checks mínimos antes de llevarlo a Vivado.

## Notas sobre implementación

- Los incrementos DDS por defecto generan ~432 Hz usando un reloj de 100 MHz. Cambia `CLK_FREQ_HZ` en `nexys_audio_top` y `midi_uart_rx` si usas otro reloj base.
- `sine_lut` carga automáticamente `sim/sine_lut_q12.mem`. Puedes regenerar la tabla con mayor resolución y apuntar el parámetro `MEM_FILE` a un BRAM inicializado.
- `fm_synth` incluye ganancia, beta y feedback firmados de 16 bits; ajusta la escala (`>> (DATA_WIDTH-2)`) si necesitas más headroom.
- Para hardware real, sincroniza el botón de gate y desactiva el bloque PWM durante configuración para evitar pops acústicos.

## Próximos pasos sugeridos

1. Generar un bloque AXI-Lite que permita modificar los registros de `param_demux` desde MicroBlaze o Zynq.
2. Añadir un conversor Delta-Sigma (1bit DSD) alternativo al PWM para evaluar SNR contra el amplificador D clase.
3. Incorporar scripts de regresión (bash o Python) que automaticen `make run` sobre todos los TBs antes de sintetizar.
