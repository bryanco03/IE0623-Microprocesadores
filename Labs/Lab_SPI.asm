#include registers.inc

;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
                                org $1000
Leds                    ds 1
cont_DA                 ds 2
comparador              ds 1


RTI_vec                 equ $3E70
ATD0_vec                equ $3E52

;*******************************************************************************
;                 Reubicar el vector de Interrupciones
;*******************************************************************************
                             org RTI_vec
                        dw  RTI_ISR
                             org ATD0_vec
                        dw  ATD0_ISR
;*******************************************************************************
;                             Configuracion del Hardware
;*******************************************************************************
                              org $2000
                              
                        movb #$49,RTICTL ; Configurar ticks cada  10 ms
                        movb #$80,CRGINT ; Habilitar el RTI
                        
                        movb #$FF,DDRB ; Configurar los Leds como salidas
                        movb #$00,PortB
                        bset DDRJ,$02
                        bclr PTJ,$02  ; Habilitar los Leds
                        movb #$0F,DDRP
                        movb #$0F,PTP  ; Apagar los Displays
                        
                        movb #$C2,ATD0CTL2
                        ldaa #160
Espere                  dbne a,Espere
                        
                        movb #$08,ATD0CTL3
                        movb #$97,ATD0CTL4
                        
                        
                        movb #$50,SPI0CR1
                        movb #$00,SPI0CR2
                        movb #$45,SPI0BR
                        
                        bset DDRM,$40
                        bset PTM,$40
                        
                        lds #$3BFF
                        cli
                        movb #32,comparador
                        movb #$01,Leds
                        movw #$0,Cont_DA

                        bra *
;*******************************************************************************
;                     Interrupcion RTI
;*******************************************************************************

RTI_ISR               ldx Cont_DA
                      inx
                      stx Cont_Da
                      cpx #1024
                      bne Manda_SS
                      movw #$0,Cont_DA
Manda_SS              bclr PTM,$40
Esperar_1
                      brclr SPI0SR,$20,Esperar_1
                      ldd Cont_DA
                      lsld
                      lsld
                      
                      anda #$0F
                      adda #$90
                      staa SPI0DR

Esperar_2
                      brclr SPI0SR,$20,Esperar_2
                      stab SPI0DR

Esperar_3
                      brclr SPI0SR,$20,Esperar_3
                      bset PTM,$40
                      bset CRGFLG,#$80
                      movb #$86,ATD0CTL5

                      rti
;*******************************************************************************
;                     Interrupcion ATD0
;*******************************************************************************
ATD0_ISR
                     ldd ADR00H
                     
                     cmpb #31
                     blo Seguir

                     movb #$0,PortB
                     movb #31,comparador
                     movb #$01,Leds

Seguir
                     cmpb comparador
                     
                     blo Fin_ATD0_ISR
                     movb Leds,PortB
                     
                     staa comparador
                     adda #3
                     staa comparador
                     
                     ldaa Leds
                     lsla
                     oraa Leds
                     staa Leds
                     


Fin_ATD0_ISR         rti