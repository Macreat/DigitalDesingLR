# PCM -> DSD en Nexys Video (PMOD JA H17)

## Objetivo

Sacar `pcm_sample` de 24 bits (seno del zCode) como flujo DSD de 1 bit a ~3.125 MHz, apto para un pin de 3.3 V. Se filtra con RC y se envia a un bafle autoamplificado.

## Pipeline propuesto

1. Fuente PCM: `sine_wave_ob` (zCode) produce `pcm_sample[23:0]` a ~48.8 kHz (OSR=64).
2. Modulador: `pcm_to_dsd` usa `clk100`, divide a 3.125 MHz (`DSD_FREQ_HZ`) y aplica Delta-Sigma de segundo orden. Entregas: `dsd_bit`, `dsd_ce` (strobe) y `pcm_ready`.
3. Pin fisico: `dsd_bit` -> PMOD JA1 (H17) como salida `LVCMOS33`.
4. Filtro analogico: RC sencillo (ej. R=6.8k, C=1 nF, fc ~23 kHz) hacia el bafle autoamplificado.

## Handshake y parametros

- `pcm_ready`: pulso de 1 ciclo cada 64 bits DSD; coloca nueva muestra con `pcm_valid=1` y `pcm_sample` estable.
- `dsd_ce`: pulso cada bit (3.125 MHz con `CLK_FREQ_HZ=100 MHz`, divisor 32).
- `DSD_FREQ_HZ` y `OSR` son parametros del RTL; usa el MMCM si quieres 3.072 MHz exactos (DSD64 con 48 kHz).

## Integracion RTL minima

```verilog
wire        dsd_bit;
wire        dsd_ce;
wire        pcm_ready;
pcm_to_dsd #(
    .SAMPLE_WIDTH(24),
    .CLK_FREQ_HZ (100_000_000),
    .DSD_FREQ_HZ (3_125_000),
    .OSR         (64)
) dsd_out (
    .clk       (clk100),
    .rst       (rst),
    .pcm_sample(pcm_sample_24b),
    .pcm_valid (pcm_valid),
    .pcm_ready (pcm_ready),
    .dsd_bit   (dsd_bit),
    .dsd_ce    (dsd_ce)
);
```

- Si partes del `fm_synth` (16 bits), extiende a 24 bits: `pcm_sample_24b = {synth_sample, 8'd0}`.
- Conecta `pcm_ready` a la logica que actualiza el seno del zCode o el sintetizador.

## Asignacion de pin (XDC)

```tcl
set_property PACKAGE_PIN H17 [get_ports {dsd_bit}]
set_property IOSTANDARD LVCMOS33 [get_ports {dsd_bit}]
```

- Salida single-ended; sin necesidad de pin complementario.

## Prueba rapida en simulacion

```sh
make run TB=tb/pcm_to_dsd_tb.v
```

- Observa en `sim/build/pcm_to_dsd_tb.vcd`: `dsd_ce` a ~3.125 MHz y densidad de unos/ceros siguiendo el seno.
- La primera muestra tras reset es cero; el resto sigue el tono de 1 kHz.

## Notas de laboratorio

- Manten la pista corta entre H17 y el RC para reducir EMI.
- Si el bafle satura, sube la resistencia (10k) o baja `FEEDBACK_LEVEL` en el RTL para reducir la potencia efectiva.
- Para DSD64 exacto (3.072 MHz), genera un reloj de 98.304 MHz via MMCM o ajusta `DSD_FREQ_HZ` y `CLK_FREQ_HZ` a la pareja correcta.
