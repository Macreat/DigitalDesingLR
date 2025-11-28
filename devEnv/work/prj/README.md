# Flujo de trabajo - Sintetizador Nexys Video A7

Este directorio contiene todo lo necesario para implementar y verificar el pipeline de sintesis solicitado en `designReq.md`, listo para ser simulado con **Icarus Verilog** y posteriormente migrado a la Nexys Video A7 (Artix-7).

## Estructura

| Carpeta / Archivo | Contenido |
| --- | --- |
| `designReq.md` | Documento original con los requisitos entregados. |
| `src/rtl/entry` | UART MIDI (`midi_uart_rx`), decodificador de knobs y demultiplexor de parametros. |
| `src/rtl/core` | Nucleo FM: `phase_accumulator`, `sine_lut`, `envelope_gen`, `fm_synth`. |
| `src/rtl/output` | Salida PWM, `pcm_to_dsd` y `dma_stub` (punto de insercion para AXI/MicroBlaze). |
| `src/rtl/top` | Integracion `nexys_audio_top`. |
| `tb/` | Testbenches por modulo + TB de integracion. |
| `sim/filelist.f` | Manifiesto para Icarus (se usa desde el `Makefile`). |
| `docs/` | Arquitectura, plan de verificacion y guia de salida DSD (`pcm_to_dsd_nexys.md`). |
| `scripts/run_iverilog.sh` | Wrapper para lanzar `make run` con cualquier TB. |

## Flujo recomendado

1. **Configurar entorno** - Instala `iverilog`, `vvp` y opcionalmente `gtkwave`. Situate en `repo/DigitalDesingLR/devEnv/work/prj`.
2. **Simular un modulo** - `make run TB=tb/midi_uart_rx_tb.v`. Los artefactos (`.vvp`, `.vcd`) se guardan en `sim/build/`.
3. **Analizar ondas** - `make waves TB=tb/fm_synth_tb.v` abre GTKWave con el fichero VCD del test seleccionado.
4. **Iterar parametros** - Ajusta los presets en `param_demux` o envia nuevos bytes MIDI desde la TB de integracion (`tb/nexys_audio_top_tb.v`).
5. **Prepararse para FPGA** - Sustituye `dma_stub` por un AXI-DMA/MicroBlaze, conecta `audio_pwm_p/n` al amplificador de la Nexys y filtra con un LPF <20 kHz. Para la ruta alternativa DSD, usa `pcm_to_dsd` y lleva `dsd_bit` al PMOD JA1 (H17) con filtro RC.

## Documentacion

- `docs/architecture.md` resume la particion Entry/Core/Output e incluye el diagrama de bloques en formato Mermaid.
- `docs/verification_plan.md` detalla que cubre cada testbench y los checks minimos antes de llevarlo a Vivado.
- `docs/pcm_to_dsd_nexys.md` describe la prueba modular DSD (pin H17 + filtro RC) partiendo del seno del zCode.

## Notas sobre implementacion

- Los incrementos DDS por defecto generan ~432 Hz usando un reloj de 100 MHz. Cambia `CLK_FREQ_HZ` en `nexys_audio_top` y `midi_uart_rx` si usas otro reloj base.
- `sine_lut` carga automaticamente `sim/sine_lut_q12.mem`. Puedes regenerar la tabla con mayor resolucion y apuntar el parametro `MEM_FILE` a un BRAM inicializado.
- `fm_synth` incluye ganancia, beta y feedback firmados de 16 bits; ajusta la escala (`>> (DATA_WIDTH-2)`) si necesitas mas headroom.
- Para hardware real, sincroniza el boton de gate y desactiva el bloque PWM durante configuracion para evitar pops acusticos.

## Proximos pasos sugeridos

1. Generar un bloque AXI-Lite que permita modificar los registros de `param_demux` desde MicroBlaze o Zynq.
2. Comparar PWM vs Delta-Sigma (1 bit DSD) midiendo SNR con el filtro RC propuesto.
3. Incorporar scripts de regresion (bash o Python) que automaticen `make run` sobre todos los TBs antes de sintetizar.
