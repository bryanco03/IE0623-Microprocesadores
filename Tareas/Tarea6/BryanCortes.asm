;*******************************************************************************
;                     Tarea 6
; autor Bryan Cortés Espinola
; version : 1.0
;*******************************************************************************
#include registers.inc
 ;******************************************************************************
 ;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
 ;******************************************************************************
                                Org $3E66
                                dw Maquina_Tiempos

;*******************************************************************************
;                Estructura de datos
;*******************************************************************************

CR:       EQU $0D
LF:       EQU $0A
EOM:      EQU $FF

Carga_TC4 EQU 30

MaskRele         EQU $04
PortRele         EQU PORTE

tTimer1mS:        EQU 50      ; Base de tiempo de 1 mS (1 ms x 1)
tTimer10mS:       EQU 500     ; Base de tiempo de 10 mS (1 mS x 10)
tTimer100mS:      EQU 5000    ; Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:         EQU 50000   ; Base de tiempo de 1 segundo (100 mS x 10)

tTimerATD         EQU 5
tTimerTerminal    EQU 1
tTimer5s          EQU 5


SCF               EQU $80


;*******************************************************************************
;                Estructura de datos
;*******************************************************************************
                org $1000
Puntero      ds 2
Puntero_2    ds 2
Est_Pres_ATD ds 2
NivelProm    ds 2
temp         ds 2
Volumen      ds 1
Nivel        ds 1

Est_Pres_Terminal ds 2
BCD:              ds 1
Cont_BCD:         ds 1

ASCII:            ds 2


; Banderas
banderas:               ds 1
Alarm                   EQU $01
Empty                   EQU $02
.-


msg_inicial  db $0C
             fcc "     Universidad de Costa Rica"
             db CR, LF, CR, LF
             fcc "   Escuela De Ingeneria Electrica"
             db CR, LF, CR, LF
             fcc "        Microprocesadores"
             db CR, LF, CR, LF
             fcc "              IE0623"
             db CR, LF, CR, LF
msg_volumen  fcc "Volumen Calculado: "
             db EOM
             
;ASCII:       ds 2
             
             
msg_Alarma   db CR, LF, CR, LF
             fcc "Alarma: El Nivel esta Bajo"
             db EOM
             
msg_Vaciar  db CR, LF, CR, LF
             fcc "Vaciando Tanque, Bomba Apagada"
             db EOM
             

             
;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
Tabla_Timers_BaseT:
Timer1mS:       ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS


Timer2mS:       ds 1
Timer_RebPB2:   ds 1  ; Timer de supresion de rebotes para PH0
Timer_RebPB1:   ds 1  ; Timer de supresion de rebotes para PH3
Timer_RebTCL:   ds 1  ; Timer de supresion de rebotes para teclado
Timer_RebDS     ds 1
TimerDigito:    ds 1  ; Timer de digito P mux

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP2:  ds 1     ; Timer de Short Press
Timer_SHP1:  ds 1     ; Timer de Short Press
Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_100mS     ds 1
TimerATD         ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

TimerTerminal ds 1
Timer5s       ds 1
Timer_LP2:    ds 1        ; Timer LongPress
Timer_LP1:    ds 1        ; Timer LongPress
TimerError    ds 1

Fin_Base1S        dB $FF
             
             

;*******************************************************************************
;                      Configuracion del Hardware
;*******************************************************************************

                              org $2000
               ; Configuracion del SCI
                movw #39,SC1BDH
                movb #$00,SC1CR1
                movb #$08,SC1CR2
                
                ldaa SC1SR1
                movb #$00,SC1DRL
                
                
                movb #$C0,ATD0CTL2
                ldaa #160
Espere_ATD      dbne a,Espere_ATD
                movb #$20,ATD0CTL3 ; Cuatro conversiones
                movb #$10,ATD0CTL4
                ;movb #$87,ATD0CTL5
                
                bset  DDRE,$04
                bset  DDRT,$20
                bclr  PORTE,$04
                bclr  PTT,$20

                 ; Configuracion del Output Compare
                movb #Carga_TC4,TC4
                movb #$90,TSCR1 ; Prender el periferico con borrado rapido de banderas
                movb #$04,TSCR2 ; Prs  = 16
                movb #$10,TIOS ; poner el canal 4 como salida
                movb #$10,TIE  ; Habiltar interrupcion

                ldd TCNT
                addd #Carga_TC4
                std TC4

                
                Movw #tTimer1mS,Timer1mS
                Movw #tTimer10mS,Timer10mS    ;Inicia los timers de bases de tiempo
                Movw #tTimer100mS,Timer100mS
                Movw #tTimer1S,Timer1S
                
                
                movb #msg_inicial,puntero

                ldaa SC1SR1
                movb #$0C,SC1DRL
