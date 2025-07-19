;*******************************************************************************
 ;                             Manejo de Pantallas
 ; Autor: Bryan Cortes Espínola
 ; Version: 0.1
 ; Descripcion: Implementa el manejo de los displays y la pantalla LCD de la
 ; Dragon 12, se muestra un mensaje de inicio en el LCD y al presinar PB H.3
 ; Cambia de mensaje y el contador mostrado en los displays empieza a descontar.
;*******************************************************************************
#include registers.inc
 ;******************************************************************************
 ;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
 ;******************************************************************************
                                Org $3E66
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

;--- Aqui se colocan los valores de carga para los timers baseT  ----

tTimer1mS:        EQU 50      ; Base de tiempo de 1 mS (1 ms x 1)
tTimer10mS:       EQU 500     ; Base de tiempo de 10 mS (1 mS x 10)
tTimer100mS:      EQU 5000    ; Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:         EQU 50000   ; Base de tiempo de 1 segundo (100 mS x 10)
;--- Aqui se colocan los valores de carga para los timers baseT  Para LCD ----
tTimer260uS       EQU 13
tTimer40uS        EQU 2
;--- Aqui se colocan los valores de carga para los timers para LCD ----
tTimer2mS         EQU 100
;--- Aqui se colocan los valores de carga para los timers de PB0  ----
tSubRebPB0         EQU 10  ; Tiempo de supresion de rebotes x 1mS
tShortP0           EQU 25  ; Tiempo minimo de ShortPress x 10mS
tLongP0            EQU 2   ; Tiempo minimo de LongPress x 1S

;--- Aqui se colocan los valores de carga para los timers de PB1  ----
tSubRebPB1         EQU 10  ; Tiempo de supresion de rebotes x 1mS
tShortP1           EQU 25  ; Tiempo minimo de ShortPress x 10mS
tLongP1            EQU 2   ; Tiempo minimo de LongPress x 1S

;--- Aqui se colocan los valores de carga para los timers de Led testigo  ----
tTimerLDTst       EQU 5   ; Tiempo de parpadeo de LED testigo x 100 mS

;--- Aqui se colocan los valores de carga para los timers de Teclado   ----
tSuprRebTCL       EQU 20  ; Tiempo de Supresion de reobtes de teclado x1mS

;--- Aqui se colocan los valores de carga para los timers de Pantalla MUX   ----
tTimerDigito      EQU 2   ; Tiempo de digito x 1 ms

;--- Aqui se colocan los valores de carga para los timers de TCM   ----
tMinutosTCM       EQU 1  ; Tiempo en Minutos en TCM
tSegundosTCM      EQU 15 ; Tiempo en Segundos en TCM

; --- Valores para las tareas Leer_PB0, Leer_PB1 ----

PortPB            EQU PTIH  ; Puerto del Boton Pulsador
MaskPB0           EQU $01   ; Boton el el puerto H.0
MaskPB1           EQU $08   ; Boton el el puerto H.3


; --- Valores para las tareas
ENABLE:           EQU $02 ; Mascara para el enable del LCD en el puerto K
EOB:              EQU $FF ; Indicador de fin de bloque

ADD_L1            EQU $80 ; Dirrecion de la primera linea del LCD
ADD_L2            EQU $C0 ; Direccion de la segunda Linea del LCD

;       ---- Mascaras para las banderas contenidas en  Banderas_1 ----
; Para la tarea Leer_PB0
ShortP0          EQU $01
LongP0           EQU $02
; Para la tarea Leer_PB1
ShortP1          EQU $04
LongP1           EQU $08
; Para la tarea Teclado
ArrayOK          EQU $01

;       ---- Mascaras para las banderas contenidas en  Banderas_2 ----
; Banderas para el LCD
RS               EQU $01 ; Indica si es comando o mandar dat
LCD_OK           EQU $02 ; Indica si esta listo para mandar un dato
FinSendLCD       EQU $04 ; Indica si se termino de enviar el dato
Second_line      EQU $08 ; Indica si se debe escribir en la Segunda Linea de LCD

;    --- Mascaras para el led tricolor en el puerto P
LD_Red          EQU $10 ; LED rojo
LD_Green        EQU $20 ; LED verde
LD_Blue         EQU $40 ; LED Azul


;    --- Mascaras para los display ---
DIG1            EQU $01 ; Estan etiquetados a como sale en la Dragon 12
DIG2            EQU $02
DIG3            EQU $04
DIG4            EQU $08

