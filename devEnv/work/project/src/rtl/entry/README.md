# entry DIR

## uart MIDI

deploys a delivery byte of 8 bits with parity
do this after implement a uart reciver compatible with the MIDI standard (8b, N1, 31250 baud rate)

objective : converts a serial MIDI stream (RX) into 8-BIT parallel data with a validity pulse (define if its a valid )
reloj divido para entrada rx y tx (con el fin de esperar si está listo)

the ready output from uart, is the enable for the DEMUX

## param DEMUX

### range management for parameters:

table for manage

frequency -> exponencial

other -> lineal

## knob param decoder
