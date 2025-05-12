org 100h
jmp main

buffer db 4000 dup('$')  ; Espacio para texto
buffer_len dw 0          ; Cuántos caracteres hay
filename db "texto.txt",0 ; Guardamos el nombre del archivo en filename y le colocamos el terminador nulo al final
msg_guardado db "Se guardo correctamente.$"  ; Mensaje de guardado

; Registros importantes
; ah = estamos almacenando instrucciones especiales como las de las posibles interrupciones
; al = estamos almacenando la entrada del teclado en caso de ser tecla extendida este sera 0
; dh = estamos almacenando la posicion de las filas para posicionar el cursor
; dl = estamos almacenando la posicion de las columnas para posicionar el cursor
        

; Inicializar posición del cursor

main: ; Solo se ejecuta al principio del codigo para posicionar el cursor en su lugar
    ; Label para acomodar el cursor desde el inicio de la pantalla
    mov ah, 02h ; movemos un 2 hex al registro ah para hacer decir que cuando hagamos la interrupcion 10h abriremos la interfaz.
    mov bh, 0 ; movemos el 0 a bh para decir que sera por el stdout 
    mov dh, 0 ; Inicializamos las filas del cursor en 0
    mov dl, 0 ; Inicializamos las columnas del cursor en 0
    int 10h ; Realizamos la interrupcion para abrir la interfaz grafica
    jmp start ; Saltamos al label start

start:
    ; Inicio del editor de texto
    mov ah, 0 ; Le decimos que cuando la interrupcion 16h se realice va a estar "escuchando" al teclado
    int 16h ; Interrupción para esperar tecla

    cmp al, 0 ; Si al es 0 significa que es un tecla extendida es decir una tecla especial
    jne seguir_tecla ; si es diferente de 0 entonces saltamos al label seguir_tecla

    int 16h ; Leer segunda parte de la tecla extendida

    ; Verificamos las teclas extendidas es decir las teclas especiales
    ; Verificar F2
    cmp ah, 3Ch  ; F2 con su codigo hex
    je guardar_buffer ; Ejecutamos label de guardar buffer es decir guardar el archivo
    ; Verificar teclas de flecha
    cmp ah, 48h ; Flecha arriba
    je flecha_arr ; Ejecutamos el label de la flecha arriba
    cmp ah, 50h ; Flecha abajo
    je flecha_abj ; Saltamos al label de la flecha abajo
    cmp ah, 4Bh ; Flecha izquierda
    je flecha_izq ; Saltamos al lebel de la flecha izquierda
    cmp ah, 4Dh; Flecha derecha
    je flecha_der ; Saltamos al label de la flecha derecha
    jmp start ; Una vez que terminamos de validar las teclas extendidas saltamos a start donde seguiremos escuchando a nuestro teclado

seguir_tecla:
    ; Si al fue diferente de 0 significa que si estamos escrbiendo algo 
    ; ESC
    cmp al, 27 ; Comparamos si al almaceno un 27 ascii es decir un ESC para ver si salimos o no
    je salir ; si es igual ejecutamos el label de salida
    ; Enter
    cmp al, 13 ; Comparamos si se almaceno el ascii de enter es decir 13
    je salto_linea ; si almacenamos un 13 saltamos al label de salto_linea
    ; Borrar
    cmp al, 8 ; Comparamos ascii 8 con el registro al para ver si se pulso backspace
    je borrar ; si si almaceno eso saltamos al label borrar

    ; Si no se presiono ninguna de esas teclas, entonces tenemos que imprimir el caracter y guardarlo en el buffer para guardar el archivo
    ; Imprimir carácter
    mov ah, 0Eh ; Movemos un 0Eh al registro ah de instruccion para decirle que vamos a imprimir el caracter
    int 10h ; Ejecutamos al interrupcion 10h para imprimir el caracter

    ; Guardar en buffer los carácteres
    mov si, [buffer_len] ; movemos la direccion del buffer al registro si
    mov [buffer + si], al ; almacenamos el valor de al en el buffer sumandole el puntero de si para mover de un caracter en un caracter es decir, almacenamos linea por linea el caracter que se haya leido del teclado
    inc word [buffer_len] ; Estamos incrementando el valor de buffer len para saber cuantos bytes estamos guardando se usara mas adelante

    ; Avanzar columna
    inc dl ; Incrementamos el valor de las columnas para ver si ya llegamos al final de la linea
    cmp dl, 80 ; Comparamos si ya llegamos a los 80 caracteres por linea, esto para ver si ya insertamos salto de linea
    jl set_cursor ; en caso de ser menor ejecutamos el label set_cursor

    ; Fin de línea
    mov dl, 0 ; Si fue mayor a 80 movemos las columnas a 0
    inc dh ; Continuando con la linea anterior le incrementamos uno a las filas para bajar al siguiente renglon
    call comprobar_scroll ; Llamamos el label comprobar_scroll para ver si ya llegammos a las 25 lineas disponilbles
    jmp set_cursor ; saltamos a set_cursor

