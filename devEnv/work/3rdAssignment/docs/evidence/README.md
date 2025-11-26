# evidence DIR

dir to archive simulation evidence and ss's of GTKwave software for previous documentation and verification

## simulations compiled :

tb to proof
:

### complete uart_rx_tb with UART generator:

![uart rx TB ](uartRXGTKWave.png)

        start_pulse → 1-cycle pulse at each start bit.

        rx_valid → 1-cycle pulse once per byte.

        rx_byte → shows 0x41, then 0x7A.

        framing_error → always 0 unless you intentionally corrupt stop bit.

### uart_tx_tb con checker de bits.
![uart tx TB ](uartTXGTKWave.png)
        tx_start → 1-cycle pulse

        tx_accept → 1-cycle pulse

        tx_ready → goes low during transmission

        Correct UART frame on the tx line every 8680 ns per bit.



### cmd_parser_tb sin UART (solo bytes).

For "DC45\n":

        duty_percent = 45

        TX output = "OK\n"

        For "STATUS\n":

        TX sends the full "FREQ=xxxxxHZ,DC=yy%\n" string.

### pwm_core_tb con medición de periodo.

        Base frequency 50 kHz → 20 µs period.

        With pow2 = 1, period doubles.

        With pow5 = 1, period ×5.

        PWM duty clearly changes as duty_percent.

### top_pwm_uart_tb para probar el sistema completo.

        UART_RX correctly receives typed bytes.

        Parser changes:

        duty_percent_o → 30

        pow2_o → 3

        UART_TX sends "OK\n" correctly.

        PWM output:

        New frequency matches expected calculation.

        dbg_tx_byte captures all outgoing TX bytes.

---

✅ 1. Compilar un testbench

La regla general es:

iverilog -o <output_sim> <tb_file> <rtl_files...>
vvp <output_sim>
gtkwave <dumpfile.vcd>


El dumpfile es el que pusiste en el testbench con:

$dumpfile("xxxx.vcd");

✅ 2. Compilación por testbench (comandos ya listos)
A) uart_rx_tb
iverilog -o uart_rx_tb_sim \
  uart_rx_tb.v uart_rx.v

vvp uart_rx_tb_sim
gtkwave uart_rx_tb.vcd &

B) uart_tx_tb
iverilog -o uart_tx_tb_sim \
  uart_tx_tb.v uart_tx.v

vvp uart_tx_tb_sim
gtkwave uart_tx_tb.vcd &

C) cmd_parser_tb

(no necesita módulo UART)

iverilog -o cmd_parser_tb_sim \
  cmd_parser_tb.v cmd_parser.v

vvp cmd_parser_tb_sim
gtkwave cmd_parser_tb.vcd &

D) pwm_core_tb
iverilog -o pwm_core_tb_sim \
  pwm_core_tb.v pwm_core.v pwm_divider.v

vvp pwm_core_tb_sim
gtkwave pwm_core_tb.vcd &


(Incluí pwm_divider.v solo si tu versión interna del pwm_core lo requiere.)

E) top_pwm_uart_tb

Aquí debes incluir todos los módulos:

iverilog -o top_pwm_uart_tb_sim \
  top_pwm_uart_tb.v \
  top_pwm_uart.v \
  uart_rx.v \
  uart_tx.v \
  cmd_parser.v \
  pwm_core.v \
  pwm_divider.v

vvp top_pwm_uart_tb_sim
gtkwave top_pwm_uart_tb.vcd &

✅ 3. ¿Qué señales observar en GTKWave?
uart_rx_tb

rx

start_pulse

rx_valid

rx_byte

framing_error

Debes ver:

Pulso de inicio → start_pulse = 1

Pulso valid → rx_valid = 1

rx_byte mostrando el valor recibido

uart_tx_tb

tx_start, tx_accept, tx_ready

tx

bit_idx

shreg

Debes ver:

tx_start → 1 pulso

tx ejecutando el frame start + 8 bits + stop cada 8680 ns

cmd_parser_tb

rx_byte, rx_valid

duty_percent, pow2, pow5

tx_byte, tx_start

resp_idx

eostr_flag

Debes ver:

Cambios de parámetros cuando envías "DC45\n"

TX respuesta "OK\n"

Para "STATUS\n" → FREQ=xxxxxHZ,DC=yy%

pwm_core_tb

pwm_out

period_count

duty_percent_in

pow2, pow5

Debes ver:

Periodo cambiando según pow2/pow5

Duty computado correctamente

top_pwm_uart_tb

uart_rx_i y uart_tx_o

duty_percent_o, pow2_o, pow5_o

dbg_tx_byte

pwm_o

Debes ver:

Cambios globales al enviar "DC30\n" o "POW23\n"

pwm_o modificando su frecuencia/duty

dbg_tx_byte mostrando cada byte enviado por TX