; Valor Maximo de Ticks (Brillo)
MaxCountTicks   EQU 100
; Valores de para los Leds del Puerto B
InicioLD        EQU $55 ; Prende los Leds pares
TemporalLD      EQU $AA ; Prende los Leds impares

; Comandos para el LCD
Clear_LCD        EQU $01        ;Comando CLEAR para LCD



BORRAR           EQU $0B
ENTER            EQU $0E

PA0              EQU $02
PA1              EQU $04
PA2              EQU $08

Carga_TC4        EQU 30



                                Org $1000
;                 --- Variables para la tarea Teclado  ---
MAX_TCL          ds 1  ; Longitud Maxima de la secuencia de teclas validas
Tecla            ds 1  ; Variable para guardar la Tecla Ingresado
Tecla_IN         ds 1  ; Variable auxiliar para guardar la Tecla Ingresado
Cont_TCL         ds 1  ; Varible para guadar el numero de teclas ingresadas
Patron           ds 1  ; Variable para el patron de lectura en el Puerto A
Est_Pres_TCL     ds 2  ; Estado Presente de la tarea de Teclado
                                Org $1010
; Arreglo de secuencia de teclas validas
Num_Array
                               org $1020
; Variables utilizadas para el control de pantallas multiplexadas
EstPres_PantallaMUX   ds 2 ; Estado Presente de la Tarea PantallaMUX
Dsp1                  ds 1 ; Variable a mostrar en el Display 1
Dsp2                  ds 1 ; Variable a mostrar en el Display 2
Dsp3                  ds 1 ; Variable a mostrar en el Display 3
Dsp4                  ds 1 ; Variable a mostrar en el Display 4
LEDS                  ds 1 ; Variable a mostrar en los Leds
Cont_Dig              ds 1 ; Variable que indica cual Display mostrar
Brillo                ds 1 ; Variable para controlar el brillo de los Leds
BIN1                  ds 1 ; Valor en binario
BIN2                  ds 1 ; Valor en binario
BCD                   ds 1
Cont_BCD              ds 1
BCD1                  ds 1
BCD2                  ds 1




; LCD
IniDsp           db $28 ;FunctionSet1
                 db $06 ;Entry Mode Set.
                 db $0C ;Display ON/OFF Control.
                 db $FF ;Indicador de fin de tabla

Punt_LCD         ds 2
CharLCD          ds 1
Msg_L1           ds 2
Msg_L2           ds 2
EstPres_SendLCD  ds 2
EstPres_TareaLCD ds 2
; Pb 1
EstPres_LeerPb1  ds 2
; TCM
Est_Pres_TCM     ds 2
MinutosTCM       ds 1




                               Org $100D
EstPres_LeerPb0 ds 2 ; Estado presente de LeerPb0

                               Org $1070
Banderas_1      ds 1
Banderas_2      ds 1





                        org $1200

MSG1        fcc " ING. ELECTRICA "
        db  EOB
MSG2        fcc "    UCR 2025    "
        db  EOB
MSG3        fcc " uPROCESADORES  "
        db  EOB
MSG4        fcc "     IE0623     "
        db  EOB

                               Org $1100
Segment         db $3F        ;'0' en 7 segmentos
                db $06        ;'1' en 7 segmentos
                db $5B        ;'2' en 7 segmentos
                db $4F        ;'3' en 7 segmentos
                db $66        ;'4' en 7 segmentos
                db $6D        ;'5' en 7 segmentos
                db $7D        ;'6' en 7 segmentos
                db $07        ;'7' en 7 segmentos
                db $7F        ;'8' en 7 segmentos
                db $6F        ;'9' en 7 segmentos

                               Org $1110
; Tabla de los valores que las teclas
Teclas          dB $01
                dB $02
                dB $03
                dB $04
                dB $05
                dB $06
                dB $07
                dB $08
                dB $09
                dB $0B ; Borrar
                dB $00
                dB $0E ; Enter

                              org $1080
Est_Pres_LDTst   ds 2


;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
Tabla_Timers_BaseT:
Counter_Ticks:  ds 2
Timer260uS:     ds 2
Timer40uS:      ds 2
Timer1mS:       ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS


