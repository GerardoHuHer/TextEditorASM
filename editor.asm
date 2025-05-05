org 100h
jmp start


buffer db 4000 dup('$')  ; Espacio para texto
buffer_len dw 0          ; Cuántos caracteres hay
filename db "texto.txt",0
msg_guardado db "Se guardo correctamente.$"  ; ← Mensaje a mostrar

; Inicializar posición del cursor
mov ah, 02h
mov bh, 0
mov dh, 0
mov dl, 0
int 10h

start:
    mov ah, 0
    int 16h            ; Espera tecla

    cmp al, 0          ; Tecla extendida?
    jne seguir_tecla

    ; Leer segunda parte de la tecla extendida
    int 16h
    ; Verificar F2
    cmp ah, 3Ch        ; F2
    je guardar_buffer
    ; Verificar teclas de flecha
    cmp ah, 48h        ; Flecha arriba
    je flecha_arr
    cmp ah, 50h        ; Flecha abajo
    je flecha_abj
    cmp ah, 4Bh        ; Flecha izquierda
    je flecha_izq
    cmp ah, 4Dh        ; Flecha derecha
    je flecha_der
    jmp start

seguir_tecla:
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
    int 10h

    ; Guardar en buffer
    mov si, [buffer_len]
    mov [buffer + si], al
    inc word [buffer_len]

    ; Avanzar columna
    inc dl
    cmp dl, 80
    jl set_cursor

    ; Fin de línea → salto
    mov dl, 0
    inc dh
    call comprobar_scroll
    jmp set_cursor

salto_linea:
    ; Agregar salto de línea al buffer
    mov al, 13
    mov si, [buffer_len]
    mov [buffer + si], al
    inc word [buffer_len]

    mov al, 10
    mov si, [buffer_len]
    mov [buffer + si], al
    inc word [buffer_len]

    mov dl, 0
    inc dh
    call comprobar_scroll
    jmp set_cursor

borrar:
    cmp dl, 0
    jne borrar_mismo_renglon
    cmp dh, 0
    je start
    dec dh
    mov dl, 79
    jmp borrar_caracter

borrar_mismo_renglon:
    dec dl

borrar_caracter:
    mov ah, 02h
    int 10h

    mov ah, 0Ah
    mov al, ' '
    int 10h

    mov ah, 02h
    int 10h

    ; Eliminar del buffer
    cmp word [buffer_len], 0
    je start
    dec word [buffer_len]
    jmp start

comprobar_scroll:
    cmp dh, 25
    jl continuar
    mov ax, 0601h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h
    mov dh, 24
continuar: 
    ret

set_cursor:
    mov ah, 02h
    int 10h
    jmp start

flecha_izq:
    cmp dl, 0
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

guardar_buffer:
    mov ah, 3Ch         ; Crear archivo
    mov cx, 0
    mov dx, filename
    int 21h
    jc error_guardado
    mov bx, ax          ; Handle

    mov ah, 40h         ; Escribir
    mov cx, [buffer_len]
    mov dx, buffer
    int 21h
    jc error_guardado

    mov ah, 3Eh         ; Cerrar archivo
    int 21h

    ; Mostrar mensaje de éxito
    mov ah, 09h
    mov dx, msg_guardado
    int 21h

    jmp start

error_guardado:
    ; Aquí podrías mostrar un mensaje de error si quieres
    jmp start