mandar_msg_inicial
                brclr SC1SR1,$80,mandar_msg_inicial
                        
                ldaa SC1SR1
                ldx Puntero
                ldaa 1,x+
                cmpa #EOM
                beq Borrar_TE
                staa SC1DRL
                stx Puntero
                bra mandar_msg_inicial
                        
Borrar_TE       bclr SC1CR2,$08

;*******************************************************************************
;                          Programa Principal
;*******************************************************************************

                        lds #$3BFF
                        cli
                        clr banderas
                        movw #ATD_Est1,Est_Pres_ATD
                        movw #Terminal_Est1,Est_Pres_Terminal

;******************************************************************************
;                          Despachador de Tareas
;******************************************************************************
Despachador_Tareas
                      jsr Tarea_ATD
                      jsr Tarea_Terminal
                      bra Despachador_Tareas
                        
;******************************************************************************
;                               TAREA ATD
;******************************************************************************
Tarea_ATD
                ldx Est_Pres_ATD
                jsr 0,x
FinATD          rts

;================================= ATD Estado 1 ================================
ATD_Est1
                movb #tTimerATD,TimerATD
                movw #ATD_Est2,Est_Pres_ATD
                ;movb #$87,ATD0CTL5
                rts
                
;================================= ATD Estado 2 ================================
ATD_Est2
                tst TimerATD
                bne Fin_ATD_Est2
                movb #$87,ATD0CTL5
                movw #ATD_Est3,Est_Pres_ATD
Fin_ATD_Est2
                rts
;================================= ATD Estado 3 ================================
ATD_Est3
                brclr ATD0STAT0,SCF,Fin_ATD_Est3
                jsr Calcula
                ldaa Volumen
                cmpa #14
                bhi No_Alarma
                bset banderas,alarm
                bset portRele,MaskRele
                bra Volv_ATD_Est1
No_Alarma
                cmpa #27
                bls Volv_ATD_Est1
                bclr banderas,alarm
                cmpa #82
                bls Volv_ATD_Est1
                bclr banderas,alarm
                bset banderas,empty
                bclr portRele,MaskRele
                
Volv_ATD_Est1
                movw #ATD_Est1,Est_Pres_ATD
Fin_ATD_Est3
                rts
                
                
;******************************************************************************
;                               TAREA TERMINAL
;******************************************************************************
Tarea_Terminal
                ldx Est_Pres_Terminal
                jsr 0,x
                rts

;============================= Terminal Estado 1================================
Terminal_Est1
                movb #tTimerTerminal,TimerTerminal
                movw #Terminal_Est2,Est_Pres_Terminal
                movw #msg_inicial,puntero
                bset SC1CR2,$08
                rts
                
;============================= Terminal Estado 2================================
Terminal_Est2
                tst TimerTerminal
                bne Fin_Terminal_Est2
                brclr SC1SR1,$80,Fin_Terminal_Est2
                ldaa SC1SR1
                ldx Puntero
                ldaa 1,x+
                cmpa #EOM
                beq msg_Volumen_envidado
                staa SC1DRL
                stx Puntero
                bra Fin_Terminal_Est2

msg_Volumen_envidado
                jsr BIN_ASCII
                ldd ASCII
                staa SC1DRL
MostrarVH       brclr SC1SR1,$80,MostrarVH
                stab SC1DRL
MostrarVL       brclr SC1SR1,$80,MostrarVL

                movw #Terminal_Est3,Est_Pres_Terminal
                movw #msg_alarma,puntero
                movw #msg_vaciar,puntero_2
Fin_Terminal_Est2
                rts
;============================= Terminal Estado 3================================
Terminal_Est3
               brclr banderas,Alarm,Verificar_vacio
               brclr SC1SR1,$80,Fin_Terminal_Est3
               ldaa SC1SR1
               ldx Puntero
               ldaa 1,x+
               cmpa #EOM
               beq Vol_Terminal_Est1
               staa SC1DRL
               stx Puntero
               bra Fin_Terminal_Est3