Timer2mS:       ds 1
Timer_RebPB0:   ds 1  ; Timer de supresion de rebotes para PH0
Timer_RebPB1:   ds 1  ; Timer de supresion de rebotes para PH3
Timer_RebTCL:   ds 1  ; Timer de supresion de rebotes para teclado
TimerDigito:    ds 1  ; Timer de digito P mux

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP0:  ds 1     ; Timer de Short Press
Timer_SHP1:  ds 1     ; Timer de Short Press
Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_100mS      ds 1
Timer_LED_Testigo ds 1   ; Timer para parpadeo de led testigo

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LP0:    ds 1        ; Timer LongPress
Timer_LP1:    ds 1        ; Timer LongPress
SegundosTCM:  ds 1


Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000
        ; Leds
        movb #$FF,DDRB
        Bset DDRJ,$02
        Bclr PTJ,$02

        ; Display 7 segmentos
        ;Movb #$7F,DDRP    ;bloquea los display de 7 Segmentos
        ;Movb #$0F,PTP
        
        bset DDRP,$7F
        bclr PTP,$0F
        
        ; Configuracion del Output Compare
        movb #Carga_TC4,TC4
        movb #$90,TSCR1 ; Prender el periferico con borrado rapido de banderas
        movb #$04,TSCR2 ; Prs  = 16
        movb #$10,TIOS ; poner el canal 4 como salida
        movb #$10,TIE  ; Habiltar interrupcion
        
        ldd TCNT
        addd #Carga_TC4
        std TC4
        
        movb #$F0,DDRA     ; Puerto A, nibble alto salidas nibble bajo entradas
        bset PUCR,$01      ; poner pullups en Puerto A
        
        
;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS    ;Inicia los timers de bases de tiempo
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S

        movb #$FF,Tecla    ; Borrar los contenidos en Tecla y Tecla_IN
        movb #$FF,Tecla_IN
        clr Cont_TCL       ; Borrar Cont_TCL
        clr Banderas_1 ; Borrar el contenido de banderas
        movb #5,MAX_TCL

        Movb #tTimerLDTst,Timer_LED_Testigo ;inicia timer parpadeo led testigo

        movb #$01,Cont_Dig
        clr Counter_Ticks
        clr TimerDigito
        movb #90,Brillo
        movb #InicioLD,LEDS
        movb #tSegundosTCM,BIN1
        movb #tMinutosTCM,BIN2
        
        
        Lds #$3BFF ; Iniciar el puntero de pila
        Cli        ; Habilitar las interrupciones


        movw #LeerPB0_Est1,EstPres_LeerPB0 ; Poner el estado 1 como Default
        movw #LeerPB1_Est1,EstPres_LeerPB1
        movw #TCL_Est1,Est_Pres_TCL ; Poner el estado 1 como Default
        movw #LDTst_Est1,Est_Pres_LDTst
        movw #PantallaMUX_Est1,EstPres_PantallaMUX
        movw #TCM_Est1,Est_Pres_TCM
;===============================================================================
;                      Inicializacion de la pantalla LCD
;===============================================================================
            movw #SendLCD_Est1,EstPres_SendLCD

            movw #MSG1,MSG_L1
            movw #MSG2,MSG_L2
            
            ; inicializar Puerto K
            bset DDRK,$3F
            ; Inicializar Banderas
            clr Banderas_2
           ; bset Banderas_2,LCD_OK
           ; inicializar Punt_LCD
             movw #IniDsp,Punt_LCD
             
             
            ; Cargar IniDsp
Cargar_Ini   ldx Punt_LCD
             movb 1,x+,CharLCD
             stx Punt_LCD
             ldaa CharLCD
             cmpa #EOB
             beq Clr_LCD
             
             
Mandar_Ini   jsr Tarea_SendLCD
             brclr Banderas_2,FinSendLCD,Mandar_Ini
             
             bclr Banderas_2,FinSendLCD
             bra Cargar_Ini
             

Clr_LCD      movb #Clear_LCD,CharLCD
Mandar_clr   jsr Tarea_SendLCD
             brclr Banderas_2,FinSendLCD,Mandar_clr
             movb tTimer2mS,Timer2mS
espere2mS    tst Timer2mS
             bne espere2mS
             
             movw #TareaLCD_Est1,EstPres_TareaLCD
        
;===============================================================================
;                           Despachador de Tareas
;===============================================================================
Despachador_Tareas

        brset Banderas_2,LCD_OK,Pasar_Tarea
        jsr TareaLCD
