;*******************************************************************************
 ;                         Proyecto Separador 623
 ; Autor: Bryan Cortes Espínola
 ; Version: 1.0
 ; Descripcion: Separador 623 Consiste en un  sistema modular que clasifica
 ; tuercas según su velocidad lineal en un canal de empaque,
 ; utilizando sensores, displays y una interfaz de usuario con teclado matricial
 ; y pantalla LCD y displays.
 ;
 ;
;*******************************************************************************
#include registers.inc
;*******************************************************************************
;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
;*******************************************************************************
                                Org $3E66
                                dw Maquina_Tiempos
;******************************************************************************
;                       DEFINICION DE VALORES
;******************************************************************************
;--- Aqui se colocan los valores de carga para los timers baseT  ----
tTimer1mS:       EQU 50      ; Base de tiempo de 1 mS (1 ms x 1)
tTimer10mS:      EQU 500     ; Base de tiempo de 10 mS (1 mS x 10)
tTimer100mS:     EQU 5000    ; Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:        EQU 50000   ; Base de tiempo de 1 segundo (100 mS x 10)
;--- Aqui se colocan los valores de carga para los timers baseT  Para LCD ----
tTimer260uS      EQU 13 ; Tiempo de ejecucion  para un comando de la LCD
tTimer40uS       EQU 2  ; Tiempo de ejecucion  para un comando de la LCD
;--- Aqui se colocan los valores de carga para los timers para LCD ----
tTimer2mS        EQU 100 ; Tiempo de ejecucion  para un comando de la LCD
;--- Aqui se colocan los valores de carga para los timers de PB2  ----
tSubRebPB2       EQU 10  ; Tiempo de supresion de rebotes x 1mS
tShortP2         EQU 25  ; Tiempo minimo de ShortPress x 10mS
tLongP2          EQU 2   ; Tiempo minimo de LongPress x 1S
;--- Aqui se colocan los valores de carga para los timers de PB1  ----
tSubRebPB1       EQU 10  ; Tiempo de supresion de rebotes x 1mS
tShortP1         EQU 25  ; Tiempo minimo de ShortPress x 10mS
tLongP1          EQU 2   ; Tiempo minimo de LongPress x 1S
;--- Aqui se colocan los valores de carga para los timers de Led testigo  ----
tTimerLDTst      EQU 5   ; Tiempo de parpadeo de LED testigo x 100 mS
;--- Aqui se colocan los valores de carga para los timers de Teclado   ----
tSuprRebTCL      EQU 20  ; Tiempo de Supresion de reobtes de teclado x1mS
;--- Aqui se colocan los valores de carga para los timers de Pantalla MUX   ----
tTimerDigito     EQU 2   ; Tiempo de digito x 1 ms
;--- Aqui se colocan los valores de carga para los timers de ATD  ----
tTimerBrillo     EQU 3  ; Timer de 300ms para iniciar conversion ATD
;--- Aqui se colocan los valores de carga para los timers la Tarea LeerDs  ----
tTimerRebDS      EQU 20  ; Timer de 20ms para suprimir rebotes
;--- Aqui se colocan los valores de carga para los timers para calcular  ----
tTimerCal        EQU 100 ; Timer para calcular Velocidad
;--- Aqui se colocan los valores de carga para los timers para modo separar ----
tTimerError      EQU 2 ; Timer de 2 s para mostrar mensaje de error
; --- Valores para las tareas Leer_PB0, Leer_PB1 ----
PortPB           EQU PTIH  ; Puerto del Boton Pulsador
MaskPB2          EQU $01   ; Boton el el puerto H.0
MaskPB1          EQU $08   ; Boton el el puerto H.3
; --- Valores para la Pantalla LCD
ENABLE:          EQU $02 ; Mascara para el enable del LCD en el puerto K
EOB:             EQU $FF ; Indicador de fin de bloque
ADD_L1           EQU $80 ; Dirrecion de la primera linea del LCD
ADD_L2           EQU $C0 ; Direccion de la segunda Linea del LCD
;       ---- Mascaras para las banderas contenidas en  Banderas_1 ----
; Para la tarea Leer_PB2
ShortP2          EQU $01 ; Indica si Hubo ShortPres en P2
LongP2           EQU $02 ; Indica si Hubo LongPres en P2
; Para la tarea Leer_PB1
ShortP1          EQU $04 ; Indica si Hubo ShortPres en P1
LongP1           EQU $08
; Para la tarea Teclado
ArrayOK          EQU $10
;       ---- Mascaras para las banderas contenidas en  Banderas_2 ----
; Banderas para el LCD
RS               EQU $01 ; Indica si es comando o mandar datp
LCD_OK           EQU $02 ; Indica si esta listo para mandar un dato
FinSendLCD       EQU $04 ; Indica si se termino de enviar el dato
Second_line      EQU $08 ; Indica si se debe escribir en la Segunda Linea de LCD
;    --- Mascaras para el led tricolor en el puerto P ----
LD_Red           EQU $10 ; LED rojo
LD_Green         EQU $20 ; LED verde
LD_Blue          EQU $40 ; LED Azul
;                    --- Mascaras para los display ---
DIG1             EQU $01 ; Estan etiquetados a como sale en la Dragon 12
DIG2             EQU $02
DIG3             EQU $04
DIG4             EQU $08
;                    ---  Valor Maximo de Ticks (Brillo)  ---
MaxCountTicks    EQU 100
;                    --- Valores de  Comandos para el LCD ----
Clear_LCD        EQU $01        ;Comando CLEAR para LCD
;                   ----  Valores de usados en Teclado ----
BORRAR           EQU $0B
ENTER            EQU $0E
;                   --- Valores de los puertos A para el teclado ----
PA0              EQU $02
PA1              EQU $04
PA2              EQU $08
;                   --- Valor de Carga para el Output Compare ---
Carga_TC4        EQU 30
;    ---  Bit del registro  ATD0STAT0 Indica si se terminó la conversion ---
SCF              EQU $80
;          --- Valores de mascaras de los Leds ----
LDStop           EQU $80 ; Led de Modo Stop
LDConfig         EQU $20 ; Led de modo Configurar
LDSeparar        EQU $40 ; Led de modo Separar
LDRebase         EQU $04 ; Led para indicar Rebase
LDLE2            EQU $02 ; Led para linea de empaque 2
LDLE1            EQU $01 ; Led para linea de empaque 1
;                  --- Valores para los Displays  de 7 segmentos ----
OFF              EQU $BB ; Apagar Display
Guion            EQU $AA ; Poner guiones
;                  ---  Valores maximos y minimos de Velocidad ---
Vmin             EQU 10  ; Valor minimo en cm/s
Vmax             EQU 80  ; Valor maximo en cm/s
;                  ---  Valores para el Relé ---
MaskRele         EQU $04  ; Bit 2
PortRele         EQU PORTE ; Puerto E
;                 --- Valores de las medidas del Separador 623 ----
DeltaS           EQU 60 ; Distancia entre sensores en cm
DeltaM           EQU 60 ; Distancia entre mensajes en cm
DeltaE           EQU 160 ; Distancia Total del canal de empaque en cm


