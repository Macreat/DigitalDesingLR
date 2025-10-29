# design prj requirements output

1. seno envolvente Genrador exponencial (porqué no puede recibir el timepo (t) el modelo e^at) (100-300 fp flops-500 canales with the nexys) y generador senusoidal
   1.1. seno de la armonica (generate sine but doesnth change with parameters of entry)
   1.2 432 hz output (obtain audio output ) -\_ design : with the clock y con el armonico entre posiciones de la tabla

algortimo de cordick - o tavlas debusqueda con interpolacion

---

for modules :

# entry

the parameters to sintetize the audio are produce by the MIDI using the KNOBS

given the MIDI input (each bottom or knob bit for 128 cases (8 bits)), WE Process this UART input and got 4 inputs bytes from 8 bits each one to process the parameters for each combination

, this inputs goes to a DMUX, then five outputs got the parameters for sintetization (base freq, mod freq, beta and decay)

(see parallel and series protocols)

# core

the output for this module is given by : the mathematical model for the signal sintetized, ONCe WE got the OUTPUT given by the DMUX, this inputs are:

FB
FM
BETA
DECAY
GAIN
and
4 bits

all of this is given and utilizables as bottoms

-

# output (DSD)

processor with DMA( direct memory access ) this in order to save and process the data obtain.

given the output , from here, we modulate the exponencial and signusoidal to reproduce a signal or audio

this input goes from a AMPLIFIR D - class , and this output goes for a low pass frequency (TO cut freq> 20KHz)

MODULATION AUDIO SIGNAL STRATEGIES:
1- ancho de pulso, obtain signal with a portrait
2-

# INR ORDER to prototype, use a micro controller, used as: MICROBLASE

this in order to configurate (a micro controller using C) and got the (bus) AXI PROTOCOL communication

ON LINUX ENVIRONMENT, this is usefull to :

- protocol of communication using ssh and then,
- using the console and UART methods, we can configurate and got some points FOR TE RASP - PI 3 MODEL B
  the amplificator D type is used to amplify the audio output
s
# verification desing for next lecture (advances ¿? )