Pasar_Tarea
        Jsr Tarea_Led_Testigo
        Jsr Tarea_LeerPB0
        Jsr Tarea_LeerPB1
        Jsr Tarea_clr_tcl
        Jsr Tarea_Teclado
        Jsr Tarea_TCM
        Jsr Tarea_Conversiones
        Jsr Tarea_PantallaMUX
        Bra Despachador_Tareas
        
        
        
;*******************************************************************************
;                            Tarea Conversiones
; Tarea Conversiones: Toma dos valores en Binario y lo convierte de BCD y luego
; a 7 segmentos en las variables Dspx, para ser mostrado en los displays
;
;*******************************************************************************
Tarea_Conversiones
                   ldaa BIN1
                   jsr Bin_BCD_MUXP
                   movb BCD,BCD1
                   ldaa BIN2
                   jsr Bin_BCD_MUXP
                   movb BCD,BCD2
                   jsr BCD_7Seg
                   rts
        
;*******************************************************************************
;                  SUBRUTINA   Bin_BCD_MUXP
;*******************************************************************************
Bin_BCD_MUXP
              movb #$07,Cont_BCD ; numeros de desplazamiento a realizar
              clr BCD   ; Limpiar BCD
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
              rts

;*******************************************************************************
;                  SUBRUTINA   BCD_7Seg
;*******************************************************************************
BCD_7Seg
              ldx #Segment
              ldaa BCD2
              lsra
              lsra
              lsra
              lsra
              movb a,x,Dsp1
              ldaa BCD2
              anda #$0F
              movb a,x,Dsp2
              ldaa BCD1
              lsra
              lsra
              lsra
              lsra
              movb a,x,Dsp3
              ldaa BCD1
              anda #$0F
              movb a,x,Dsp4
         rts
;******************************************************************************
;                       Tarea PantallaMUX
;
;******************************************************************************
Tarea_PantallaMUX
            ldx EstPres_PantallaMUX  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
            rts


;====================== Pantalla MUX Estado 1 ==================================
PantallaMUX_Est1
             tst TimerDigito
             bne Fin_PantallaMUX_Est1
             
             movb #tTimerDigito,TimerDigito
             ldaa Cont_Dig
             cmpa #1
             beq Mostrar_Dsp1
             cmpa #2
             beq Mostrar_Dsp2
             cmpa #3
             beq Mostrar_Dsp3
             cmpa #4
             beq Mostrar_Dsp4
             
             Bclr PTJ,$02
             movb LEDS,PORTB
             clr Cont_Dig
             bra Incre_Cont_Dig
             
             
Mostrar_Dsp1
               bclr PTP,DIG1
               movb Dsp1,PORTB
               bra Incre_Cont_Dig

Mostrar_Dsp2
               bclr PTP,DIG2
               movb Dsp2,PORTB
               bra Incre_Cont_Dig
Mostrar_Dsp3
               bclr PTP,DIG3
               movb Dsp3,PORTB
               bra Incre_Cont_Dig
Mostrar_Dsp4
               bclr PTP,DIG4
               movb Dsp4,PORTB
               bra Incre_Cont_Dig

Incre_Cont_Dig inc Cont_Dig
               movw #MaxCountTicks,Counter_Ticks
               movw #PantallaMUX_Est2,EstPres_PantallaMUX
Fin_PantallaMUX_Est1
                rts
         
;====================== Pantalla MUX Estado 2 ==================================
PantallaMUX_Est2
                ldd Counter_Ticks
                cmpb Brillo
                bhi Fin_PantallaMUX_Est2
                bset PTP,$0F
                bset PTJ,$02
                movw #PantallaMUX_Est1,EstPres_PantallaMUX
Fin_PantallaMUX_Est2
                rts
                
;******************************************************************************
;                       Tarea SendLCD
;
;******************************************************************************
Tarea_SendLCD
            ldx EstPres_SendLCD  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
            rts


;====================== SendLCD Estado 1 ==================================
SendLCD_Est1
              ldaa CharLCD
              anda #$F0
              lsra
              lsra
              staa PortK
              
              brset Banderas_2,RS,Poner_RS1
              bclr PortK,RS
              
              bra  Poner_Enable1
Poner_RS1     bset PortK,RS
Poner_Enable1 bset PortK,ENABLE
              movw #tTimer260uS,Timer260uS
              movw #SendLCD_Est2,EstPres_SendLCD

            rts
                