Verificar_vacio
               brclr banderas,empty,Vol_Terminal_Est1
               brclr SC1SR1,$80,Fin_Terminal_Est3
               ldaa SC1SR1
               ldx Puntero_2
               ldaa 1,x+
               cmpa #EOM
               beq msg_Vaciar_envidado
               staa SC1DRL
               stx Puntero_2
               bra Fin_Terminal_Est3
msg_Vaciar_envidado
               movb #tTimer5s,Timer5s
               movw #msg_inicial,puntero
               movw #Terminal_Est4,Est_Pres_Terminal
               bra Fin_Terminal_Est3

Vol_Terminal_Est1
               movw #Terminal_Est1,Est_Pres_Terminal
Fin_Terminal_Est3
               rts
;============================= Terminal Estado 4================================
Terminal_Est4
              tst Timer5s
              bne Fin_Terminal_Est4
              bclr banderas,empty
              movw #Terminal_Est1,Est_Pres_Terminal
Fin_Terminal_Est4
              rts
               

;******************************************************************************
;                               SUBRUTINA BIN_ASCII
;******************************************************************************
BIN_ASCII
              ldaa Volumen
              clr BCD
              movb #07,Cont_BCD
Desplazar_BCD
              lsla      ; desplazar a (MSB -> C)
              rol BCD   ; rotar BCD (BCD <- C)
              ldab BCD  ; separar primer nibble
              andb #$0F
              cmpb #$05 ; Ver si es menor que 5, si es mayor sumar 3
              blo nibble2_BCD
              addb #$03
nibble2_BCD
              psha   ; Guardar el dato de Bin
              tba
              ldab BCD ; Separar el segundo nibble
              andb #$F0
              cmpb #$50 ; Ver si es menor que 5, si es mayor sumar 3
              blo verificar_desp
              addb #$30
verificar_desp
              aba
              staa BCD
              pula
              dec Cont_BCD
              bne Desplazar_BCD
              lsla    ; Ultimo desplazamiento
              rol BCD
              
              ldaa BCD
              anda #$0F
              adda #$30
              staa ASCII+1
              
              ldaa BCD
              anda #$F0
              lsra
              lsra
              lsra
              lsra
              adda #$30
              staa ASCII
              rts

;******************************************************************************
;                       SUBRUTINA CAlcula
;******************************************************************************
Calcula
                ldd ADR00H
                addd ADR01H
                addd ADR02H
                addd ADR03H
                lsrd
                lsrd
                std NivelProm
               
                ldy #20
                emul
                ldx #1023
                idiv
                stx temp

                ldd #13
                ldy temp
                emul
                ldx #20
                idiv
                stx temp

                ldd temp
                stab Nivel
                ldy #314
                emul
                ldy #15
                emul
                ldx #100
                idiv
                stx temp

                ldd temp
                ldy #15
                emul
                ldx #100
                idiv
                stx temp
                ldd temp
                stab volumen
               
               rts
;******************************************************************************
;                       SUBRUTINA DE ATENCION A OC
;******************************************************************************

Maquina_Tiempos:
                ldd TCNT
                addd #Carga_TC4
                std TC4

                ldx #Tabla_Timers_BaseT ; Cargar la tabla de timers
                jsr Decre_Timers_BaseT ; disminuir los timers
                ldd Timer1mS           ; repertir para las demas bases
                bne Timer_10ms
                movw #tTimer1mS,Timer1mS
                ldx #Tabla_Timers_Base1mS
                jsr Decre_Timers
Timer_10ms      ldd Timer10mS
                bne Timer_100ms
                movw #tTimer10mS,Timer10mS
                ldx #Tabla_Timers_Base10mS
                jsr Decre_Timers
Timer_100ms     ldd Timer100mS
                bne Timer_1s
                movw #tTimer100mS,Timer100mS
                ldx #Tabla_Timers_Base100mS
                jsr Decre_Timers
Timer_1S        ldd Timer1S
                bne Fin
                movw #tTimer1S,Timer1S
                ldx #Tabla_Timers_Base1S
                jsr Decre_Timers
Fin
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
                        
                        