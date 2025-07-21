#include registers.inc

;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
                                org $1000
Leds                    ds 1
cont_oc                ds 1


OC5_vec                 equ $3E64

;*******************************************************************************
;                 Reubicar el vector de Interrupciones
;*******************************************************************************
                             org OC5_vec
                        dw  OC5_ISR

;*******************************************************************************
;                             Configuracion del Hardware
;*******************************************************************************
                              org $2000
                        movb #$FF,DDRB ; Configurar los Leds como salidas
                        bset DDRJ,#$02
                        bclr PTJ,#$02  ; Habilitar los Leds

                        movb #$0F,DDRP
                        movb #$0F,PTP  ; Apagar los Displays

                        movb #$90,TSCR1
                        movb #$04,TSCR2
                        movb #$20,TIOS
                        movb #$20,TIE
                        movb #$04,TCTL1
                        
                        ldd TCNT
                        addd #1500
                        std TC5
                        
                        


;*******************************************************************************
;                          Programa Principal
;*******************************************************************************
                       lds #$3BFF  ; Inicializar la pila
                       cli         ; Habilitar las interrupciones mascarables
                       movb #$01, Leds
                       movb #25, cont_oc

                       bra *
;*******************************************************************************
;                     Interrupcion OC5
;*******************************************************************************

OC5_ISR
                      dec cont_oc
                      bne fin
                      movb #25,cont_oc
                      movb Leds,PORTB
                      ldaa Leds
                      cmpa #$80
                      beq fin_led
                      lsl Leds
                      bra fin
fin_led               movb #$01,Leds
fin                   ldd TCNT
                      addd #1500
                      std TC5
		      rti