;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************
                                Org $1000
;                 --- Variables para la tarea Teclado  ---
MAX_TCL          ds 1  ; Longitud Maxima de la secuencia de teclas validas
Tecla            ds 1  ; Variable para guardar la Tecla Ingresado
Tecla_IN         ds 1  ; Variable auxiliar para guardar la Tecla Ingresado
Cont_TCL         ds 1  ; Varible para guadar el numero de teclas ingresadas
Patron           ds 1  ; Variable para el patron de lectura en el Puerto A
Est_Pres_TCL     ds 2  ; Estado Presente de la tarea de Teclado
                                Org $1010
;             --- Arreglo de secuencia de teclas validas ---
Num_Array
                               org $1020
;     --- Variables utilizadas para el control de pantallas multiplexadas ---
EstPres_PantallaMUX   ds 2 ; Estado Presente de la Tarea PantallaMUX
Dsp1                  ds 1 ; Variable a mostrar en el Display 1
Dsp2                  ds 1 ; Variable a mostrar en el Display 2
Dsp3                  ds 1 ; Variable a mostrar en el Display 3
Dsp4                  ds 1 ; Variable a mostrar en el Display 4
LEDS                  ds 1 ; Variable a mostrar en los Leds
Cont_Dig              ds 1 ; Variable que indica cual Display mostrar
Brillo                ds 1 ; Variable para controlar el brillo de los Leds
;                --- Variables utilizadas para la subrutina de conversion ---
BCD                   ds 1 ; Variable para conversion Bin-BCD
Cont_BCD              ds 1 ; Variable de numeros de desplazamiento a realizar
BCD1                  ds 1 ; Variable a convertir a 7 Seg
BCD2                  ds 1 ; Variable a convertir a 7 Seg
;                --- Variables utilizadas para la pantalla  LCD ---
IniDsp           db $28 ;FunctionSet1
                 db $06 ;Entry Mode Set.
                 db $0C ;Display ON/OFF Control.
                 db $FF ;Indicador de fin de tabla
Punt_LCD         ds 2  ; Puntero para mandar datos a la LCD
CharLCD          ds 1  ; Caracter a enviar
Msg_L1           ds 2  ; Puntero del mensaje a mostrar en la primer linea
Msg_L2           ds 2  ; Puntero del mensaje a mostrar en la segunda linea
EstPres_SendLCD  ds 2  ; Estado Presente de la Tarea SendLCD
EstPres_TareaLCD ds 2  ; Estado Presente de Tarea LCD
;                ---  Variables utilizadas para la PB1 y  PB2
EstPres_LeerPb1  ds 2 ; Estado presente de LeerPb1
EstPres_LeerPb2  ds 2 ; Estado presente de LeerPb2
;                --- Variables del Modo Configurar ---
Est_Pres_TConfig ds 2 ; Estado Presente de la Configurar
ValorVelUmbral   ds 1 ; Variable para el valor ingresado de Velocidad por teclado
VelUmbral        ds 1 ; Variable del Velocidad Umbral Selecionado
;                --- Variables del Modo Separar ---
Est_Pres_TSeparar ds 2 ; Estado Presente de la Tarea Separar
DeltaT            ds 1 ; Variable para medir intervalo de tiempo
Velocidad         ds 1 ; Variable para la velocidad calculada
CantLE1           ds 1 ; Variable para la cantidad de Tuercas en LE1
CantLE2           ds 1 ; Variable para la cantidad de Tuercas en LE2
ValorRebase       ds 1 ; Variable para la cantidad Maxima en cada LE
;                 --- Variables para la Tarea Brillo ---
Est_Pres_TBrillo ds 2 ; Estado Presente de la Tarea Brillo
;                 --- Variables para la tarea LeerDS ----
Est_Pres_LeerDS  ds 2 ; Estado Presente de la Tarea LeerDS
Temp_DS          ds 1 ; Variable para el valor temporal de los DS
Valor_DS         ds 1 ; Valor para el valor leido de los DS
                               Org $1070