;====================== SendLCD Estado 2 ==================================
SendLCD_Est2
              ldd Timer260uS
              bne Fin_SendLCD_Est2
              
              bclr PortK,ENABLE
              
              ldaa CharLCD
              anda #$0F
              lsla
              lsla
              staa PortK
              brset Banderas_2,RS,Poner_RS2
              bclr PortK,RS
              bra Poner_Enable2
Poner_RS2     bset PortK,RS
Poner_Enable2 bset PortK,ENABLE
              movw #tTimer260uS,Timer260uS
              movw #SendLCD_Est3,EstPres_SendLCD
            
Fin_SendLCD_Est2
            rts
            
;====================== SendLCD Estado 3 ==================================
SendLCD_Est3
             ldd Timer260uS
             bne Fin_SendLCD_Est3
             bclr PortK,ENABLE
             movw #tTimer40uS,Timer40uS
             movw #SendLCD_Est4,EstPres_SendLCD
Fin_SendLCD_Est3
            rts

;====================== SendLCD Estado 4 ==================================
SendLCD_Est4
             ldd Timer40uS
             bne Fin_SendLCD_Est4
             bset Banderas_2,FinSendLCD
             movw #SendLCD_Est1,EstPres_SendLCD

Fin_SendLCD_Est4
            rts
            
;******************************************************************************
;                       Tarea LCD
;
;******************************************************************************
TareaLCD
            ldx EstPres_TareaLCD  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
            rts


;========================= Tarea LCD  Estado 1 ==================================
TareaLCD_Est1
            bclr Banderas_2,FinSendLCD
            bclr Banderas_2,RS
            brset Banderas_2,Second_line,Mandar_L2
            movb #ADD_L1,CharLCD
            movw MSG_L1,Punt_LCD
            bra Mandar_Char
Mandar_L2   movb #ADD_L2,CharLCD
            movw MSG_L2,Punt_LCD
Mandar_Char jsr Tarea_SendLCD
            movw #TareaLCD_Est2,EstPres_TareaLCD
            rts
;========================= Tarea LCD  Estado 2 =================================
TareaLCD_Est2
            brclr Banderas_2,FinSendLCD,No_Enviado
            bclr Banderas_2,FinSendLCD
            bset Banderas_2,RS
            ldx Punt_LCD
            movb 1,x+,CharLCD
            stx Punt_LCD
            ldaa CharLCD
            cmpa #EOB
            bne No_Enviado
            brset Banderas_2,Second_Line,Terminar_LCD
            bset Banderas_2,Second_Line
            bra Reg_est1_TareaLCD
Terminar_LCD
            bclr Banderas_2,Second_Line
            bset Banderas_2,LCD_OK
Reg_est1_TareaLCD
            movw #TareaLCD_Est1,EstPres_TareaLCD
            bra Fin_TareaLCD_Est2
No_Enviado  jsr Tarea_SendLCD
Fin_TareaLCD_Est2
                 rts


;*******************************************************************************
;                            Tarea clr_tcl
; Tarea Led_PB: Se encarga de realizar acciones segun es presionado el boton de
; PTH.0
;
;*******************************************************************************
Tarea_clr_tcl
             brset Banderas_1,ShortP0,ON ;si se presiona short press enceder LED
             brset Banderas_1,LongP0,OFF ;si se presiona long press apagar LED

             bra FIN_Led        ; Si no se presiona fin de tarea

ON           bclr Banderas_1,ShortP0   ; Borrar banderas asocioadas
             bset PortB,$01         ; Encender Led
             bra FIN_Led

OFF          bclr Banderas_1,LongP0   ; Borrar Bandera de LongPress
             bclr PortB,$01        ; Apagar Led
             bclr Banderas_1,ArrayOK ; Borrar Bandera de ArrayOK

             jsr Borrar_Num_Array

FIN_Led      rts



;******************************************************************************
;                               Tarea Leer PB0
;  Metodo para la implementacion de la maquina de estados Leer_PB0
; EL estado de partida se inicializa en la variable EstPres_LeerPB0
; en el programa pricipal
; En cada estado se actualiza EstPres_LeerPB0 Cargando la dirrecion del
; proximo estado
;******************************************************************************
Tarea_LeerPB0
            ldx EstPres_LeerPB0  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado

