;*******************************************************************************
;                               IoT
;*******************************************************************************

 ; Autor : Bryan Cortes Espinola C22422
 ; Version : 0.1
 ; Descripcion: implementa un sistema IoT que procesa datos numéricos en formato
 ; ASCII El programa inicia solicitando al usuario un número entre 1-50
 ;(validado) que determina cuántos datos procesar, luego realiza las
 ; conversiones mediante subrutinas especializadas (ASCII_BIN para la conversión
 ; y Mover para la separación en nibbles), y finalmente muestra los resultados
 ; formateados en la terminal, incluyendo contadores y listas de valores
 ; separados por comas, antes de reiniciar el ciclo para nuevo procesamiento.

;*******************************************************************************
;                          Estructuras de Datos
;*******************************************************************************
;  Caracteres ASCII
NULL:     equ $00
CR:       equ $0D
LF:       equ $0A
; Subrutinas del Debugger
GetChar   equ $EE84
PutChar   equ $EE86
PrintF    equ $EE88

; Direcciones
Datos_IoT equ $1500
Datos_Bin equ $1600
Punteros  equ $1010
RAM       equ $1000
Programa  equ $2000
Mensajes  equ $1030

                                ORG RAM
cant:              db $14
cont:              ds 1
offset:            ds 1
ACC:               ds 2
                                ORG Punteros
nibble_UP          dw $1700
nibble_MED         dw $1800
nibble_LOW         dw $1900
                                ORG Mensajes
MSG:               fcc "INGRESE EL VALOR DE CANT(ENTRE 1 Y 50): "
                   db NULL
MSG_cont           db CR, LF, CR, LF
                   fcc "CANTIDAD DE VALORES PROCESADOS: %X"
                   db CR, LF, CR, LF, NULL
MSG_nibble_coma fcc "%X, "
                db NULL
MSG_nibble      fcc "%X"
                db CR, LF, CR, LF, NULL
MSG_nibble_UP   fcc "Nibble_UP: "
                db NULL
MSG_nibble_MED  fcc "Nibble_MED: "
                db NULL
MSG_nibble_LOW  fcc "Nibble_LOW: "
                db NULL
                                ORG Datos_IoT
                  fcc "0129"
                  fcc "0729"
                  fcc "3954"
                  fcc "1875"
                  fcc "0075"
          
                  fcc "1536"
                  fcc "0534"
                  fcc "2755"
                  fcc "2021"
                  fcc "0389"
          
                  fcc "0000"
                  fcc "1329"
                  fcc "1783"
                  fcc "0009"
                  fcc "2804"
          
                  fcc "0064"
                  fcc "0128"
                  fcc "0256"
                  fcc "0512"
                  fcc "4095"

;*******************************************************************************
;                          Progama Principal
;*******************************************************************************
                        ORG Programa
              lds #$3BFF   ; Inicializar puntero de pila
              jsr Get_Cant ; Obtener cantidad de datos a procesar
              ldx #Datos_IoT ; X = Origen (datos ASCII de entrada)
              ldy #Datos_Bin ; Y = Destino (datos binarios convertidos)
              pshy          ; Guardar destino en pila (parámetro para ASCII_BIN)
              pshx          ; Guardar origen en pila (parámetro para ASCII_BIN)
              jsr ASCII_BIN  ; Convertir 'cant' datos de ASCII a binario
              ldx #Datos_Bin ; Cargar datos binarios para procesamiento
              jsr mover     ; Organizar datos en nibbles (UP, MED, LOW)
              jsr Imprimir   ; Imprimir los datos procesados en terminal
              bra *
              
;*******************************************************************************
;                       Subrutina Get_Cant
; Descripcion:Obtener una cantidad entre 1-50 del usuario mediante entrada
; por teclado
; Entradas:
;   - MSG: Mensaje a mostrar para solicitar entrada
; Salidas:
;   - cant: Variable donde se almacena la cantidad válida ingresada
;*******************************************************************************

Get_Cant      ldd #MSG ; Cargar mensasje
              ldx #$0  ; Inicializar X (necesario para PrintF)
              jsr [PrintF,x] ; Mostrar el mensaje en terminal
Primer_Char   ldx #$0 ; Inicializar X (necesario para GetChar)
              jsr [GetChar,x] ; Obtener caracter
              cmpb #$30 ; Comparar si no se ingreso un numero
              blt Primer_Char ; Si es menor no es valido
              cmpb #$35 ; Comparar si el numero ingresado es mayor que 5
              bhi Primer_Char ; Si mayor no es valido
              ldx #$0  ; Inicializar X (necesario para PutChar)
              jsr [PutChar,x]; mostrar carracter
              andb #$0F ; Obtener el numero ingresado
              ldaa #$0A ; Cargar 10 en A
              mul        ; Multplicar
              stab cant  ; Guardar decenas temporalmente
