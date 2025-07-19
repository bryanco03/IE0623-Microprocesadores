 ;*******************************************************************************
;                                Conversiones
;*******************************************************************************

 ; Autor : Bryan Cortes Espinola C22422
 ; Version : 0.1
 ; Descripcion:Este progama pasa un numero binario de 12 bits a una codificacion
 ; BCD usando el algoritmo XS3 implementado en Bin_BCD, tambien se pasa un
 ; numero en BCD menor o igual a 99 a Bin usando el método de multiplicación
 ; de décadas y suma

;*******************************************************************************
;                          Estructuras de Datos
;*******************************************************************************
                        ORG $1000
Binario:     dw $0FFF
BCD:         dw $4732
num_shift:   db 11
temp:        ds 2
temp_nibble: ds 1
                        ORG $1010
num_BCD    ds 2
                        ORG $1020
num_Bin    ds 2



;*******************************************************************************
;                          Progama Principal
;*******************************************************************************
                        ORG $2000
                 ldd Binario
                 bra Bin_BCD
seguir_BCD       ldd BCD
                 bra BCD_Bin
fin              bra *
                        
;*******************************************************************************
;                          BCD a BIN
;*******************************************************************************
Bin_BCD               ldy #$0010
               emul              ;D = Binario × 16, desplazamiento de 4 bits
               clr num_BCD       ; Poner ceros al resultado
               clr num_BCD+1
desplazar_bit  lsld              ; Desplaza D a la izquierda, msb -> Carry
               rol num_BCD+1     ; Rota el byte bajo de BCD
               rol num_BCD       ; Rota el byte alto de BCD
               std temp          ; Guarda D temporalmente
               ldd num_BCD       ; Carga num_BCD en D (A=alto, B=bajo)
               andb #$0F         ; Aísla el nibble bajo (primer dígito BCD)
               cmpb #$05         ; Compara con 5
               blo segundo_nibble; Si es <5, salta
               addb #$03         ; Si es >=5, suma 3
segundo_nibble stab temp_nibble   ; Guarda el nibble ajustado temporalmente
               ldab num_BCD+1     ; Carga el byte bajo de BCD
               andb #$F0          ; Aísla el segundo nibble (segundo dígito BCD)
               cmpb #$50
               blo tercer_nibble  ; Si es <5, salta
               addb #$30          ; Si es >=5, suma
tercer_nibble  addb temp_nibble   ; Une con el nibble bajo ajustado
               stab num_BCD+1     ; Guarda el byte bajo de BCD actualizado
               anda #$0F          ; Aísla el Tercer nibble(tercer dígito BCD)
               cmpa #$05          ; Compara con 5
               blo cuarto_nibble  ; Si es <5, salt
               adda #$03          ; Si es >=5, suma
cuarto_nibble  staa temp_nibble   ; Guarda el nibble ajustado
               ldaa num_BCD       ; Carga el byte alto de BCD
               anda #$F0          ; Aísla el nibble más alto (cuarto dígito BCD)
               adda temp_nibble   ; Combina con el nibble anterior ajustado
               staa num_BCD       ; Guarda el byte alto de BCD actualizado
               ldd temp           ; Recupera D (valor binario desplazado)
               dec num_shift      ; Decrementa el contador
               bne desplazar_bit  ; Si no es cero, repite el bucle
               lsld               ; Desplazamiento final (bit 12)
               rol num_BCD+1
               rol num_BCD
               bra seguir_BCD
                

;*******************************************************************************
;                          BCD a BIN
;*******************************************************************************

BCD_Bin        std temp
	       clr num_Bin
               clr num_Bin+1  ; Limpiar num_BCD
               andb #$0F      ; Sacar el primer nibble
               stab num_Bin+1 ; Guardarlo en la parte baja de num_Bin
               ldab temp+1
               andb #$F0      ; Sacar el segundo nibble
               lsrb           ; Ubicar el nibble a la derecha
               lsrb
               lsrb
               lsrb
               ldaa #$0A      ; Cargar 10 para luego multplicar
               mul
               addb num_Bin+1 ; sumar el resultado con el anterior nibble
               stab num_Bin+1
               ldab temp      ; Cargar la parte alta de BCD
               andb #$0F      ; Sacar el tercer nibble
               ldy #$0064     ; Cargar 100 (decimal) para luego multiplicar
               emul
               addd num_Bin   ; Se suma con los anteriores nibbles
               std num_Bin
               clra
               ldab temp
               andb #$F0      ;ultimo Nibble
               lsrb           ;Ubicar el nibble a la derecha
               lsrb
               lsrb
               lsrb
               ldy #$03E8     ; Cargar 1000 (decimal) para luego multiplicar
               emul
               addd num_Bin
               std num_Bin
               lbra fin

                

                
                

                