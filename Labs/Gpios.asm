#include registers.inc

                                org $2000
                   movb #$00,DDRH  ; definir el puerto H como entradas
                   movb #$FF,DDRB  ; Definir el puerto B como salidas
                   bset DDRJ,#$02  ; Colocar el enable de los leds como salida
                   bclr PTJ,#$02   ; Habilitar ENABLE de los LEDs
prender_leds       movb PTIH,PORTB ;Poner los valores de los switches a los leds
                   bra prender_leds ; Repetir
        
