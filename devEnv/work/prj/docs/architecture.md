# Arquitectura propuesta

## Visión general

El proyecto se divide en tres dominios lógicos alineados con el documento `designReq.md`:

1. **Entry / Control** – Captura serial MIDI (31.25 kbaud), filtra los bytes relevantes provenientes de knobs/controles y distribuye los parámetros sobre registros dedicados mediante un demultiplexor.
2. **Core de síntesis** – Implementa un oscilador DDS dual (carrier/modulador), tabla senoidal con cuantización Q1.15, la cadena FM (beta/feedback) y un generador de envolvente exponencial sencillo (ATA/DECAY/SUSTAIN).
3. **Output / DSD** – Convierte las muestras firmadas a PWM (1 bit) compatible con el amplificador clase D de la Nexys Video A7 y expone un stub de DMA listo para reemplazarse por un AXI-DMA/MicroBlaze.

## Diagrama de bloques (alto nivel)

```mermaid
graph TD
    MIDI[MIDI UART RX<br>midi_uart_rx] --> DEC(knob_param_decoder)
    DEC --> DMX[param_demux]
    DMX -->|phase_inc_base| CORE
    DMX -->|phase_inc_mod| CORE
    DMX -->|beta/feedback/gain| CORE
    DMX -->|attack/decay/sustain| CORE
    CORE[FM Core<br>phase_acc + sine_lut + envelope_gen] --> DMA[dma_stub]
    CORE --> PWM[pwm_audio_out]
    DMA --> MEM[(AXI/Mem)]
    PWM --> AMP[Clase D + LPF]
```

## Señales clave por bloque

| Bloque | Entradas principales | Salidas principales | Comentarios |
| --- | --- | --- | --- |
| `midi_uart_rx` | `clk100`, `rst`, `midi_rx` | `data_out[7:0]`, `data_valid` | Ajustar `CLK_FREQ_HZ` si se usa otro reloj. |
| `knob_param_decoder` | `midi_data`, `midi_valid` | `param_addr`, `param_value`, `param_valid` | Usa bits `[6:4]` como selector (hasta 8 parámetros simultáneos). |
| `param_demux` | `param_addr/value/valid` | `phase_inc_base/mod`, `beta`, `gain`, `feedback`, `attack`, `sustain`, `decay`, `timbre_sel` | Contiene presets por defecto (432 Hz). |
| `fm_synth` | Increments + ADSR + `gate` | `sample[15:0]`, `sample_valid` | Combina `phase_accumulator`, `sine_lut`, `envelope_gen`. |
| `pwm_audio_out` | `sample[15:0]`, `clk` | `audio_pwm_p/n` | Modulación de ancho de pulso unipolar; agregar filtro LC externo. |
| `dma_stub` | `sample`, `sample_valid` | `last_written`, `ready` | Punto de inserción para AXI-DMA + MicroBlaze. |

## Consideraciones para Nexys Video A7

- Reloj: utilice el oscilador de 100 MHz (`clk100`). Si se activa el MMCM interno, actualice `CLK_FREQ_HZ`.
- Audio out: el módulo `pwm_audio_out` produce dos señales complementarias para el **Amplificador Clase D** integrado. Añada un filtro pasabajas RC/LC con corte <20 kHz (como exige el documento original).
- MicroBlaze / AXI: `dma_stub` se dejó minimalista para que pueda reemplazarse por un bloque AXI-Stream conectado a un MicroBlaze (C/SDK) que configure registros vía AXI-Lite o UART externo.

## Integración futura

1. Sustituir `dma_stub` por un DMA real con acceso a DDR/BRAM usando Vivado IP Integrator.
2. Añadir una LUT exponencial real (o CORDIC) si se requiere la forma envolvente descrita (`e^{-t/τ}`) en hardware.
3. Implementar un bloque de interpolación en `sine_lut` (o ampliar la profundidad a 1024 muestras) para reducir distorsión al reproducir 500 canales virtuales.
4. Conectar los botones/knobs físicos de la Nexys vía interfaz PMOD o el MIDI-USB de un MicroBlaze auxiliar como describe el requisito original.