salto_linea:
    ; Agregar salto de línea al buffer
    mov al, 13 ; Movemos un enter en ascii para insertar en las siguientes lineas un salto de linea '\n'
    mov si, [buffer_len] ; Almacenamos la direccion del buffer_len en si
    mov [buffer + si], al ; aniadimos el salto de linea al buffer_len
    inc word [buffer_len] ; Incrementamos la posicion del buffer_len

    mov al, 10 ; Con este codigo ascii vamos a realizar el salto de linea
    mov si, [buffer_len]; Almacenamos la direccion del buffer_len en si
    mov [buffer + si], al ; aniadimos el salto de linea al buffer_len
    inc word [buffer_len] ; Incrementamos la posicion del buffer_len

    mov dl, 0 ; CUnado hagamos el salto de linea movemos nuestro cursor a la columna 0
    inc dh ; Y a la fila siguiente
    call comprobar_scroll ; Comprobamos el scroll para verificar si ya llegamos a la zona donde vamos a scrollear
    jmp set_cursor ; Saltamos al label set_cursor

borrar:
    cmp dl, 0 ; Verificamos si las columnas son 0
    jne borrar_mismo_renglon ; Si no es igual a 0 vamos a borrar en el mismo renglon
    cmp dh, 0 ; Comparamos si estamos en la fila 0
    je start ; Si si es igual a 0 entonces saltamos a start es decir a escucha el teclado
    dec dh ; Si estabamos al principio del renglon vamos a dismunir los renglones
    mov dl, 79 ; Y nos vamos a mover a la ultima columna 
    jmp borrar_caracter ; Saltamos la label borrar_caracter

borrar_mismo_renglon:
    dec dl ; Si borramos sobre el mismo renglon solo decrementamos las columnas

borrar_caracter:
    mov ah, 02h ; Le decimos que nos iremos a la interfaz grafica en la proxima int10h
    int 10h ; Realizmos la interrupcion

    mov ah, 0Ah ; Decimos que vamos a ejecutar la proximma interrupcion 0Ah
    mov al, ' ' ; Vamos a escribir un ' ' porque borramos el caracter
    int 10h ; Imprimimos ese ' ' en la pantalla

    mov ah, 02h ; Le decimos que nos iremos a la interfaz grafica en la proxima int10h 
    int 10h ; Realizamos la interrupcion

    ; Eliminar del buffer
    cmp word [buffer_len], 0 ; Comparamos que el valor del buffer no sea 0 porque si no estariamos borrando la nada y provocando que se saliera de su espacio en memoria
    je start ; en caso de ser 0 saltamos al label start
    dec word [buffer_len] ; Si es diferente restamos el valor de la posicion en el buffer
    jmp start ; Saltamos al start

comprobar_scroll:
    cmp dh, 25 ; Comprobamos que las filas dh sean 25
    jl continuar ; Si es menor saltamos a continuar
    mov ax, 0601h ; Instruccion para hacer un scroll hacia abajo cuando se haga la int10
    mov bh, 07h ; Aqui le estamos dando las caracteristicas de color que se va a mantener el gris
    mov cx, 0000h ; coordenandas del scroll 0,0
    mov dx, 184Fh ; coordenas del final en dx
    int 10h ; Ejecutamos la interrupcion
    mov dh, 24 ; Movemos nuestras filas a 24
continuar: 
    ret ; Le decimos que cuando retorne cada que se llame a continuar, es para volver a la subrutina en la que estabamos cuando lo llamamos

