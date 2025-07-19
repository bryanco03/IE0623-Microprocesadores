;*******************************************************************************
;                                Selector
;*******************************************************************************

 ; Autor : Bryan Cortes Espinola C22422
 ; Version : 0.1
 ; Descripcion: Realiza la operación XOR entre los últimos elementos de la
 ; tabla Datos (con signo, termina en $80) y los primeros de
 ; Mascaras (sin signo, termina en $FE), en orden inverso.
 ; Guarda en un arreglo (apuntado por Puntero) los resultados
 ; negativos.


;*******************************************************************************
;                          Estructuras de Datos
;*******************************************************************************
                        ORG $1000
Puntero: dw $1300

Datos    EQU $1050
Mascaras EQU $1150
                        ORG Datos
Tabla_datos:    dB  $8D, $7F, $80
                   ;$71, $BB, $F7, $80
                   ;$B4, $71, $BB, $F7, $80
                  
                        ORG Mascaras
Tabla_mascaras: dB $AD, $AB, $CD, $F7, $FE
                  ;$74, $31, $CD, $FE

;*******************************************************************************
;                          Progama Principal
;*******************************************************************************
                        ORG $2000
                ldx #Mascaras      ; X apunta al inicio de la tabla Mascaras
                ldy #Datos         ; Y apunta al inicio de la tabla Datos
                clra               ; A se usara como índice para recorrer Datos
loop_datos      ldab a,y           ; B <- Datos[A]
                cmpb #$80          ; ¿Es el final de la tabla?
                beq fin_datos      ; Sí -> salir del bucle
                inca               ; A++
                bra loop_datos
fin_datos       tsta
                beq fin
                deca
loop_mascaras   ldab 1,x+          ; B <- máscara, avanza X
                cmpb #$FE          ; ¿Fin de tabla Mascaras?
                beq fin            ; Sí -> fin
                eorb a,y
                bpl comparar_a     ; Si el resultado es positivo, no guardar
guardar_neg     ldy Puntero        ; Y <- dirección de almacenamiento
                stab 0,y           ; Guardar resultado negativo
                iny
		sty Puntero        ; puntero ++
                ldy #Datos         ; Restaurar Y a inicio de Datos
comparar_a      tsta               ; ¿A == 0?
                beq fin            ; Sí -> terminó de procesar
                deca               ; A--
                bra loop_mascaras
fin             bra *
                