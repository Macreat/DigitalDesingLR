# core DIR

# diagram block

for the sen generator , i use A FSM

I/O: Inputs : start, en , angle (16 bits); outputs : sine (16bits), ready.

# module implementation

sine = [32767 <8bits> * sin (2pi Angle/ 65536<16bits>)]

onda senoidal con periodo de 65536 ; esto es una aproximación dados los 16 bits

(necesito 65536 valores, dado el ángulo, o un algoritmo para aproximar el ángulo (en radianes (this a step) ))

# sine implementation

given a LUT de 16384 posiciones (14 bits)

how can i define the states¿?

- the angle is the index in order to split our data (65536)

as : if angle <16384 : index = angle

if 16384 < angle < 32768 : index = 32768 - angle

if 32768 < angle < 49152 : index = angle - 32768; all values has a zeo on 15 and 14 bits cases

if 49152 < angle < 65536 : index = 65536 ; on this last conditional the last range can avoid ; making the last operation ; always gate operation is less expensive that mathematical methods

- first and third operation its equal to apply AND gate: as angle & 32767

- last operation its eqaul to has 15 and 14 bits activated and the 13 and 12 not

49152 : given 16 bits : 1 1 00...00.......00... ( first element of range )
GIVEN the 14 bits LUT table:
-only actived the 14 first bits (1)
49153 its the same but the first bit its on high

on last range : 65536 gives the 16 bits activated and
negated : only active the 2 last bits

on first case: 16384, only active the bit 15, and their first element its high for 14 bits

(summarize, take the last configuration in order to denny )

index is how i select the LUT

---

first and third case : index = to angle and angle & 16383

second and last : angle[13:0] pero negado
cases :
00 -> second bit is 0 -> apply specific case
01 -> only when second bit es 1 -> apply specific case
10 -> second bit is 0 -> apply specific case
11 - > only when second bit es 1 -> apply specific case

this block got a combinational performance only seeing the 14 bit
(xOr applied)

got a entry as 16 bits( angle ) and output ( index as 14 bits)

finally got : index = dennyAngle[ 14: 0] & angle [ 13 : 0 ]

and angle[ 14 ] & dennyAngle [13 :0 ]

index goes to the LUT of 14 bits, the output generated is the sine (wh/ the negative part ) this goes to another block that gimmes the sine generated (normally considering the last two digits (the signficant bit and their ) (15 and 14) in order to define the signe )

- where impplement C 2 ¿?

what its the common problem ¿?

- size of 14 bits ( gimmes 32KB of memory )

in order to got more on time : interpolate ( w 16 bits )
in this case, the LUT14 BLOCK is reeplace for a 4bits LUT (got 15 positions ) (one for angles and another for index 0 1024-2048- ... 4096... 16384 its the limit ) < index is necessary to interpolate >

- each index manage a specific position on my LUT

# interpolation impl

given the 4Luts (15 positions) in order to interpolate...

the sine\* = (index - idx[ indexlow ]); idxlow is of 4 bits but index managed the 14 bits on my LUT
; idxLow and idx high its a range for index
i should multiply my LUT on idxhgih and idxlow like this:

= {(index - idx[ indexlow ]) _ phi(idxHigh) + (idx[ idxhigh ]- index) _ phi (idxLow)} / 1024

this output goes to antoher block, where i should manage the idxHigh and idx low, then manage into a TOP block, in order to deploy sine ¨(dividr entre 1024 implica quitar los 10 bits más signficativos), this output its interpolated

define INPUTS/ OUTPUTS

- apply a counter in order to manage better size but this manage many cycles of clock

- manage registers for a cycle of clock (manage less combinational blocks)

FSM depends more on CYCLE clock TIMME (basis define (doesnt do anything )-> enable -> start-> (once i got a result) -> ready (output) and then on the first)

how to implement ( a combinational or sequential FSM ¿?)
