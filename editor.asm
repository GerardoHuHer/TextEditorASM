org 100h

; Inicializar posición del cursor
mov ah, 02h ; FUnción para centrarnos en el cursor
mov bh, 0 ; Deshabilita el cursor
; Posiciones del cursor en filas y columnas
mov dh, 0 ; Filas
mov dl, 0 ; Columnas
; Interrupción 10 
int 10h

start:
    mov ah, 0
    int 16h            ; Espera tecla

    ; Validamos teclas especiales estas se almacenan en ah
 
    ; Flecha izquierda
    cmp ah, 4Bh
    je flecha_izq

    ; Flecha Derecha
    cmp ah, 4Dh
    je flecha_der

    ; Flecha arriba
    cmp ah, 48h
    je flecha_arr

    ; Flecha abajo
    cmp ah, 50h
    je flecha_abj

    
    ; ESC
    cmp al, 27
    je salir
    ; Enter
    cmp al, 13
    je salto_linea
    ; Borrar
    cmp al, 8
    je borrar

    ; Imprimir carácter
    mov ah, 0Eh
    int 10h ; interrupción para imprimir

    ; Avanzar columna
    inc dl
    cmp dl, 80
    jl set_cursor

    ; Fin de línea → saltar de línea
    mov dl, 0
    inc dh
    call comprobar_scroll
    jmp set_cursor

salto_linea:
    mov dl, 0
    inc dh
    call comprobar_scroll
    jmp set_cursor

borrar:
    cmp dl, 0
    jne borrar_mismo_renglon
    cmp dh, 0
    je start            ; No retroceder si estás en la esquina superior
    dec dh
    mov dl, 79
    jmp borrar_caracter

borrar_mismo_renglon:
    dec dl

borrar_caracter:
    ; Coloca cursor en nueva posición
    mov ah, 02h
    int 10h

    ; Escribe un espacio para "borrar"
    mov ah, 0Ah
    mov al, ' '
    int 10h

    ; Volver a colocar cursor en esa posición
    mov ah, 02h
    int 10h
    jmp start

comprobar_scroll:
    cmp dh, 25
    jl continuar
    ; Scroll una línea hacia arriba
    mov ax, 0601h       ; Scroll 1 línea hacia arriba
    mov bh, 07h         ; Color gris sobre negro
    mov cx, 0000h       ; Esquina superior izquierda
    mov dx, 184Fh       ; Esquina inferior derecha (24,79)
    int 10h

    ; Mantener cursor en última línea 
    mov dh, 24 

continuar: 
    ret

set_cursor:
    mov ah, 02h
    int 10h
    jmp start

flecha_izq:
    ; Comparamos si estamos al inicio de la línea
    cmp dl, 0
    ; Si es diferente de 0 significa que no estamos al principio de la línea.
    ; Entonces saltamos a mover_mismo_renglon_izq
    jne mover_mismo_renglon_izq
    cmp dh, 0
    je start

    dec dh
    mov dl, 79
    jmp mover_cursor

mover_mismo_renglon_izq:
    dec dl
    jmp mover_cursor

flecha_der: 
    cmp dl, 79
    jne mover_mismo_renglon_der
    cmp dh, 24
    je start

    inc dh
    mov dl, 0
    jmp mover_cursor

mover_mismo_renglon_der: 
    inc dl
    jmp mover_cursor

flecha_arr: 
    cmp dh, 0
    je start
    dec dh
    jmp mover_cursor

flecha_abj:
    cmp dh, 24
    je start
    inc dh
    jmp mover_cursor

mover_cursor:
    mov ah, 02h
    int 10h
    jmp start

salir:
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0
    mov dx, 184Fh
    int 10h

    mov ah, 4Ch
    int 21h