; ------------- Variables utilizadas para las banderas del Programa ----------|
Banderas_1      ds 1  ; X,X,X,ArrayOK,LongP1,ShortP1,LongP2,ShortP2
Banderas_2      ds 1  ; X,X,X,X,Second_line,FinSendLCD,LCD_OK,RS
                              org $1080
Est_Pres_LDTst   ds 2 ; Estado Presente de Led Testigo
;===============================================================================
;                              Mensajes
;===============================================================================
                        org $1200
MSG_STOP_L1                fcc "  SELECTOR 623  "
                           db EOB
MSG_STOP_L2                fcc "    MODO STOP   "
                           db EOB
MSG_CONFIGURAR_L1          fcc "MODO CONFIGURAR "
                           db EOB
MSG_CONFIGURAR_L2          fcc "VELOCIDAD UMBRAL"
                           db EOB
MSG_SEPARAR_L1             fcc "  MODO SEPARAR  "
                           db EOB
MSG_SEPARAR_S1             fcc "ESPERANDO INICIO"
                           db EOB
MSG_SEPARAR_S2             fcc "Esperando P1... "
                           db EOB
MSG_SEPARAR_S3             fcc "Esperando P2... "
                           db EOB
MSG_SEPARAR_S4             fcc " TIniP    TFinP "
                           db EOB
MSG_SEPARAR_S5             fcc "VELOC.  CANTIDAD"
                           db EOB
MSG_SEPARAR_S6             fcc "***Velocidad*** "
                           db EOB
MSG_SEPARAR_S7             fcc "*FUERA DE RANGO*"
                           db EOB
;===============================================================================
;                          Tabla de 7 Segmentos
;===============================================================================
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
                db $40        ;'-' mostrar Guion
                db $00        ;' ' Apagar

;===============================================================================
;                          Tabla de Teclas
;===============================================================================
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
;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
Tabla_Timers_BaseT:
Counter_Ticks:  ds 2       ;Timer para el brillo
Timer260uS:     ds 2       ;Timer para ejecucion de comando en el LCD
Timer40uS:      ds 2       ;Timer para ejecucion de comando en el LCD
Timer1mS:       ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS


Timer2mS:       ds 1   ;Timer para ejecucion de comando en el LCD
Timer_RebPB2:   ds 1  ; Timer de supresion de rebotes para PH0
Timer_RebPB1:   ds 1  ; Timer de supresion de rebotes para PH3
Timer_RebTCL:   ds 1  ; Timer de supresion de rebotes para teclado
Timer_RebDS     ds 1  ; Timer de supresion de rebotes para los DS
TimerDigito:    ds 1  ; Timer de digito P mux

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP2:  ds 1     ; Timer de Short Press
Timer_SHP1:  ds 1     ; Timer de Short Press
Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

TimerBrillo       ds 1   ; Timer para conversiones del ATD
TimerCal          ds 1   ; Timer para medir velocidad
TimerIniPant      ds 1   ; Timer de inicio de mensaje
TimerFinPant      ds 1   ; Timer de final de mensaje
Timer_LED_Testigo ds 1   ; Timer para parpadeo de led testigo

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

TimerError    ds 1        ; Timer para mostrar mensaje de error
Timer_LP2:    ds 1        ; Timer LongPress
Timer_LP1:    ds 1        ; Timer LongPress
Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000
        ; Configuracion de LED
        movb #$FF,DDRB ; Poner Puerto B como salida
        Bset DDRJ,$02  ; Habiltar LED
        Bclr PTJ,$0
        ; Configuracion del Rele
        bset DDRE,MaskRele ; Poner PORTE.2 como Salida

        ; Configuracion de los Displays y Led Tricolor.
        bset DDRP,$7F ; Poner del bit 0 a l 6 como salidas
        bclr PTP,$0F  ; Apagar los displays por el momento
        
        ; inicializar Puerto K
        bset DDRK,$3F

        ; Configuracion del Output Compare
        movb #$90,TSCR1 ; Prender el periferico con borrado rapido de banderas
        movb #$04,TSCR2 ; Prs  = 16
        movb #$10,TIOS ; poner el canal 4 como salida
        movb #$10,TIE  ; Habiltar interrupcion
        ; Cargar TC4
        ldd TCNT
        addd #Carga_TC4
        std TC4
        ; Configuracion de Teclado matricial
        movb #$F0,DDRA     ; Puerto A, nibble alto salidas nibble bajo entradas
        bset PUCR,$01      ; poner pullups en Puerto A
        
        movb #$C0,ATD0CTL2 ;Enceder ATD
        ldaa #160 ;Cargar valor para generar retardo de 10us
