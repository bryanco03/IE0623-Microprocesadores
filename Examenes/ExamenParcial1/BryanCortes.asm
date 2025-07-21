;*******************************************************************************
;                     Examen Parcial 1 Parte II Codificacion
;    Autor: Bryan Cort�s Esp�nola  C22422
;    Fecha de Realizacion : 16/5/2025
;*******************************************************************************


;*******************************************************************************
;             Declaracion de las estructuras de datos
;*******************************************************************************
                                      org $1000
; Variables
Banderas         ds 1
Indice           ds 1
; Etiquetas
Flag             equ $01
Valor1           equ 63
Valor2           equ 40
                           org $1010
Fuente           dw $3837
                 dw $3435
                 dw $3735
                 dw $3333
                 dw $3234
                 dw $3934
                 dw $3731
                 dw $3632
                 dw $3331
                 dw $3035
                 dw $3430
                 dw $ffff

			   org $1030
Destino
;*******************************************************************************
;                         Programa Principal
;*******************************************************************************
                           org $2000
             lds #$4000    ; Inicializar la pila
             ldy #Destino  ; Y apunta a Destinos
             ldx #Fuente   ; X Apunta a Fuente
             clrb          ; Borrar B
             bset Banderas,#Flag ; Poner 1 en Flag
loop         ldaa b,x      ; Aceder al primer valor
             incb          ; Incrementar el indice para el barrido de la tabla
             cmpa #$FF     ; Verificar Si es el fin de la tabla
             beq Evaluar_Flag ; Si es Verificar la bandera
             stab Indice    ; Guardar el indice
             ldab b,x       ; Cagar la otra parte del dato
             inc Indice     ; Incrementar el indice
             jsr Conversion ; Subrutina Conversion Ascii -> Bin
             brclr banderas,#Flag,No_Impar ; Ver si se debe buscar si es impar
             bita #Flag     ; Verificar si es Impar
             beq No_Guardar ; Si no lo es no guardar
             cmpa #Valor1   ; Ver si es menor que 63
             blo No_Guardar ; Si es menor no Guardar
Guardar      staa 1,y+      ; Guardar Valor
             bra No_Guardar
No_Impar     cmpa #Valor2   ; Ver si es menor que 40
             bhs No_Guardar ; Si es mayor no Guardar
             bra Guardar
No_Guardar  ldab Indice ; Cagar el indice y repetir loop
             bra loop
Evaluar_Flag brclr Banderas,#Flag,Fin ; Comprobar si ya se Hicieron 2 pasadas
             bclr Banderas,#Flag ; Si no borrar Flag y B Y repetir Loop
             clrb
             bra loop
Fin          bra *
;*******************************************************************************
;                        Subrutina  Conversion
;*******************************************************************************
Conversion               pshd      ; Guardar D en la Pila
                         suba #$30 ; Extraer el valor numerico
                         ldab #10  ; Cargar 10 En A para luego multiplicar
                         mul       ; (Multiplicar por la posicion Decimal)
                         leas 1,sp ; Desplazar sp para la parte baja de D
                         pula      ; Sacar la parte Baja de la pila
                         suba #$30 ; Extraer el Valor numerico
                         aba       ; Sumarlo con el anterior Valor extraido
                         rts


             







