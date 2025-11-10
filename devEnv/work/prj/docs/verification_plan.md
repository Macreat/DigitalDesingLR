# Plan de verificación (Icarus Verilog)

| Módulo / Testbench        | Objetivo                                       | Estímulos                                                                | Métricas / Checks                                                                          |
| ------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| `tb/midi_uart_rx_tb.v`    | Validar la captura serie a 31.25 kbaud.        | `send_byte()` inyecta comandos `NOTE ON`, `CONTROL CHANGE`.              | `data_valid` se activa y el byte coincide con el enviado; sin `framing_error`.             |
| `tb/fm_synth_tb.v`        | Revisar operación DDS/FM + ADSR.               | Se usan incrementos por defecto (432 Hz) y variaciones de `gate`/`beta`. | Señal `sample` oscila y cambia cuando se reduce `beta`. Se revisa `sample_valid` continuo. |
| `tb/pwm_audio_out_tb.v`   | Confirmar conversión PWM y excursión completa. | Barrido de `sample` desde -32768 a +32767.                               | El duty cycle aumenta monotónicamente; `pwm_out_n` complementa a `pwm_out_p`.              |
| `tb/nexys_audio_top_tb.v` | Integración completa (entry → core → output).  | Secuencia MIDI simple + `gate_button`.                                   | Se observa actividad en `audio_pwm_p` tras configurar parámetros.                          |

## Flujo sugerido

1. **Compilación** – `make run TB=tb/midi_uart_rx_tb.v` para cada banco de pruebas (o usar `scripts/run_iverilog.sh`).
2. **Exploración de formas de onda** – `make waves TB=tb/fm_synth_tb.v` abre GTKWave con el `VCD` generado en `sim/build/`.
3. **Cobertura funcional manual** – revise que los knobs mapeen correctamente (`param_addr`) y que los registros se actualicen (`update_pulse`).
4. **Regresión ligera** – cree un script de shell que invoque `make run` para todos los TBs y reporte el primer fallo (`set -e`).

## Puntos a monitorear en la FPGA

- **Timing**: fija `create_clock` de 100 MHz y revise violaciones al instanciar MicroBlaze o DMA reales.
- **Consumo de LUT/BRAM**: `sine_lut` puede migrarse a BRAM mediante `readmemh` + inferencia (`(* rom_style="block" *)`).
- **Ruido de conmutación**: el PWM a 100 MHz puede requerir dividir el reloj o añadir dithering para evitar EMI; ajustar `PWM_COUNTER_WIDTH`.
- **Interfaz MIDI**: añada sincronizadores adicionales o un filtro de glitch en `midi_rx` si el conector DIN se cablea externamente.