Espere
        dbne a,Espere
        movb #$20,ATD0CTL3 ; Ciclo de 4 mediciones
        movb #$93,ATD0CTL4 ; 8 bits
                           ; 2 Ciclos de muestreo
                           ; 600 Khz de frecuencia de muestreo
;===============================================================================
;                          Inicializacion de Estruturas de Datos
;===============================================================================
        ;Inicia los timers de bases de tiempo
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S

        movb #$FF,Tecla    ; Borrar los contenidos en Tecla y Tecla_IN
        movb #$FF,Tecla_IN
        clr Cont_TCL       ; Borrar Cont_TCL
        clr Banderas_1 ; Borrar el contenido de banderas
        movb #2,MAX_TCL
        
        clr CantLE1
        clr CantLE2
        
        movb #$05,ValorRebase

        Movb #tTimerLDTst,Timer_LED_Testigo ;inicia timer parpadeo led testigo

        movb #$01,Cont_Dig
        clr Counter_Ticks
        clr TimerDigito
        movb #90,Brillo
        movb #0,LEDS

        Lds #$3BFF ; Iniciar el puntero de pila
        Cli        ; Habilitar las interrupciones
        
;===============================================================================
;                      Inicializacion de variables de maquina de estado
;===============================================================================
         ; Poner el estado 1 como Default
        movw #LeerPB2_Est1,EstPres_LeerPB2
        movw #LeerPB1_Est1,EstPres_LeerPB1
        movw #TCL_Est1,Est_Pres_TCL
        movw #LDTst_Est1,Est_Pres_LDTst
        movw #PantallaMUX_Est1,EstPres_PantallaMUX
        movw #TBrillo_Est1,Est_Pres_TBrillo
        movw #LeerDS_Est1,Est_Pres_LeerDS
        movw #TConfig_Est1,Est_Pres_TConfig
        movw #TSeparar_Est1,Est_Pres_TSeparar
        movw #SendLCD_Est1,EstPres_SendLCD
        movw #TareaLCD_Est1,EstPres_TareaLCD
;===============================================================================
;                      Inicializacion de la pantalla LCD
;===============================================================================

            ; Mandar los mensajes a mostrar
            movw #MSG_STOP_L1,MSG_L1
            movw #MSG_STOP_L2,MSG_L2


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



;===============================================================================
;                           Despachador de Tareas
;===============================================================================
Despachador_Tareas

        brset Banderas_2,LCD_OK,Pasar_Tarea
        jsr TareaLCD
Pasar_Tarea
        Jsr Tarea_Led_Testigo
        Jsr Tarea_LeerPB2
        Jsr Tarea_LeerPB1
        Jsr Tarea_Teclado
        Jsr Tarea_PantallaMUX
        Jsr Tarea_Leer_DS
        Jsr Tarea_Brillo
        Jsr Tarea_Modo_STOP
        Jsr Tarea_Modo_Configurar
        Jsr Tarea_Modo_Separar
        Jsr BCD_7Seg
        Bra Despachador_Tareas

;******************************************************************************
;                               TAREA MODO STOP
;******************************************************************************
Tarea_Modo_STOP
        tst Valor_DS  ; Verifica si es el modo escogido
        bne Fin_Tarea_Modo_STOP
        movb #LDStop,LEDS    ; Si lo es prender el led de Stop
        movw #MSG_STOP_L1,MSG_L1 ; Mandar el mensaje de Stop al LCD
        movw #MSG_STOP_L2,MSG_L2
        bclr Banderas_2,LCD_Ok
        movb #OFF,BCD1       ; Apagar Displays
        movb #OFF,BCD2
Fin_Tarea_Modo_STOP
        rts
        
;******************************************************************************
;                      TAREA MODO Configurar
;******************************************************************************
Tarea_Modo_Configurar
        ldaa Valor_DS
        cmpa #$40       ; Verificar si es el modo escogido
        bne No_Modo_Configurar
        ldx Est_Pres_TConfig    ; Si lo es ejecutar Tarea
        jsr 0,x
        bra Fin_Tarea_Modo_Configurar
No_Modo_Configurar
        movw #TConfig_Est1,Est_Pres_TConfig ; si no devolverse al estado 1
Fin_Tarea_Modo_Configurar
        rts
        
;====================== Configurar    Estado 1 =================================
TConfig_Est1
        movw #MSG_CONFIGURAR_L1,MSG_L1   ;Mandar mensaje al LCD de Config
        movw #MSG_CONFIGURAR_L2,MSG_L2
        bclr Banderas_2,LCD_Ok
        movb #LDConfig,LEDS  ; Poner el Led de config
        ldaa VelUmbral    ; Mostrar la Velocidad de Umbral selecionada
        jsr Bin_BCD_MUXP
        movb #OFF,BCD2    ; Apagar el otro Display
        movb BCD,BCD1
        jsr BORRAR_NUM_ARRAY ; Borrar lo que hay en num_array
        movw #TConfig_Est2,Est_Pres_TConfig

        rts


