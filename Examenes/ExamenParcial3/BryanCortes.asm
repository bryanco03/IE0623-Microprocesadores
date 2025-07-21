;*******************************************************************************
;                            Tercer Parcial Parte 2
; Bryan Cortés Espínola C22422
;
;*******************************************************************************
#include registers.inc
;*******************************************************************************
;                                Valores
;*******************************************************************************
; Caracteres ASCII
CR:       EQU $0D
LF:       EQU $0A
NP:       EQU $0C

i:        EQU $69
p:        EQU $70
f:        EQU $66


; Indicador de final de mensaje
EOM:      EQU $FF

; Valores para los bits de los perifericos
; Transmisor
TDRE      EQU $80
TE        EQU $08
; Receptor
RE        EQU $04
RDRF      EQU $20
; Fin de conversion ATD
SCF       EQU $80


;*******************************************************************************
;                  Definicion de  Estructura de datos
;*******************************************************************************
                org $1000
CntrATD      ds 1
Punt_Com     ds 2
EP_TareaCom  ds 2
EP_LeerATD   ds 2
;*******************************************************************************
;                               Mensajes
;*******************************************************************************
              org $1010

msg          fcc "     Universidad de Costa Rica"
             db CR, LF
             fcc "   Escuela De Ingeneria Electrica"
             db CR, LF
             fcc "        Microprocesadores"
             db CR, LF
             fcc "              IE0623"
             db CR, LF, CR, LF
             fcc "Ingrese una (i) para iniciar o una (p) para parar"
             db CR, LF, CR, LF
             fcc "Si desea terminar ingrese una (f): "
             db EOM
;*******************************************************************************
;                      Configuracion del Hardware
;*******************************************************************************

                              org $2000
               ; Configuracion del SCI
                movw #39,SC1BDH ; a 38400 bps
                movb #$00,SC1CR1 ; Sin Paridad
                movb #$08,SC1CR2 ; Habiltar Transmisor

                ldaa SC1SR1
                movb #$00,SC1DRL
                
                ; Coonfiguracion de los Leds
                movb #$FF,DDRB ; Configurar los Leds como salidas
                movb #$00,PortB ; Habilitar Leds
                bset DDRJ,$02

                ; Configurar ATD
                movb #$C0,ATD0CTL2
                ldaa #160       ; Delay de 10us
Espere_ATD      dbne a,Espere_ATD

                movb #$08,ATD0CTL3 ; un ciclo de conversion
                movb #$97,ATD0CTL4 ; 2 ciclos de muestreo
                                   ; 8 bits
                                   ; prs = 23


;*******************************************************************************
;                          Programa Principal
;*******************************************************************************
                        ; Definir Pila
                        lds #$3BFF
                        ; Inicializar Variables de estado
                        movw #TareaCom_Est1,EP_TareaCom
                        movw #LeerATD_Est1,EP_LeerATD
                        ; Borrar CntrATD
                        clr CntrATD
                        
;******************************************************************************
;                          Despachador de Tareas
;******************************************************************************
Despachador_Tareas
                      jsr Tarea_COM
                      jsr Tarea_LeerATD
                      bra Despachador_Tareas

;******************************************************************************
;                               TAREA COM
;******************************************************************************
Tarea_COM
                ldx EP_TareaCom
                jsr 0,x
FinATD          rts

;================================= TareaCom Estado 1 ===========================
TareaCom_Est1
                ; Cargar msg en Punt_Com
                ldx #msg
                stx Punt_Com
                
                ; Mandar NP a transmitir
                ldaa SC1SR1
                movb #NP,SC1DRL
                
                ; Pasar al estado 2
                movw #TareaCom_Est2,EP_TareaCom
                
                rts
;================================= TareaCom Estado 2 ===========================
TareaCom_Est2
                ; Transmisor Disponible?
                brclr SC1SR1,TDRE,Fin_TareaCom_Est2
                
                ; Cargar Caracter en a
                ldx Punt_Com
                ldaa 0,x
                ; Ver si es el fin de mensaje
                cmpa #EOM
                beq Encender_Receptor
                ; Transmitir caracter
                staa SC1DRL
                inx ; pasar a otro Caracter
                stx Punt_Com; Guardar puntero
                bra Fin_TareaCom_Est2
                
Encender_Receptor
                bclr SC1CR2,TE ; Apagar Transmisor
                bset SC1CR2,RE ; Encender Transmisor
                ; Pasar al estado 3
                movw #TareaCom_Est3,EP_TareaCom
Fin_TareaCom_Est2
                rts
;================================= Tarea Com Estado 3 ==========================
TareaCom_Est3
               ; Caracter en el Receptor?
               brclr SC1SR1,RDRF,Fin_TareaCom_Est3
               ; Ver si es "i"
               ldaa SC1DRL
               cmpa #i
               beq Poner_Caracter
               ; Ver si es "p"
               cmpa #p
               beq Poner_Caracter
               ; Ver si es "f"
               cmpa #f
               bne Fin_TareaCom_Est3
               ; Si es f, Borrar CntrATD
               clr CntrATD
               bra Fin_TareaCom_Est3
Poner_Caracter
              ; poner caracter
              staa CntrATD
              bset SC1CR2,TE ; Encerder Transmisor
              bclr SC1CR2,RE ; Apagar Receptor
              ; Pasar al estado 1
              movw #TareaCom_Est1,EP_TareaCom
Fin_TareaCom_Est3
                rts


;******************************************************************************
;                               TAREA LeerATD
;******************************************************************************
Tarea_LeerATD
                ldx EP_LeerATD
                jsr 0,x
                rts

;============================= LeerATD Estado 1================================
LeerATD_Est1
                ldaa CntrATD
                ; Ver si se ingresó una "i"
                cmpa #i
                beq Iniciar_ATD
                ; Ver si se ingresó una "p"
                cmpa #p
                bne Apagar_LEDs
                bra Fin_LeerATD_Est1
                
Apagar_LEDs     ; Apagar Leds
                movb #$00,PortB
                bra Fin_LeerATD_Est1

Iniciar_ATD     ; Iniciar ciclo de conversion
                movb #$85,ATD0CTL5
                movw #LeerATD_Est2,EP_LeerATD
Fin_LeerATD_Est1
                rts

;============================= LeerATD Estado 2================================
LeerATD_Est2
                 ; Ver  si se Termino ciclo de Conversion A/D
                 brclr ATD0STAT0,SCF,Fin_LeerATD_Est2
                 ; Cargar el Valor Leido
                 ldd ADR00H
                 ; Pasar Parte baja a los Leds
                 stab PortB
                 ; Devolverse al estado 1
                 movw #LeerATD_Est1,EP_LeerATD
Fin_LeerATD_Est2
                rts