Segundo_Char  ldx #$0
              jsr [GetChar,x] ; Leer segundo carácter
              cmpb #$30 ; Comparar si no se ingreso un numero
              blt Segundo_Char
              cmpb #$39 ; Comparar si no se ingreso un numero
              bhi Segundo_Char
              aba       ; Pasar B a A, A = 0
              anda #$0F ; Convertir segundo dígito a numérico
              adda cant ; Sumar decenas + unidades
              cmpa #$32  ; Comparar con 50
              bhi Segundo_Char ; Si es mayor que 32, pedir de nuevo
              tsta        ; Verificar si es cero
              beq Segundo_Char  ; Si es cero, pedir de nuevo
              staa cant    ; Guardar cantidad final (1-32)
              clra        ; Limpiar A
              ldx #$0     ; Preparar X para PutChar
              jsr [PutChar,x]; Mostrar segundo dígito
              rts
;*******************************************************************************
;                          Subrutina ASCII_BIN
; Descripcion: Convertir números ASCII (4 dígitos) a formato binario de 12 bits
; Entradas:
;   - Pila: Contiene puntero a Datos_IoT (ASCII) y Datos_bin (destino)
;   - cant: Cantidad de números a convertir (variable en memoria)
; Salidas:
;   - Datos_bin: Array con valores binarios convertidos
;   - cont: Contador de datos procesados
;   - offset: Posición actual en Datos_IoT
;*******************************************************************************

ASCII_BIN     leas 2,sp   ; Colocar el sp donde estas las direcciones
              pulx        ; Datos_IoT
              puly        ; Datos_bin
              clr offset  ; Reinicicar el offset
              clr cont    ; Reiniciar la cantidad de datos procesado
loop          ldaa offset ; Cargar offset actual
              ldab a,x    ; acceder el dato de Datos_Iot
              andb #$0F   ; Obtener Valor numerico
              clra        ; Borrar a
              pshy        ; Guardar Datos_IoT
              ldy #$03E8  ; Cargar 1000
              emul        ; multiplicar X * D
              std ACC     ; Guardar el resultado en ACC
              puly        ; Recuperar Datos_IoT
              inc offset  ; Mover el offset al siguiere digito
              ldaa offset ; Cargar offset actual
              ldab a,x    ; Cargar el proximo digito
              andb #$0F   ; obtener el valor
              ldaa #$64   ; Cargar 100
              mul
              addd ACC    ; Sumar con los resultados anteriores
              std ACC     ; Guardar
              inc offset
              ldaa offset
              ldab a,x    ; Cargar el proximo digito
              andb #$0F   ; obtener el valor
              ldaa #$0A
              mul         ; Multiplicar dígito por 10
              addd ACC    ; Sumar al acumulado
              std ACC     ; Guardar resultado
              inc offset
              ldaa offset
              ldab a,x    ; Leer último dígito
              andb #$0F   ; Convertir a numérico
              clra        ; Unidades no necesitan multiplicarse (×1)
              addd ACC    ; Sumar al total acumulado
              std ACC     ; Guardar valor final convertido
              ldaa cont   ; Cargar posición actual en Datos_bin
              movw ACC, a,y ; Guardar valor de 12 bits en Datos_bin
              inc offset    ; Mover al siguiente grupo de 4 dígitos
              inc cont      ;Incrementar contador de datos 2 veces (Es un Word)
              inc cont
              ldaa cont
              lsra         ; Dividir contador entre 2
              cmpa cant    ; Comparar con cantidad total requerida
              bne loop     ; Repetir si no hemos terminad
              lsr cont      ; Ajustar contador a valor correcto
              leas -6,sp    ; Ajuste de pila (compensar pushes anteriores)
              rts          ; Retornar de subrutina
              
;*******************************************************************************
;                          Subrutina Mover
; Descripcion: Mover y separar nibbles de datos binarios a tres arrays distintos
;Entradas:
;   - X: Puntero a Datos_Bin (array de datos de entrada)
;   - cant: Cantidad de datos a procesar (variable en memoria)
; Salidas:
;   - nibble_UP: Array de Nibbles superiores (bits 11-8)
;   - nibble_MED: Array de Nibbles medios (bits 7-4)
;   - nibble_LOW: Array de Nibbles inferiores (bits 3-0)
;*******************************************************************************

mover        clra ; Reiniciar contador
             pshx ; Guardar Datos_Bin en la pila
             ldy nibble_UP ; Cargar la dirrecion de nibble_UP en y
nibble_alto  movb 2,x+, 1,y+ ; Mover el nibble mas significativo
             inca ; Incrementar el contador de los datos movidos
             cmpa cant ; Compararlo con el numero de datos a mover
             bne nibble_alto ; si no se llegado se repite el loop
             pulx ; Recuperar Datos_Bin
             inx  ; incrementar Datos_Bin para que apunte a la parte baja
             pshx ; Guardar Datos_Bin+1
             clra ; Reiniciar contador
             ldy nibble_MED ; Cargar el puntero de nibble_med