;====================== Configurar   Estado 2 =================================
TConfig_Est2
        brclr Banderas_1,ArrayOK,Fin_TConfig_Est2 ; Ver si se ingreso algo
        bclr Banderas_1,ArrayOK ; borrar la bandera
        ldd Num_Array     ; Cargar las teclas ingresadas
        jsr BCD_Bin          ; Pasarlas a Binario
        ldaa ValorVelUmbral   ; Cargar resultado de BCD_BIN
        cmpa #Vmin           ; Verificar si estan el el rango adecuado
        blo No_Valido
        cmpa #Vmax
        bhi No_Valido
        jsr Bin_BCD_MUXP
        movb #OFF,BCD2      ; Mostrar el valor ingresado si es Valido
        movb BCD,BCD1
        movb ValorVelUmbral,VelUmbral
No_Valido                   ; si no es valido ignorarlo
        jsr Borrar_Num_Array
Fin_TConfig_Est2
        rts
        
;******************************************************************************
;                      TAREA MODO Separar
;******************************************************************************
Tarea_Modo_Separar
        ldaa Valor_DS  ;Ver si se seleccionó
        cmpa #$C0
        bne No_Modo_Separar
        ldx Est_Pres_TSeparar
        jsr 0,x
        bra Fin_Tarea_Modo_Separar
No_Modo_Separar
        movw #TSeparar_Est1,Est_Pres_TSeparar
Fin_Tarea_Modo_Separar
        rts

;====================== Separar  Estado 1 =================================
TSeparar_Est1
             bset LEDS,LDSeparar  ; Prender el Led de Separar
             bclr LEDS,LDStop
             bclr LEDS,LDConfig
             movw #MSG_SEPARAR_L1,MSG_L1    ; Mandar mensaje al LCD
             movw #MSG_SEPARAR_S1,MSG_L2
             bclr Banderas_2,LCD_Ok
             movb #OFF,BCD1              ; apagar displays
             movb #OFF,BCD2
             movw #TSeparar_Est2,Est_Pres_TSeparar
             rts
             
;====================== Separar  Estado 2 =================================
TSeparar_Est2
             brclr Banderas_1,LongP2,Fin_TSeparar_Est2 ; Esperar Inicio
             movw #MSG_SEPARAR_L1,MSG_L1    ; Mandar mensaje esperar P1
             movw #MSG_SEPARAR_S2,MSG_L2
             bclr Banderas_2,LCD_Ok
             movb #OFF,BCD1          ; apagar  Displays
             movb #OFF,BCD2
             bset PortRele,MaskRele  ; Activar centrifugadora

             bclr Banderas_1,ShortP2  ; Borrar ShortP2

             bclr Leds,LDRebase ; Apagar led de rebase
             
             movw #TSeparar_Est3,Est_Pres_TSeparar
Fin_TSeparar_Est2
             rts

;====================== Separar  Estado 3 =================================
TSeparar_Est3
             brclr Banderas_1,ShortP1,Fin_TSeparar_Est3 ; esperar P2
             bclr Banderas_1,ShortP1       ; si llegar borrar y activar timer
             movb #tTimerCal,TimerCal
             movw #MSG_SEPARAR_L1,MSG_L1 ; Mandar mensaja para P2
             movw #MSG_SEPARAR_S3,MSG_L2
             bclr Banderas_2,LCD_Ok
             
             movw #TSeparar_Est4,Est_Pres_TSeparar
             
Fin_TSeparar_Est3
             rts


;====================== Separar  Estado 4 =================================
TSeparar_Est4
             brclr Banderas_1,ShortP2,Fin_est4    ; esperar P2
             jsr Calcula     ;Calcular velocidad, TimerIniPant, TimerFinPant
             ldaa Velocidad  ; Ver si la velocidad esta en el rango
             cmpa #Vmin
             blo Fuera_Rango
             cmpa #Vmax
             bhi Fuera_Rango
             movw #MSG_SEPARAR_L1,MSG_L1 ; Mandar mensaje de timers
             movw #MSG_SEPARAR_S4,MSG_L2
             bclr Banderas_2,LCD_Ok
             ldab TimerIniPant ; Mostrar Timer en Segundos
             clra          ; Esta en 100 ms, por lo que se debe dividir
             ldx  #10
             idiv
             tfr x,a

             jsr Bin_BCD_MUXP
             movb BCD,BCD2
             
             ldab TimerFinPant   ; Mostrar Timer en Segundos
             clra                ; Esta en 100 ms, por lo que se debe dividir
             ldx  #10
             idiv
             tfr x,a
             jsr Bin_BCD_MUXP
             movb BCD,BCD1
             movw #TSeparar_Est5,Est_Pres_TSeparar
