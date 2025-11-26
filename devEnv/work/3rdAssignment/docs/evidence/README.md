# evidence DIR

dir to archive simulation evidence and ss's of GTKwave software for previous documentation and verification

## simulations compiled :

test benchs designed to proof system modularity.

### complete uart_rx_tb with UART generator:

![uart rx TB ](uartRXGTKWave.png)

        start_pulse → 1-cycle pulse at each start bit.

        rx_valid → 1-cycle pulse once per byte.

        rx_byte → shows 0x41, then 0x7A.

        framing_error → always 0 unless you intentionally corrupt stop bit.

### uart_tx_tb with bit checker

![uart tx TB ](uartTXGTKWave.png)

        tx_start → 1-cycle pulse

        tx_accept → 1-cycle pulse

        tx_ready → goes low during transmission

        Correct UART frame on the tx line every 8680 ns per bit.

### uart loopback

![uart loop back](uartloopBackGTKWave.png)

        The transmitter generates correct UART frames (start, 8 data bits, stop) with stable timing and no interruptions.

        The receiver successfully decodes both transmitted bytes (0x41 and 0x7A) and asserts rx_valid at the expected moments.

        No framing errors or data loss are observed, indicating the TX→RX loopback is fully functional.

### pwm_core_tb with period sense :

![pwm core ](pwmCoreGTKWave.png)

        Base frequency 50 kHz → 20 µs period.

        With pow2 = 1, period doubles.

        With pow5 = 1, period ×5.

        PWM duty clearly changes as duty_percent.

### top_pwm_uart_tb to proof complete system

---
