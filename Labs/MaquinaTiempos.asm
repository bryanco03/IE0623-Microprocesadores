 ;******************************************************************************
 ;                              MAQUINA DE TIEMPOS
 ;                                     (RTI)
 ;******************************************************************************
#include registers.inc
 ;******************************************************************************
 ;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
 ;******************************************************************************
                                Org $3E70
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

;--- Aqui se colocan los valores de carga para los timers baseT  ----

tTimer1mS:        EQU 1     ;Base de tiempo de 1 mS (1 ms x 1)
tTimer10mS:       EQU 10    ;Base de tiempo de 10 mS (1 mS x 10)
tTimer100mS:      EQU 100    ;Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:         EQU 1000    ;Base de tiempo de 1 segundo (100 mS x 10)

;--- Aqui se colocan los valores de carga para los timers de la aplicacion  ----


tTimerLDTst       EQU 1     ;Tiempo de parpadeo de LED testigo en segundos


                                Org $1000

;Aqui se colocan las estructuras de datos de la aplicacion
                                
;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1040
Tabla_Timers_BaseT:

Timer1mS        ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS

Timer1_Base1:   ds 1       ;Ejemplos de timers de aplicacion con BaseT
Timer2_Base1:   ds 1

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer1_Base10:  ds 1       ;Ejemplos de timers de aplicacion con base 10 mS
Timer2_Base10:  ds 1

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS
Timer1_Base100  ds 1       ;Ejemplos de timers de aplicacpon con base 100 mS
Timer2_Base100  ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S
Timer_LED_Testigo ds 1   ;Timer para parpadeo de led testigo
Timer1_Base1S:    ds 1   ;Ejemplos de timers de aplicacion con base 1 seg.
Timer2_Base1S:    ds 1

Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000

        Bset DDRB,$80     ;Habilitacion del LED Testigo
        Bset DDRJ,$02     ;como comprobacion del timer de 1 segundo
        BClr PTJ,$02      ;haciendo toogle
        
        Movb #$0F,DDRP    ;bloquea los display de 7 Segmentos
        Movb #$0F,PTP
        
        Movb #$17,RTICTL   ;Se configura RTI con un periodo de 1 mS
        Bset CRGINT,$80
;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS         ;Inicia los timers de bases de tiempo
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S
        
        Movb #tTimerLDTst,Timer_LED_Testigo  ;inicia timer parpadeo led testigo
        Lds #$3BFF
        Cli
Despachador_Tareas

        Jsr Tarea_Led_Testigo
       ; Aqui se colocan todas las tareas del programa de aplicacion
        Bra Despachador_Tareas
       
;******************************************************************************
;                               TAREA LED TESTIGO
;******************************************************************************

Tarea_Led_Testigo
                Tst Timer_LED_Testigo
                Bne FinLedTest
                Movb #tTimerLDTst,Timer_LED_Testigo
                Ldaa PORTB
                Eora #$80
                Staa PORTB
FinLedTest
      Rts

;******************************************************************************
;                       SUBRUTINA DE ATENCION A RTI
;******************************************************************************

Maquina_Tiempos:
                ldx #Tabla_Timers_BaseT
                jsr Decre_Timers_BaseT
                ldd Timer1mS
                cpd #$0000
                bne Timer_10ms
                movw #tTimer1mS,Timer1mS
                ldx #Tabla_Timers_Base1mS
                jsr Decre_Timers
Timer_10ms      ldd Timer10mS
                cpd #$0000
                bne Timer_100ms
                movw #tTimer10mS,Timer10mS
                ldx #Tabla_Timers_Base10mS
                jsr Decre_Timers
Timer_100ms     ldd Timer100mS
                cpd #$0000
                bne Timer_1s
                movw #tTimer100mS,Timer100mS
                ldx #Tabla_Timers_Base100mS
                jsr Decre_Timers
Timer_1S        ldd Timer1S
                cpd #$0000
                bne Fin
                movw #tTimer1S,Timer1S
                ldx #Tabla_Timers_Base1S
                jsr Decre_Timers
Fin             bset CRGFLG,#$80

                RTI
;******************************************************************************
;                       SUBRUTINA DECRE_Timers_BaseT
;******************************************************************************
Decre_Timers_BaseT
                  ldy 2,x+
                  beq Decre_Timers_BaseT
                  cpy #$FFFF
                  beq Fin_Decre_BaseT
                  dey
                  sty -2,x
                  bra Decre_Timers_BaseT
Fin_Decre_BaseT   rts
;******************************************************************************
;                       SUBRUTINA DECRE_Timers
;******************************************************************************
Decre_Timers
              tst 0,x
              bne Fin_tabla
Pasar         inx
              bra Decre_Timers
Fin_Tabla     ldaa 0,x
              cmpa #$FF
              beq Fin_Decre
              dec 0,x
              bra Pasar
Fin_Decre     rts
              
              