Fin_est4     bra Fin_TSeparar_Est4
Fuera_Rango
             movw #MSG_SEPARAR_S6,MSG_L1  ; Mandar Mensaje de error
             movw #MSG_SEPARAR_S7,MSG_L2
             bclr Banderas_2,LCD_Ok
             
             cmpa #99               ; Si es mayor que 99 mostrar guiones
             bhi Mostrar_Guiones
             
             jsr Bin_BCD_MUXP        ; Si no mostrarlo en los displays
             movb BCD,BCD1
             movb #OFF,BCD2
             bra Cargar_TimerError
Mostrar_Guiones
             movb #Guion,BCD1
             movb #Guion,BCD2
Cargar_TimerError
             clr TimerIniPant   ; Cargar el timerError y pasar al estado 6
             clr TimerFinPant
             movb #tTimerError,TimerError
             movw #TSeparar_Est6,Est_Pres_TSeparar
Fin_TSeparar_Est4
             rts

;====================== Separar  Estado 5 =================================
TSeparar_Est5
             tst TimerIniPant  ; Esperar que llegue la Tuerca
             bne Fin_TSeparar_Est5
             ldaa Velocidad     ; Comparar la  velocidad para separar cual
             cmpa VelUmbral     ; linea de empaque mandar
             bhi Mandar_LE1
             inc CantLE2        ; si es menor a la umbral mandar a LE2
             ldaa CantLE2
             bset LEDS,LDLE2
             bra Verificar_Rebase
Mandar_LE1
             inc CantLE1    ; Si es menor mandar a LE1
             ldaa CantLE1
             bset LEDS,LDLE1
Verificar_Rebase
             cmpa ValorRebase    ; Ver si se llego al valor Maximo
             bhi  Hubo_Rebase
             
             movw #MSG_SEPARAR_L1,MSG_L1   ; si no Mostrar mensaje de Vel Cant
             movw #MSG_SEPARAR_S5,MSG_L2
             bclr Banderas_2,LCD_Ok
             
             jsr Bin_BCD_MUXP   ; Mostrar la cantidad el display
             movb BCD,BCD1
             ldaa Velocidad      ; Mostrar la velocidad en el display
             jsr Bin_BCD_MUXP
             movb BCD,BCD2
             movw #TSeparar_Est7,Est_Pres_TSeparar
             bra Fin_TSeparar_Est5
Hubo_Rebase
            bclr PortRele,maskRele ; si hubo apagar centrifugo

            bclr Banderas_1,LongP2
            
            clr CantLE1                       ; borrar cantidades
            clr CantLE2
            
            bset LEDS,LDRebase ; Indicar rebase
            bclr LEDS,LDLE1   ; Apagar Leds
            bclr LEDS,LDLE2
            movw #TSeparar_Est1,Est_Pres_TSeparar
Fin_TSeparar_Est5
             rts

;====================== Separar  Estado 6 =================================
TSeparar_Est6
            tst TimerError ; Esperar TimerError y pasar al estado 2
            bne Fin_TSeparar_Est6
            movw #TSeparar_Est2,Est_Pres_TSeparar
Fin_TSeparar_Est6
             rts
;====================== Separar  Estado 7 =================================
TSeparar_Est7
             tst TimerFinPant   ; Esperar TimerFinPant
             bne Fin_TSeparar_Est7
             bclr LEDS,LDLE1        ;Apagar Leds
             bclr LEDS,LDLE2
             movw #TSeparar_Est2,Est_Pres_TSeparar

Fin_TSeparar_Est7
             rts
             
;******************************************************************************
;                       Tarea Brillo
;
;******************************************************************************
Tarea_Brillo
            ldx Est_Pres_TBrillo ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
            rts

;====================== Tarea Brillo Estado 1 ==================================
TBrillo_Est1
             movb #tTimerBrillo,TimerBrillo    ; Esperar nuevo ciclo
             movw #TBrillo_Est2,Est_Pres_TBrillo
             rts
;====================== Tarea Brillo Estado 2 ==================================
TBrillo_Est2
            tst TimerBrillo
            bne Fin_TBrillo_Est2  ; Iniciar ciclo de conversion
            movb #$87,ATD0CTL5
            movw #TBrillo_Est3,Est_Pres_TBrillo
Fin_TBrillo_Est2
            rts
;====================== Tarea Brillo Estado 3 ==================================
TBrillo_Est3
           brclr ATD0STAT0,SCF,Fin_TBrillo_Est3 ; esperar que termine mediciones
           ldd ADR00H
           addd ADR01H    ;Sacar promedio de las 4 mediciones
           addd ADR02H
           addd ADR03H
           lsrd
           lsrd
           ldx #255     ; Ponerlo en un rango de 0-1 con FDiv
           fdiv
           xgdx
           ldy #100    ; Ponerlo en rango de 0 100
           emul
           ldx #65535 ; Quitar el valor inducido por FDIV (2^16 - 1)
           ediv
           tfr y,a   ; Pasar la parte baja a B
           staa Brillo      ; Guardar Brillo
           movw #TBrillo_Est1,Est_Pres_TBrillo
Fin_TBrillo_Est3
           rts
           
;******************************************************************************
;                               Tarea Teclado
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
           bset PTP,LD_Red       ;Prender rojo
           bclr PTP,LD_Blue       ; apagar azul
           movw #LDTst_Est2,Est_Pres_LDTst
           movb #tTimerLDTst,Timer_LED_Testigo;inicia timer parpadeo led testigo