set_cursor: 
    mov ah, 02h ; Decimos que la funcion de la interrupcion 10 sera la 02 que nos ayudara a posicionar el cursor con los valores de dx 
    int 10h ; Ejecutamos la int10h
    jmp start ; saltamos a start

flecha_izq:
    cmp dl, 0 ; Comprobamos si la columna es igual a 0
    jne mover_mismo_renglon_izq ; Si es diferente de 0 llamamos al label mover_mismo_renglon_izq
    cmp dh, 0 ; Comparamos si la fila es 0
    je start ; Si es igual a 0 saltamos a start
    dec dh ; Restamos en caso de no ser cero decrementamos las filas
    mov dl, 79 ; Movemos el cursor a la fila anterior en la ultima columna
    jmp mover_cursor ; saltamos al label move_cursor

mover_mismo_renglon_izq:
    dec dl ; En caso de estar en el mismo renglon restamos las columnas
    jmp mover_cursor ; saltamos al label mover_cursor

flecha_der: 
    cmp dl, 79 ; Comprobamos si estamos en la ultima columna
    jne mover_mismo_renglon_der ; si es diferente de 79 que es el limite de de columnas nos saltamos al label mover_mismo_renglon_der
    cmp dh, 24 ; Comprobamos que la posicion de las filas
    je start ; Si es igual a 24 saltamos al label start
    inc dh ; Incrementamos la posicion de la fila
    mov dl, 0 ; Movemos 0 a las columnas
    jmp mover_cursor ; Llamamos al label mover_cursor

mover_mismo_renglon_der: 
    inc dl ; Incrementamos la posicion de las columnas
    jmp mover_cursor

flecha_arr: 
    cmp dh, 0 ; Comprobamos que las filas sean igual a cero
    je start ; Si es igual a 0 saltamos a start
    dec dh ; Si es diferente restamos una fila
    jmp mover_cursor ; Saltamos a mover_cursor para posicionar el cursor en su nueva posicion

flecha_abj:
    cmp dh, 24 ; Comprobamos si ya estamos en el ultimo renglon
    je start ; Si es igual saltamos a start
    inc dh ; Si es diferente incrementamos la posicion de las filas
    jmp mover_cursor ; Saltamos a mover_cursor para posicionar el cursor

mover_cursor:
    ; Label para posicionar el cursor en su nuevas coordenadas
    mov ah, 02h ; Parametro para la interrupcion 10
    int 10h ; Provocamos la interrupcion
    jmp start ; Saltamos al label start

salir:
    ; Label para salir
    mov ax, 0600h ; Pasamos como parametro a la interrupción
    mov bh, 07h ; movemos 07h al registro bh para el estilo gris de la pantalla
    mov cx, 0 ; Restauramos la terminal en la posición que debería de estar de inicio
    mov dx, 184Fh ; Restauramos la terminal en la posición que debería de estar de fin
    int 10h ; Llamamos a la interrupción

    mov ah, 4Ch ; Almacenamos el paramatro 4Ch para terminar la ejecución del programa
    int 21h ; Interrupción en la BIOS

guardar_buffer:
    mov ah, 3Ch ; Parametro 3Ch para hacer la interrupción
    mov cx, 0 ; Atributo de solo lectura en el archivo
    mov dx, filename ; Nombre del archivo
    int 21h ; Llamada a la interrupción
    jc error_guardado ; Saltar al error si hubo un fallo
    mov bx, ax ; Guardamos la respuesta en BX

    mov ah, 40h ; Pasamos como parametro 40h a la interrupción 21h
    mov cx, [buffer_len] ; Esta será la longitud del buffer a guardar
    mov dx, buffer ; La dirección del buffer a escribir
    int 21h ; Escribimos el buffer en el archivo
    jc error_guardado ; Saltamos un error en caso que haya alguna falla

    mov ah, 3Eh ; Parametro para cerrar el archivo
    int 21h ; Interrupción para cerrar el archivo

    ; Mostrar mensaje de éxito
    mov ah, 09h ; parametro de salir para la interrupción 21h
    mov dx, msg_guardado ; Movemos el mensaje a dx para con la interrupción 21h imprimirlo en pantalla
    int 21h ; Ejecutamos la interrupción 21h

    jmp start ; Saltamos a start 

error_guardado:
    ; Aquí podrías mostrar un mensaje de error si quieres
    jmp start
