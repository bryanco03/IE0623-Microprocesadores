#include registers.inc
;*******************************************************************************
;              Relocalizacion de vector de interrupcion
;*******************************************************************************
          ; Vector de RTI
	    org $3E70
        dw RTI_ISR
          ; Vector de OC7
            org $3E60
        dw OC7_ISR
        ; Vector de Port H.0
            org $3E4C
        dw PORTH_ISR
;*******************************************************************************
;                         Definicion de Variables
;*******************************************************************************
PeriodoRTI        EQU $54
Hab_RTI           EQU $80
PowON_ECT         EQU $80
PRS_ECT           EQU $0D
HAB_O7            EQU $80
HAB_PTH           EQU $01
Carga_RTI         EQU 200
Carga_OC7         EQU 5
Carga_TC7         EQU 37500
LD_PB7            EQU $80
;*******************************************************************************
;                         Declaracion de estructuras de Datos
;*******************************************************************************
                        org $1000
CONT_INT          ds 1
;*******************************************************************************
;                      Configuracion de Hardware
;*******************************************************************************
                                      org $2000
          ;Habilitar LED
          bset DDRB,LD_PB7   ; Poner el puerto del Led como salida
          bset DDRJ,$02     ; Habiltar LED
          bclr PTJ,$02
          
          ;  Apagar Displays  de 7 Segmentos
          movb #$0F,DDRP
          movb #$0F,PTP
          
          ; Cargar periodo RTI
          movb #Carga_RTI,RTICTL
          ; Habiltar RTI
          movb #Hab_RTI,CRGINT
          ; Configurar MODULO TCM

          movb #PRS_ECT,TSCR2  ; Cargar el preescalador
          movb #HAB_O7,TIOS    ; Definirlo como 7
          ; Configurar Puerto H (Key Wake up)
          bset PIEH,HAB_PTH
          bclr PPSH,HAB_PTH  ; activo del flanco decreciente
;*******************************************************************************
;                           Programa Principal
;*******************************************************************************
          movb #Carga_RTI,CONT_INT ; Cargar CON_INT para RTI
          lds #$3BFF               ; definir pila
          cli                      ; Habiltar interrupciones mascarables
          bset PORTB,LD_PB7        ; Encender Led
          bra *
;*******************************************************************************
;             Subrutina de interrupcion puerto H Key wake up
;*******************************************************************************
PORTH_ISR      ; Suprimir Rebotes
              ldd #13000
Sup_rebotes   subd #1
              bne Sup_rebotes
              
              brset CRGINT,Hab_RTI,Hab_OC  ; Verificar si RTI esta habilitado
              
              movb #Hab_RTI,CRGINT ; Si no esta, Habilitarlo
              bclr TSCR1,PowON_ECT ; Deshabilitar OC7
              bclr TIE,HAB_O7
              movb #Carga_RTI,CONT_INT ; Cargar CONT_INT
              bra Fin_PORTH_ISR
              
Hab_OC        bclr CRGINT,#Hab_RTI ; Si estaba habilitarlo, Dehabilitarlo
              bset TSCR1,PowON_ECT; Habilitar OC7
              bset TIE,HAB_O7
              movw #Carga_TC7,TC7 ; Cargar TC7
              movb #Carga_OC7,CONT_INT  ; Cargar Con_Int para OC7
              
              
Fin_PORTH_ISR
             bset PIFH,HAB_PTH   ; borrar Bandera
              rti

;*******************************************************************************
;             Subrutina de interrupcion OC7
;*******************************************************************************
OC7_ISR
         dec CONT_INT  ; Decrementar Cont
         bne FIN_OC7_ISR   ; Si ya paso el tiempo
         bclr TSCR1,PowON_ECT ; Apagar OC7
         bclr TIE,HAB_O7
         movb #Hab_RTI,CRGINT ; Habiltar RTI
         ldaa PORTB       ; Toggle al Led
         eora #LD_PB7
         staa PORTB

         movb #Carga_RTI,CONT_INT ; Cargar CONT_INT para RTI

FIN_OC7_ISR
         bset TFLG1,HAB_O7   ; Cargar CONT_INT;
         rti
;*******************************************************************************
;             Subrutina de interrupcion OC7
;*******************************************************************************
         
RTI_ISR
        dec CONT_INT     ;  decrementar Cont
        bne FIN_RTI_ISR  ; Si ya paso el tiempo
        bclr CRGINT,HAB_RTI ; Deshabiltar RTI
        bset TSCR1,PowON_ECT  ; Habiltar 0C7
        bset TIE,HAB_O7
        movw #Carga_TC7,TC7          ; Cargar TC7
        movb #Carga_OC7,CONT_INT
        
        ldaa PORTB       ; Toggle al Led
        eora #LD_PB7
        staa PORTB

FIN_RTI_ISR
        bset CRGFLG,HAB_RTI ; Borrar Bandera de interrupcion
        rti

