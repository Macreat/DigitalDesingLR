# Guía rápida de verificación

Este README resume los pasos necesarios para arrancar la verificación del sistema digital descrito en `designReq.md`, utilizando el flujo de simulación que se preparó para Icarus Verilog.

## 1. Preparar el entorno

- Requisitos: `iverilog`, `vvp`, `gtkwave` (opcional) instalados en el PATH.
- Ubicación de trabajo: `repo/DigitalDesingLR/devEnv/work/prj`.
- (Opcional) exporta `IVERILOG`, `VVP` o `GTKWAVE` si usas rutas personalizadas.

```bash
cd repo/DigitalDesingLR/devEnv/work/prj
make clean        # limpia artefactos previos
```

## 2. Seleccionar el testbench

Los bancos de pruebas disponibles se encuentran en `tb/`:

| Testbench | Cobertura |
| --- | --- |
| `tb/midi_uart_rx_tb.v` | UART/MIDI + sincronización de datos de entrada. |
| `tb/fm_synth_tb.v` | Núcleo FM completo (DDS, LUT, ADSR). |
| `tb/pwm_audio_out_tb.v` | Conversión PWM para la etapa de salida. |
| `tb/nexys_audio_top_tb.v` | Integración Entry → Core → Output. |

Para apuntar a uno en específico define la variable `TB` al invocar `make run`.

## 3. Compilar y ejecutar

```bash
make run TB=tb/fm_synth_tb.v
```

- Compila todas las fuentes listadas en `sim/filelist.f` + el TB seleccionado.
- Los binarios `.vvp` y trazas `.vcd` se almacenan en `sim/build/`.

También puedes usar el wrapper:

```bash
scripts/run_iverilog.sh tb/fm_synth_tb.v
```

## 4. Revisar formas de onda

```bash
make waves TB=tb/fm_synth_tb.v
```

- Abre GTKWave con el archivo `sim/build/fm_synth_tb.vcd`.
- Si usas otro visor, abre manualmente el `.vcd` correspondiente.

## 5. Interpretar resultados

1. Verifica que los avisos de Icarus sean los esperados (por ejemplo, sensibilidad completa de `sine_lut`).
2. En los TB modulares, revisa señales internas (`data_valid`, `phase_inc`, `env_level`, etc.).
3. En el TB de integración, confirma actividad en `audio_pwm_p/n` tras los comandos MIDI simulados.

## 6. Extender la verificación

- Ajusta parámetros en `tb/*.v` o usa `param_demux` para enviar nuevas combinaciones.
- Añade nuevas pruebas siguiendo el formato existente y ejecútalas con `make run TB=<nuevo_tb>`.
- Para regresiones rápidas, crea un script que invoque `make run` para cada TB y detenga al primer fallo (`set -e`).

## Recursos adicionales

- `docs/architecture.md`: descripción Entry/Core/Output y diagrama de bloques.
- `docs/verification_plan.md`: objetivos específicos por testbench y métricas sugeridas.

Sigue estos pasos para iniciar la verificación desde cero y asegurar que cada bloque cumpla los requisitos antes de migrar el diseño a Vivado/Nexys Video A7.