Fin_LDTst_Est1 rts

;=========================== Estado 2 ==========================================
LDTst_Est2
           tst Timer_LED_Testigo
           bne Fin_LDTst_Est2
           bset PTP,LD_Green     ; Prender Verde
           bclr PTP,LD_Red        ; Apagar Rojo
           movw #LDTst_Est3,Est_Pres_LDTst
           movb #tTimerLDTst,Timer_LED_Testigo;inicia timer parpadeo led testigo
Fin_LDTst_Est2
             rts

;=========================== Estado 3 ==========================================
LDTst_Est3
           tst Timer_LED_Testigo
           bne Fin_LDTst_Est3
           bset PTP,LD_Blue   ; prender azul
           bclr PTP,LD_Green  ; Apagar Verde
           movw #LDTst_Est1,Est_Pres_LDTst
           movb #tTimerLDTst,Timer_LED_Testigo;inicia timer parpadeo led testigo
Fin_LDTst_Est3
             rts


;******************************************************************************
;                               Tarea Leer PB2
;  Metodo para la implementacion de la maquina de estados Leer_PB1
; EL estado de partida se inicializa en la variable EstPres_LeerPB0
; en el programa pricipal
; En cada estado se actualiza EstPres_LeerPB0 Cargando la dirrecion del
; proximo estado
;******************************************************************************
Tarea_LeerPB2
            ldx EstPres_LeerPB2  ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado

FinTareaPB  rts
;====================== Leer PB Estado 1 =======================================
LeerPB2_Est1 brset PortPB,MaskPB2,FinPB2_Est1 ; Verificar si se presiono PB
             movb #tSubRebPB2,Timer_RebPB2 ; Si si cargar Timers
             movb #tShortP2,Timer_SHP2
             movb #tLongP2,Timer_LP2

             movw #LeerPB2_Est2,EstPres_LeerPB2 ; Pasar al estado 2
FinPB2_Est1   rts


;====================== Leer PB Estado 2 =======================================
LeerPB2_Est2 tst Timer_RebPB2   ; Verficar si ya cumplio el tiempo de rebotes
             bne FinPB2_Est2
             brset PortPB,MaskPB2,Volver_Est1 ; Verificar si sigue presionado
             movw #LeerPB2_Est3,EstPres_LeerPB2 ; si si pasar al estado 3
             bra FinPB2_Est2
Volver_Est1  movw #LeerPB2_Est1,EstPres_LeerPB2; Si no volver al estado 1
FinPB2_Est2  rts


;====================== Leer PB Estado 3 =======================================
LeerPB2_Est3  tst Timer_SHP2 ; Verificar el tiempo de Short Press
              bne FinPB2_Est3
              brset PortPB,MaskPB2,Volv_Est1 ; Verificar si sigue presionado
              movw #LeerPB2_Est4,EstPres_LeerPB2 ; si es asi pasar al estado 4
              bra FinPB2_Est3
Volv_Est1     bset Banderas_1,ShortP2 ; Si no Poner ShortPress y volver a estado1
              movw #LeerPB2_Est1,EstPres_LeerPB2
FinPB2_Est3   rts


;====================== Leer PB Estado 4 =======================================
LeerPB2_Est4  tst Timer_LP2 ; Verificar el tiempo Long Press
              bne Revisar_PB2 ; si se cumplió
              brclr PortPB,MaskPB2,FinPB2_Est4 ; ver si sigue presionado
              bset Banderas_1,LongP2 ; Poner LongPress
              Bra Reg_Est1
Revisar_PB2   brclr PortPB,MaskPB2,FinPB2_Est4; si no se cumpplio ver si sigue
              bset Banderas_1,ShortP2; Si no poner ShortPress
Reg_Est1      movw #LeerPB2_Est1,EstPres_LeerPB2  ; Volver al estado 1
FinPB2_Est4   rts


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
;                       Tarea Leer_DS
;
;******************************************************************************
Tarea_Leer_DS
            ldx Est_Pres_LeerDS ; Cargar el estado presente
            Jsr 0,x              ; Ejecutar el estado
            rts

;====================== Tarea Leer DS Estado 1 =================================
LeerDS_Est1
            ldaa PortPB   ; Leer el Puerto
            anda #$C0     ; Tomar los dos bits mas significativos (PH.7 y PH.6)
            staa Temp_DS   ; Guardar el valor leido
            movb #tTimerRebDS,Timer_RebDS
            movw #LeerDS_Est2,Est_Pres_LeerDS
             rts
;====================== Tarea Leer DS Estado 2 =================================
LeerDS_Est2
            tst Timer_RebDS    ; suprimir rebotes
            bne Fin_LeerDS_Est2
            ldaa PortPB      ; Leer de nuevo el puerto
            anda #$C0
            cmpa Temp_DS   ; comparar con lo antes leido
            bne No_Guardar_DS
            movb Temp_DS,Valor_DS  ; si es igual guardar
No_Guardar_DS
            movw #LeerDS_Est1,Est_Pres_LeerDS