FinTareaPB  rts
;====================== Leer PB Estado 1 =======================================
LeerPB0_Est1 brset PortPB,MaskPB0,FinPB0_Est1 ; Verificar si se presiono PB
             movb #tSubRebPB0,Timer_RebPB0 ; Si si cargar Timers
             movb #tShortP0,Timer_SHP0
             movb #tLongP0,Timer_LP0

             movw #LeerPB0_Est2,EstPres_LeerPB0 ; Pasar al estado 2
FinPB0_Est1   rts


;====================== Leer PB Estado 2 =======================================
LeerPB0_Est2 tst Timer_RebPB0   ; Verficar si ya cumplio el tiempo de rebotes
             bne FinPB0_Est2
             brset PortPB,MaskPB0,Volver_Est1 ; Verificar si sigue presionado
             movw #LeerPB0_Est3,EstPres_LeerPB0 ; si si pasar al estado 3
             bra FinPB0_Est2
Volver_Est1  movw #LeerPB0_Est1,EstPres_LeerPB0; Si no volver al estado 1
FinPB0_Est2   rts


;====================== Leer PB Estado 3 =======================================
LeerPB0_Est3  tst Timer_SHP0 ; Verificar el tiempo de Short Press
              bne FinPB0_Est3
              brset PortPB,MaskPB0,Volv_Est1 ; Verificar si sigue presionado
              movw #LeerPB0_Est4,EstPres_LeerPB0 ; si es asi pasar al estado 4
              bra FinPB0_Est3
Volv_Est1     bset Banderas_1,ShortP0 ; Si no Poner ShortPress y volver a estado1
              movw #LeerPB0_Est1,EstPres_LeerPB0
FinPB0_Est3   rts


;====================== Leer PB Estado 4 =======================================
LeerPB0_Est4  tst Timer_LP0 ; Verificar el tiempo Long Press
              bne Revisar_PB0 ; si se cumplió
              brclr PortPB,MaskPB0,FinPB0_Est4 ; ver si sigue presionado
              bset Banderas_1,LongP0 ; Poner LongPress
              Bra Reg_Est1
Revisar_PB0   brclr PortPB,MaskPB0,FinPB0_Est4; si no se cumpplio ver si sigue
              bset Banderas_1,ShortP0; Si no poner ShortPress
Reg_Est1      movw #LeerPB0_Est1,EstPres_LeerPB0  ; Volver al estado 1
FinPB0_Est4   rts


;******************************************************************************
;                               Tarea Leer PB1
;  Metodo para la implementacion de la maquina de estados Leer_PB1
; EL estado de partida se inicializa en la variable EstPres_LeerPB1
; en el programa pricipal
; En cada estado se actualiza EstPres_LeerPB0 Cargando la dirrecion del
; proximo estado
;******************************************************************************
Tarea_LeerPB1
            ldx EstPres_LeerPB1  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado

FinTareaPB1  rts
;====================== Leer PB Estado 1 =======================================
LeerPB1_Est1 brset PortPB,MaskPB1,FinPB1_Est1 ; Verificar si se presiono PB
             movb #tSubRebPB1,Timer_RebPB1 ; Si si cargar Timers
             movb #tShortP1,Timer_SHP1
             movb #tLongP1,Timer_LP1

             movw #LeerPB1_Est2,EstPres_LeerPB1 ; Pasar al estado 2
FinPB1_Est1   rts


;====================== Leer PB Estado 2 =======================================
LeerPB1_Est2     tst Timer_RebPB1   ; Verficar si ya cumplio el tiempo de rebotes
                 bne FinPB1_Est2
                 brset PortPB,MaskPB1,Volver_Est1_PB1 ; Verificar si sigue presionado
                 movw #LeerPB1_Est3,EstPres_LeerPB1 ; si si pasar al estado 3
                 bra FinPB1_Est2
Volver_Est1_PB1  movw #LeerPB1_Est1,EstPres_LeerPB1; Si no volver al estado 1
FinPB1_Est2   rts


;====================== Leer PB Estado 3 =======================================
LeerPB1_Est3  tst Timer_SHP1 ; Verificar el tiempo de Short Press
              bne FinPB1_Est3
              brset PortPB,MaskPB1,Volv_Est1_PB1 ; Verificar si sigue presionado
              movw #LeerPB1_Est4,EstPres_LeerPB1 ; si es asi pasar al estado 4
              bra FinPB1_Est3