nibble_medio ldab 2,x+ ; Cargar nibble
             lsrb      ; Desplazar bits 7-4 a posición 3-0:
             lsrb      ; (4 desplazamientos a la derecha)
             lsrb
             lsrb
             stab 1,y+ ; Guardar en el arreglo de nibble_med
             inca      ; Incrementar contador
             cmpa cant ; Verificar si ha procesado todos los datos
             bne nibble_medio ; Repetir si no ha terminado
             clra ; reiniciar el contador
             pulx ; recuperar Datos_Bin+1
             ldy nibble_LOW ; Y apunta a array destino nibble_LOW
nibble_bajo  ldab 2,x+    ; Cargar byte actual en B
             andb #$0F    ; Aislar nibble bajo (bits 3-0)
             stab 1,y+    ; Guardar nibble bajo e incrementar puntero
             inca         ; Incrementar contador
             cmpa cant    ; Verificar si completó todos los datos
             bne nibble_bajo ; Repetir si faltan dato
             rts           ; Retornar de subrutina
;*******************************************************************************
;                          Subrutina IMPRIMIR
; Descripccion: Imprime valores en el terminal de la tarjeta Dragon 12
; Entradas:
;   - cont: Variable
;   - nibble_UP, nibble_MED, nibble_LOW: Arrays de datos
;   - cant: Cantidad de elementos en cada array
; Salidas: Mensajes formateados en el terminal
;*******************************************************************************
Imprimir    ldx #$00            ; Inicializa X a 0 (para llamadas a PrintF)
            ldab cont           ; Carga el valor del contador en B
            clra                ; Limpia A (D = A:B)
            pshd                ; Guarda el contador en pila para PrintF
            ldd #MSG_cont       ; Carga dirección del mensaje del contador
            jsr [PrintF,x]      ; Llama a PrintF para mostrar el contador
            ldd #MSG_Nibble_UP  ; Carga mensaje para nibble UP
            pshd                ; Guarda mensaje en pila (para subrutina)
            ldy nibble_UP       ; Carga dirección de datos UP en Y
            jsr Imprimir_Nibble ; Llama a subrutina de mostrar los nibbles
            ldd #MSG_Nibble_MED ; Carga mensaje para nibble MED
            pshd                ; Guarda mensaje en pila (para subrutina)
            ldy nibble_MED      ; Carga dirección de datos MED en Y
            jsr Imprimir_Nibble ; Llama a subrutina de mostrar los nibbles
            ldd #MSG_Nibble_LOW ; Carga mensaje para nibble LOW
            pshd                ; Guarda mensaje en pila (para subrutina)
            ldy nibble_LOW      ; Carga dirección de datos LOW en Y
            jsr Imprimir_Nibble ; Llama a subrutina de mostrar los nibbles
            leas 8,sp           ; Restablecer el sp en la direccion de retorno
            rts

;*******************************************************************************
;                        IMPRIMIR_NIBBLE
; Entrada:
;   Y = Puntero a los datos del nibble
;   Cant = Cantidad de elementos (En Memoria)
;   Pila = Mensaje a mostrar (2 bytes)
;*******************************************************************************
Imprimir_Nibble leas 2,sp  ; Ajusta pila (Se salta la dirección de retorno)
                puld       ; Recupera el mensaje de la pila
                leas -4,sp ; restablece la pila en la direccion de retorno
                pshy       ; Guarda puntero Y
                ldx #$00   ; Inicializa X para PrintF
                jsr [PrintF,x]  ; Muestra el mensaje (UP, MED o LOW)
                puly       ; Recuperar el puntero a datos
                ldaa cant  ; Carga cantidad de elementos a procesar
Procesar_Loop   cmpa #$01  ; Compara si es el último elemento
                beq Ultimo_Elemento ; Si es 1, salta al ultimo elemento
                deca       ; Decrementa contador
                psha       ; Guarda el contador
		ldab 1,y+  ; Lee el dato y avanza el puntero
                pshy       ; Guarda Y
                clra       ; Limpia parte alta (D = 0:B)
                pshd       ; Guarda el dato en pila para PrintF
                ldd #MSG_nibble_coma ; Carga mensaje con coma
                ldx #$00   ; Prepara X para PrintF
                jsr [PrintF,x] ; Imprime dato con coma
		puld           ; Recupera el dato
		puly           ; Recupera Y
		pula           ; Recupera el contador
                bra Procesar_Loop; Repite para siguiente elemento
Ultimo_Elemento ldab 1,y+      ; Lee el último dato
                clra           ; Limpia parte alta
                pshd           ; Guarda dato para PrintF
                ldd #MSG_nibble ; Carga mensaje sin coma
                ldx #$00        ; Prepara X para PrintF
                jsr [PrintF,x]  ; Imprime último dato sin coma
                puld            ; Limpia pila
                rts


