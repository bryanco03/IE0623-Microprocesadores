#include registers.inc

;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
                                org $1000
Leds                    ds 1


PTH_vec                 equ $3E4C

;*******************************************************************************
;                 Reubicar el vector de Interrupciones
;*******************************************************************************
                             org PTH_vec
                        dw  PTH_ISR

;**********************************************************-*********************
;                             Configuracion del Hardware
;*******************************************************************************
                              org $2000
                        movb #$FF,DDRB ; Configurar los Leds como salidas
                        bset DDRJ,#$02
                        bclr PTJ,#$02  ; Habilitar los Leds

                        movb #$0F,DDRP
                        movb #$0F,PTP  ; Apagar los Displays

                        bset PIEH,$01
                        bset PPSH,$00


;*******************************************************************************
;                          Programa Principal
;*******************************************************************************
                       lds #$3BFF  ; Inicializar la pila
                       cli         ; Habilitar las interrupciones mascarables
                       movb #$01, Leds


                       bra *
;*******************************************************************************
;                     Interrupcion OC5
;*******************************************************************************

PTH_ISR               bset PIFH,$01
                      movb Leds,PORTB
                      ldaa Leds
                      cmpa #$80
                      beq fin_led
                      lsl Leds
                      bra fin
fin_led               movb #$01,Leds
fin                      rti