Volv_Est1_PB1 bset Banderas_1,ShortP1 ; Si no Poner ShortPress y volver a estado1
              movw #LeerPB1_Est1,EstPres_LeerPB1
FinPB1_Est3   rts


;====================== Leer PB Estado 4 =======================================
LeerPB1_Est4  tst Timer_LP1 ; Verificar el tiempo Long Press
              bne Revisar_PB1 ; si se cumplió
              brclr PortPB,MaskPB1,FinPB1_Est4 ; ver si sigue presionado
              bset Banderas_1,LongP1 ; Poner LongPress
              Bra Reg_Est1_PB1
Revisar_PB1   brclr PortPB,MaskPB1,FinPB1_Est4; si no se cumpplio ver si sigue
              bset Banderas_1,ShortP1; Si no poner ShortPress
Reg_Est1_PB1  movw #LeerPB1_Est1,EstPres_LeerPB1  ; Volver al estado 1
FinPB1_Est4   rts


 ;******************************************************************************
;                       Tarea TCM
;
;******************************************************************************
Tarea_TCM
            ldx Est_Pres_TCM  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
            rts


;========================= TCM  Estado 1 ==================================
TCM_Est1
            brclr Banderas_1,ShortP1,Fin_TCM_Est1
            movb #tSegundosTCM,SegundosTCM
            movb #tMinutosTCM,MinutosTCM
            
            movw #MSG3,MSG_L1
            movw #MSG4,MSG_L2
            bclr Banderas_2,LCD_Ok
            
            movw #TCM_Est2,Est_Pres_TCM

Fin_TCM_Est1  rts

;======================  TCM Estado 2 ==================================
TCM_Est2
           movb MinutosTCM,BIN2
           movb SegundosTCM,BIN1
           movb #TemporalLD,LEDS
           
           tst SegundosTCM
           bne Fin_TCM_Est2
           
           tst MinutosTCM
           bne Dec_Minutos
           
           movb #tMinutosTCM,BIN2
           movb #tSegundosTCM,BIN1
           movw #MSG1,MSG_L1
           movw #MSG2,MSG_L2
           bclr Banderas_2,LCD_Ok
           
           movb #InicioLD,LEDS
           bclr Banderas_1,ShortP1
           movw #TCM_Est1,Est_Pres_TCM
           bra Fin_TCM_Est2
           
Dec_Minutos
          dec MinutosTCM
          movb #60,SegundosTCM
           
Fin_TCM_Est2 rts


;******************************************************************************
;                               Tarea Teclado
;
;
;******************************************************************************
Tarea_Teclado
            ldx Est_Pres_TCL  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado

FinTareaTCL  rts
;====================== Teclado Estado 1 =======================================
TCL_Est1
             jsr Leer_Tecla ; Ir a la subrutina de leer tecla
             ldaa Tecla
             cmpa #$FF   ; Ver si se presionó alguna tecla
             beq Fin_TCL_Est1  ; si no seguir en el estado 1
             movb #tSuprRebTCL,Timer_RebTCL ; si se presiono cargar timer
             movw #TCL_Est2,Est_Pres_TCL   ; y pasar al estado 2
Fin_TCL_Est1 rts
;====================== Teclado Estado 2 =======================================
TCL_Est2
             tst Timer_RebTCL ; Comprobar si el timer ya expiró
             bne Fin_TCL_Est2
             movb Tecla,Tecla_IN ; Guardar el valor de tecla
             jsr Leer_Tecla
             ldaa Tecla
             cmpa Tecla_IN  ; comprobar si se sigue presionado
             bne Reg_TCL_Est1 ;
             movw #TCL_Est3,Est_Pres_TCL  ; si es asi pasar al estado 3
             bra Fin_TCL_Est2
Reg_TCL_Est1 movw #TCL_Est1,Est_Pres_TCL  ; si no regresar al estado 1
Fin_TCL_Est2 rts
;====================== Teclado Estado 3 =======================================
TCL_Est3
             jsr Leer_Tecla
             ldaa Tecla   ; Volver a leer si una tecla fue presionada
             cmpa #$FF
             bne Fin_TCL_Est3 ; si ya se dejó de presionar pasar al estado 4
             movw #TCL_Est4,Est_Pres_TCL
Fin_TCL_Est3 rts

