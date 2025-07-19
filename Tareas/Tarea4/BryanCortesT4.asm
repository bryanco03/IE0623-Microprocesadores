 ;******************************************************************************
 ;                             Teclado Matricial
 ; Autor: Bryan Cortes Espínola
 ; Version: 0.1
 ; Descripcion: Manejo del teclado matricial de la tarjeta Dragon 12, se utiliza
 ; Programacion por maquinas de estado, con una maquina de tiempos generado por
 ; Interrupciones RTI con timers de 1ms, 10ms 100ms y 1S, Se implementa la tarea
 ; Teclado por medio de maquina de estado el cual maneja el ingreso de una
 ; secuencia valida ademas que tiene logica para suprimir los rebotes mecanicos
 ; de los botones.
 ; El Teclado tiene la siguiente Forma:
 ;                       clr      1  2  3
 ;                                4  5  6
 ;                                7  8  9
 ;                                B  0  E
 ; Donde B es la tecla Borrar y E la tecla Enter y se podrá una secuencia valida
 ; de una longitud maxima indicado por MAX_TCL, El boton clr sirve para borrar
 ; la secuencia de teclas ingresadas, al realizar un Long Press (Presionarlo por
 ; 2 segundos) se implementa por medio de la tarea LEER_PB el cual se implementó
 ; por maquina de estados, donde se discrimina la duracion del pulso si es Short
 ; Press (de 250ms a 2 s) o long Press (Mas de dos segundos)
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

tTimer1mS:        EQU 1      ; Base de tiempo de 1 mS (1 ms x 1)
tTimer10mS:       EQU 10     ; Base de tiempo de 10 mS (1 mS x 10)
tTimer100mS:      EQU 100    ; Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:         EQU 1000   ; Base de tiempo de 1 segundo (100 mS x 10)
;--- Aqui se colocan los valores de carga para los timers de la aplicacion  ----
tSubRebPB         EQU 10  ; Tiempo de supresion de rebotes x 1mS
tShortP           EQU 25  ; Tiempo minimo de ShortPress x 10mS
tLongP            EQU 2   ; Tiempo minimo de LongPress x 1S
tTimerLDTst       EQU 1   ; Tiempo de parpadeo de LED testigo en segundos
tSuprRebTCL       EQU 20  ; Tiempo de Supresion de reobtes de teclado x1mS

PortPB            EQU PTIH  ; Puerto del Boton Pulsador
MaskPB            EQU $01   ; Boton el el puerto H.0

                                Org $1000
MAX_TCL          db $05  ; Longitud Maxima de la secuencia de teclas validas
Tecla            ds 1
Tecla_IN         ds 1
Cont_TCL         ds 1
Patron           ds 1
Est_Pres_TCL     ds 2    ; Estado Presente de la tarea de Teclado
                               Org $100C
Banderas         ds 1
                               Org $100D
Est_Pres_LeerPb ds 2 ; Estado presente de LeerPb
                               Org $1010
; Arreglo de secuencia de teclas validas
Num_Array
                dB $FF
                               Org $1020
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


; Banderas
ShortP          EQU $01
LongP           EQU $02
ArrayOK         EQU $04

; Mascaras del Puerto A
PA0            EQU $01
PA1            EQU $02
PA2            EQU $04

; Valores
BORRAR        EQU $0B
ENTER         EQU $0E


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

Timer_RebPB:    ds 1  ; Timer de supresion de rebotes para PH0
Timer_RebTCL:   ds 1  ; Timer de supresion de rebotes para teclado

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP:  ds 1     ; Timer de Short Press

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_100mS  ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LED_Testigo ds 1   ; Timer para parpadeo de led testigo
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
        clr Banderas ; Borrar el contenido de banderas
        
        Movb #tTimerLDTst,Timer_LED_Testigo ;inicia timer parpadeo led testigo

        Lds #$3BFF ; Iniciar el puntero de pila
        Cli        ; Habilitar las interrupciones
        
        
        movw #LeerPB_Est1,Est_Pres_LeerPB ; Poner el estado 1 como Default
        movw #TCL_Est1,Est_Pres_TCL ; Poner el estado 1 como Default
;===============================================================================
;                           Despachador de Tareas
;===============================================================================
Despachador_Tareas

        Jsr Tarea_Led_Testigo
        Jsr Tarea_LeerPB
        Jsr Tarea_Led_PB
        Jsr Tarea_Teclado

        Bra Despachador_Tareas
;*******************************************************************************
;                            Tarea Led_PB
; Tarea Led_PB: Se encarga de realizar acciones segun es presionado el boton de
; PTH.0
;
;*******************************************************************************
Tarea_Led_PB
             brset Banderas,ShortP,ON ;si se presiona short press enceder LED
             brset Banderas,LongP,OFF ;si se presiona long press apagar LED

             bra FIN_Led        ; Si no se presiona fin de tarea
             
ON           bclr Banderas,ShortP   ; Borrar banderas asocioadas
             bset PortB,$01         ; Encender Led
             bra FIN_Led
             
OFF          bclr Banderas,LongP   ; Borrar Bandera de LongPress
             bclr PortB,$01        ; Apagar Led
             bclr Banderas,ArrayOK ; Borrar Bandera de ArrayOK

             jsr Borrar_Num_Array
             
FIN_Led      rts



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
Volv_Est1    bset Banderas,ShortP ; Si no Poner ShortPress y volver a estado1
             movw #LeerPB_Est1,Est_Pres_LeerPB
FinPB_Est3   rts


;====================== Leer PB Estado 4 =======================================
LeerPB_Est4  tst Timer_LP ; Verificar el tiempo Long Press
             bne Revisar_PB ; si se cumplió
             brclr PortPB,#MaskPB,FinPB_Est4 ; ver si sigue presionado
             bset Banderas,LongP ; Poner LongPress
             Bra Reg_Est1
Revisar_PB   brclr PortPB,#MaskPB,FinPB_Est4; si no se cumpplio ver si sigue prs
             bset Banderas,ShortP; Si no poner ShortPress
Reg_Est1     movw #LeerPB_Est1,Est_Pres_LeerPB  ; Volver al estado 1
FinPB_Est4   rts


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
             bset Banderas,ArrayOK
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
                Tst Timer_LED_Testigo  ; Verificar si se cumplió el tiempo
                Bne FinLedTest
                Movb #tTimerLDTst,Timer_LED_Testigo; si si recargar el timer
                Ldaa PORTB  ; Cargar el estado de PortB
                Eora #$80   ; Hacer Toggle
                Staa PORTB  ; Volver a escribir
FinLedTest      Rts

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
;                       SUBRUTINA DE ATENCION A RTI
;******************************************************************************

Maquina_Tiempos:
                ldx #Tabla_Timers_BaseT ; Cargar la tabla de timers
                jsr Decre_Timers_BaseT ; disminuir los timers
                ldd Timer1mS
                cpd #$0000            ; repertir para las demas bases
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

