 ;******************************************************************************
 ;                              MAQUINA DE TIEMPOS
 ;                                     (RTI)
 ; Leer PB: Leer el boton pulsador de PH0, Suprimir rebotes, ademas discrimina
 ; si es un Short Press o Longo Press
 ;
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
tSubRebPB         EQU 10 ; Tiempo de supresion de rebotes x 1mS
tShortP           EQU 25 ; Tiempo minimo de ShortPress x 10mS
tLongP            EQU 2  ; Tiempo minimo de LongPress x 1S
tTimerLDTst       EQU 1     ;Tiempo de parpadeo de LED testigo en segundos

PortPB            EQU PTIH  ; Puerto del Boton Pulsador
MaskPB            EQU $01   ; Boton el el puerto H.0


                                Org $1000

;Aqui se colocan las estructuras de datos de la aplicacion
Est_Pres_LeerPb ds 2 ; Estado presente de LeerPb
Banderas_PB     ds 1  ; Banderas (ShortP y LongP)


ShortP          EQU $01
LongP           EQU $02


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

Timer_RebPB:    ds 1  ; Timer de supresion de rebotes

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP:  ds 1     ; Timer de Short Press

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_100mS  ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LED_Testigo ds 1   ;Timer para parpadeo de led testigo
Timer_LP:    ds 1        ; Timer LongPress

Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000

        Bset DDRB,$81     ;Habilitacion del LED Testigo y de PB0
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
        clr Banderas_PB
        movw #LeerPB_Est1,Est_Pres_LeerPB
;===============================================================================
;                           Despachador de Tareas
;===============================================================================
Despachador_Tareas

        Jsr Tarea_Led_Testigo
        Jsr Tarea_LeerPB
        Jsr Tarea_Led_PB
        
        Bra Despachador_Tareas
;*******************************************************************************
;                            Tarea Led_PB
;*******************************************************************************
Tarea_Led_PB
            brset Banderas_PB,ShortP,ON ;si se presiona short press enceder LED
            brset Banderas_PB,LongP,OFF ;si se presiona long press  apagar LED
            bra FIN_Led
ON          bclr Banderas_PB,ShortP   ; Borrar banderas asocioadas
            bset PortB,$01            ; Ejecuta la accion
            bra FIN_Led
OFF         bclr Banderas_PB,LongP
            bclr PortB,$01
FIN_Led     rts



;******************************************************************************
;                               Tarea Leer PB
;  Metodo para la implementacion de la maquina de estados Leer_PB
; EL estado de partida se inicializa en la variable Est_Pres_LeerPB
; en el programa pricipal
; En cada estado se actualiza Est_Pres_LeerPB Cargando la dirrecion del
; proximo estado
;******************************************************************************
Tarea_LeerPB
            ldx Est_Pres_LeerPB  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
            
FinTareaPB  rts
;====================== Leer PB Estado 1 =======================================
LeerPB_Est1  brset PortPB,#MaskPB,FinPB_Est1 ; Verificar si se presiono PB
             movb #tSubRebPB,Timer_RebPB ; Si si cargar Timers
             movb #tShortP,Timer_SHP
             movb #tLongP,Timer_LP

             movw #LeerPB_Est2,Est_Pres_LeerPB ; Pasar al estado 2
FinPB_Est1   rts


;====================== Leer PB Estado 2 =======================================
LeerPB_Est2  tst Timer_RebPB   ; Verficar si ya cumplio el tiempo de rebotes
             bne FinPB_Est2
             brset PortPB,#MaskPB,Volver_Est1 ; Verificar si sigue presionado
             movw #LeerPB_Est3,Est_Pres_LeerPB ; si si pasar al estado 3
             bra FinPB_Est2
Volver_Est1  movw #LeerPB_Est1,Est_Pres_LeerPB; Si no volver al estado 1
FinPB_Est2   rts


;====================== Leer PB Estado 3 =======================================
LeerPB_Est3  tst Timer_SHP ; Verificar el tiempo de Short Press
             bne FinPB_Est3
             brset PortPB,#MaskPB,Volv_Est1 ; Verificar si sigue presionado
             movw #LeerPB_Est4,Est_Pres_LeerPB ; si es asi pasar al estado 4
             bra FinPB_Est3
Volv_Est1    bset Banderas_PB,ShortP ; Si no Poner ShortPress y volver a estado1
             movw #LeerPB_Est1,Est_Pres_LeerPB
FinPB_Est3   rts


;====================== Leer PB Estado 4 =======================================
LeerPB_Est4  tst Timer_LP ; Verificar el tiempo Long Press
             bne Revisar_PB ; si se cumplió
             brclr PortPB,#MaskPB,FinPB_Est4 ; ver si sigue presionado
             bset Banderas_PB,LongP ; Poner LongPress
             Bra Reg_Est1
Revisar_PB   brclr PortPB,#MaskPB,FinPB_Est4; si no se cumpplio ver si sigue prs
             bset Banderas_PB,ShortP; Si no poner ShortPress
Reg_Est1     movw #LeerPB_Est1,Est_Pres_LeerPB  ; Volver al estado 1
FinPB_Est4   rts



;******************************************************************************
;                               TAREA LED TESTIGO
;******************************************************************************

Tarea_Led_Testigo
                Tst Timer_LED_Testigo  ; Verificar si se cumplió el tiempo
                Bne FinLedTest
                Movb #tTimerLDTst,Timer_LED_Testigo; si si recargar el timer
                Ldaa PORTB  ; Cargar el estado de PortB
                Eora #$80   ; Hacer Toggle
                Staa PORTB  ; Volver a escribir
FinLedTest      Rts

;******************************************************************************
;                       SUBRUTINA DE ATENCION A RTI
;******************************************************************************

Maquina_Tiempos:
                ldx #Tabla_Timers_BaseT ; Cargar la tabla de timers
                jsr Decre_Timers_BaseT ; disminuir los timers
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
