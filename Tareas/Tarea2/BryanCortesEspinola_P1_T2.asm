;*******************************************************************************
;                                Divisor
;*******************************************************************************

 ; Autor : Bryan Cortes Espinola C22422
 ; Version : 0.1
 ; Descripcion:  Este Programa toma una tabla de valores de tamaño Long y coloca
 ; los valores divisibles por 4 en la tabla con origen en Div

;*******************************************************************************
;                          Estructuras de Datos
;*******************************************************************************
                        ORG $1000
Long:    db 10
Cant_4:  ds 1

Datos    EQU $1100
Div_4    EQU $1200
                        ORG Datos
Tabla: dB $08, $A2, $FB, $93, $C4, $E7, $32, $10, $EC, $54


;*******************************************************************************
;                          Progama Principal
;*******************************************************************************
                        ORG $2000
                ldx #Datos        ; X apunta a la tabla de datos
                ldy #Div_4        ; Y apunta a la tabla de salida
                clr Cant_4        ; Inicializa contador
loop            ldaa 1,x+         ; Toma el valor actual y avanza X
                bita #$03         ; ¿Es divisible por 4?
                bne no_divisible  ; Si no lo es, salta
                ldab Cant_4       ; Cargar el contador de numeros divisibles
                staa b,y          ; Guardar en Div_4
                inc Cant_4        ; Incrementar el contador
no_divisible    dec Long          ; Decrementar el contador de Datos
                bne loop          ; Repetir si no es cero
                bra *


        