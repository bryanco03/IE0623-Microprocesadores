#include registers.inc

;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
                                org $1000
Leds                    ds 1
cont_toi                ds 1


TOI_vec                 equ $3E5E

;*******************************************************************************
;                 Reubicar el vector de Interrupciones
;*******************************************************************************
                             org TOI_vec
                        dw  TOI_ISR

;*******************************************************************************
;                             Configuracion del Hardware
;*******************************************************************************
                              org $2000
                        movb #$FF,DDRB ; Configurar los Leds como salidas
                        bset DDRJ,#$02
                        bclr PTJ,#$02  ; Habilitar los Leds

                        movb #$0F,DDRP
                        movb #$0F,PTP  ; Apagar los Displays

                        movb #$80,TSCR1
                        movb #$82,TSCR2


;*******************************************************************************
;                          Programa Principal
;*******************************************************************************
                       lds #$3BFF  ; Inicializar la pila
                       cli         ; Habilitar las interrupciones mascarables
                       movb #$01, Leds
                       movb #25, cont_toi

                       bra *
;*******************************************************************************
;                     Interrupcion TOI
;*******************************************************************************

TOI_ISR               bset TFLG2,#$80
                      dec cont_toi
                      bne fin
                      movb #25,cont_toi
                      movb Leds,PORTB
                      ldaa Leds
                      cmpa #$80
                      beq fin_led
                      lsl Leds
                      bra fin
fin_led               movb #$01,Leds
fin                   rti