Fin_LeerDS_Est2
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
              ; Verificar cual Diplay toca poner el dato
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
             ; si no corresponde al display, es a los LEDS y reiniciar ciclo
             Bclr PTJ,$02
             movb LEDS,PORTB
             clr Cont_Dig
             bra Incre_Cont_Dig

            ; Multiplexar el contenido de las pantallas
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
            ; incrementar Cont_dig y inicializar contador de ticks para brillo
Incre_Cont_Dig inc Cont_Dig
               movw #MaxCountTicks,Counter_Ticks
               movw #PantallaMUX_Est2,EstPres_PantallaMUX
Fin_PantallaMUX_Est1
                rts

;====================== Pantalla MUX Estado 2 ==================================
PantallaMUX_Est2       ; esperar que llegue el brillo adecudado
                ldd Counter_Ticks
                cmpb Brillo
                bhi Fin_PantallaMUX_Est2
                bset PTP,$0F
                bset PTJ,$02
                movw #PantallaMUX_Est1,EstPres_PantallaMUX
Fin_PantallaMUX_Est2
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
            movb #ADD_L1,CharLCD        ; iniciar en linea 1
            movw MSG_L1,Punt_LCD
            bra Mandar_Char
Mandar_L2   movb #ADD_L2,CharLCD     ; iniciar en linea 2
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
            movb 1,x+,CharLCD          ; Mandar los datos
            stx Punt_LCD
            ldaa CharLCD
            cmpa #EOB
            bne No_Enviado
            brset Banderas_2,Second_Line,Terminar_LCD  ; Si se mando verificar
            bset Banderas_2,Second_Line                ; Segunda Fila
            bra Reg_est1_TareaLCD
Terminar_LCD
            bclr Banderas_2,Second_Line
            bset Banderas_2,LCD_OK
Reg_est1_TareaLCD
            movw #TareaLCD_Est1,EstPres_TareaLCD
            bra Fin_TareaLCD_Est2
No_Enviado  jsr Tarea_SendLCD  ; Seguir enviando el dato
Fin_TareaLCD_Est2
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
              anda #$F0    ; Colocar dato en PortK.5 a PortK.2
              lsra
              lsra
              staa PortK

              brset Banderas_2,RS,Poner_RS1 ; Ver si es comando
              bclr PortK,RS

              bra  Poner_Enable1
Poner_RS1     bset PortK,RS
Poner_Enable1 bset PortK,ENABLE ; Mandar enable
              movw #tTimer260uS,Timer260uS
              movw #SendLCD_Est2,EstPres_SendLCD

            rts

;====================== SendLCD Estado 2 ==================================
SendLCD_Est2
              ldd Timer260uS  ; esperar que procese el dato
              bne Fin_SendLCD_Est2

              bclr PortK,ENABLE   ; quitar enable

              ldaa CharLCD
              anda #$0F
              lsla           ; Colocar dato en PortK.5 a PortK.2
              lsla
              staa PortK
              brset Banderas_2,RS,Poner_RS2  ; ver si es comando
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
             ldd Timer260uS  ;esperar que procese el dato
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
             bset Banderas_2,FinSendLCD   ; Indicar que se mando el dato
             movw #SendLCD_Est1,EstPres_SendLCD

Fin_SendLCD_Est4
            rts
            
;*******************************************************************************
;                  SUBRUTINA  BCD_BIN
;*******************************************************************************

BCD_Bin
           cmpb #$FF
           beq Solo_Unidades
           stab ValorVelUmbral
           ldab #10
           mul
           addb ValorVelUmbral
           stab ValorVelUmbral
           bra Fin_BCD_Bin
Solo_Unidades
          staa ValorVelUmbral
Fin_BCD_Bin
           rts
           
;*******************************************************************************
;                          SUBRUTINA  Calcula
;*******************************************************************************
Calcula
        ;Delta T : tTimerCal - TimerCal
        ldaa #tTimerCal
        suba TimerCal
        staa DeltaT

        ; Velocidad  = DeltaS/DeltaT, unidades cm/s -> DeltaT base 100ms
        ; Hay que dividir entre 10 a DeltaT pero v=DeltaS\(DeltaT/10)
        ; -> (DeltaS*10)/DeltaT
        ldaa #DeltaS
        ldab #10
        mul
        xgdx
        ldab DeltaT
        clra
        xgdx
        idiv
        tfr x,b
        stab Velocidad


        ;TimerIniPant = (DeltaE-(DeltaM-DeltaS))/Velocidad
        ldab #DeltaE
        subb #DeltaM
        subb #DeltaS
        clra
        xgdx
        ldab Velocidad
        clra
        xgdx
        idiv
        tfr x,b
        ldaa #10
        mul
        stab TimerIniPant

        ;TimerFinPant = (DeltaE-DeltaS)/Velocidad

        ldab #DeltaE
        subb #DeltaS
        clra

        xgdx

        ldab Velocidad
        clra

        xgdx

        idiv

        tfr x,b
        ldaa #10
        mul
        stab TimerFinPant
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
              lsra        ;Pasar al nibble inferior
              lsra
              lsra
              lsra
              movb a,x,Dsp1 ; acceder Segment
              ldaa BCD2
              anda #$0F    ; Extraer el nibble inferior
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