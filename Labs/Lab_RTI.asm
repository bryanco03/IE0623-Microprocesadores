#include registers.inc

;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
                                org $1000
Leds                    ds 1
cont_rti                ds 1


RTI_vec                 equ $3E70

;*******************************************************************************
;                 Reubicar el vector de Interrupciones
;*******************************************************************************
                             org RTI_vec
                        dw  RTI_ISR

;*******************************************************************************
;                             Configuracion del Hardware
;*******************************************************************************
                              org $2000
                        movb #$FF,DDRB ; Configurar los Leds como salidas
                        bset DDRJ,#$02
                        bclr PTJ,#$02  ; Habilitar los Leds
                        
                        movb #$0F,DDRP
                        movb #$0F,PTP  ; Apagar los Displays
                        
                        bset CRGINT,#$80 ; Habilitar el RTI
                        movb #$17,RTICTL ; Configurar ticks cada  1 ms
                        

;*******************************************************************************
;                          Programa Principal
;*******************************************************************************
                       lds #$3BFF  ; Inicializar la pila
                       cli         ; Habilitar las interrupciones mascarables
                       movb #$01, Leds
                       movb #250, cont_rti
                       
                       bra *
;*******************************************************************************
;                     Interrupcion RTI
;*******************************************************************************

RTI_ISR               bset CRGFLG,#$80
                      dec cont_rti
                      bne fin
                      movb #250,cont_rti
                      movb Leds,PORTB
                      ldaa Leds
                      cmpa #$80
                      beq fin_led
                      lsl Leds
                      bra fin
fin_led               movb #$01,Leds
fin                   rti
                        
                        
                        