;====================== Teclado Estado 4 =======================================
TCL_Est4
             ldx #Num_Array
             ldaa Cont_TCL
             ldab Tecla_IN
             cmpa MAX_TCL   ; comprobar si ya se ingresó el maximo de teclas
             beq Maximo_TCL

             tsta          ; Comprobar si es la primera tecla
             beq Primer_Tecla

             cmpb #BORRAR  ; Ver si la tecla es borrar
             beq Borrar_Tecla

             cmpb #ENTER   ; Ver si la tecla es Enter
             beq Enter_TCL
             bra Poner_Tecla

Primer_Tecla cmpb #BORRAR  ; si la primera tecla es borrar o enter ignorar
             beq Fin_TCL_Est4
             cmpb #ENTER
             beq Fin_TCL_Est4

Poner_Tecla  stab a,x ; Guardar la tecla presionada en num_array
             inc Cont_TCL
             bra Fin_TCL_Est4

Maximo_TCL   cmpb #BORRAR ; Ver si es borrar o enter, si es otra ignorar
             beq Borrar_Tecla
             cmpb #ENTER
             beq Enter_TCL
             bra Fin_TCL_Est4

Enter_TCL    clr Cont_TCL    ; Accion de  Enter
             bset Banderas_1,ArrayOK
             bra Fin_TCL_Est4

Borrar_Tecla deca         ; Accion de Borrar
             staa Cont_TCL
             movb #$FF,a,x

Fin_TCL_Est4 movb #$FF,Tecla_IN   ; FIn de estado borrar tecla y pasar al estado 1
             movw #TCL_Est1,Est_Pres_TCL
             rts

;******************************************************************************
;                               TAREA LED TESTIGO
;******************************************************************************

Tarea_Led_Testigo
            ldx Est_Pres_LDTst  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
FinLedTest  Rts

;=========================== Estado 1 ==========================================
LDTst_Est1
           tst Timer_LED_Testigo
           bne Fin_LDTst_Est1
           bset PTP,LD_Red
           bclr PTP,LD_Blue
           movw #LDTst_Est2,Est_Pres_LDTst
           movb #tTimerLDTst,Timer_LED_Testigo;inicia timer parpadeo led testigo
Fin_LDTst_Est1 rts

;=========================== Estado 2 ==========================================
LDTst_Est2
           tst Timer_LED_Testigo
           bne Fin_LDTst_Est2
           bset PTP,LD_Green
           bclr PTP,LD_Red
           movw #LDTst_Est3,Est_Pres_LDTst
           movb #tTimerLDTst,Timer_LED_Testigo;inicia timer parpadeo led testigo
Fin_LDTst_Est2
             rts

;=========================== Estado 3 ==========================================
LDTst_Est3
           tst Timer_LED_Testigo
           bne Fin_LDTst_Est3
           bset PTP,LD_Blue
           bclr PTP,LD_Green
           movw #LDTst_Est1,Est_Pres_LDTst
           movb #tTimerLDTst,Timer_LED_Testigo;inicia timer parpadeo led testigo
Fin_LDTst_Est3
             rts



;*******************************************************************************
;                  SUBRUTINA  Leer_Tecla
;*******************************************************************************
Leer_Tecla     clra ;  Borrar el offset
               movb #$EF,Patron
               ldx #Teclas
Loop_Tecla     movb Patron,PORTA   ; Escribir patron
               brclr PORTA,#PA0,Cargar_Tecla  ; recorrer por las teclas
               inca                           ; buscando alguna presionada
               brclr PORTA,#PA1,Cargar_Tecla
               inca
               brclr PORTA,#PA2,Cargar_Tecla
               inca
               ldab Patron
               cmpb #$7F      ; si no se encuentra alguna presionada escribir FF
               beq Tecla_No_Pres
               sec ; Carry = 1
               rol Patron
               bra Loop_Tecla
Tecla_no_Pres  movb #$FF,Tecla
               bra Fin_Leer_Tecla
Cargar_Tecla   movb a,x,Tecla
Fin_Leer_Tecla rts


;*******************************************************************************
;                  SUBRUTINA  Borrar_Num_Array
;*******************************************************************************

Borrar_Num_Array   ldaa MAX_TCL          ; Borrar Num_Array
                   ldx #Num_Array
Borrar_Array       movb #$FF,1,x+
                   dbne a,Borrar_Array
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