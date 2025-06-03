section .data
    ; Mensajes del juego
    msg_bienvenida db 'Bienvenido a Serpientes y Escaleras!',0xA,0
    msg_jugadores db 'Ingrese numero de jugadores (1-4): ',0
    msg_turno db 'Turno del Jugador ',0
    msg_presione_enter db 'Presione ENTER para lanzar el dado...',0xA,0
    msg_dado db 'Dado: ',0
    msg_posicion db 'Posicion: ',0
    msg_escalera db '¡Escalera! Subes a ',0
    msg_serpiente db '¡Serpiente! Bajas a ',0
    msg_victoria db '¡Jugador ',0
    msg_ganador db ' gana!',0xA,0
    msg_turnos_total db 'Total de turnos: ',0
    msg_error_jugadores db 'Numero invalido. Debe ser 1-4.',0xA,0
    msg_nueva_linea db 0xA,0

    ; Tablero: 0=normal, >0=escalera, <0=serpiente
    tablero:
        dd 0, 0, 35, 0, 0, 0, 0, 0, 0, 0    ; Casilla 3: escalera +35
        dd 0, 0, 0, 0, 0, 0,-21, 0, 0, 0     ; Casilla 16: serpiente -21
        dd 0, 0, 0, 0, 0, 0, 0,42, 0, 0      ; Casilla 27: escalera +42
        dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        dd-20, 0, 0, 0, 0, 0, 0, 0, 0, 0     ; Casilla 40: serpiente -20
        dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        dd 0, 0, 0, 0, 0, 0,-42, 0, 0, 0     ; Casilla 76: serpiente -42
        dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0      ; Casilla 100 es la meta

    ; Variables del juego
    num_jugadores dd 0
    jugadores_pos times 4 dd 1      ; Posiciones iniciales (1-100)
    jugadores_turnos times 4 dd 0   ; Contador de turnos
    turno_actual dd 0               ; Índice del jugador actual (0-3)
    total_turnos dd 0               ; Turnos totales

section .bss
    input resb 2
    buffer resb 10

section .text
    global _start

; ==================== MACROS ====================
%macro print 1
    pusha
    mov eax, %1
    call strlen
    mov edx, eax
    mov ecx, %1
    mov ebx, 1
    mov eax, 4
    int 0x80
    popa
%endmacro

%macro read 2
    pusha
    mov edx, %2
    mov ecx, %1
    mov ebx, 0
    mov eax, 3
    int 0x80
    popa
%endmacro

; ================== FUNCIONES ==================
strlen:
    push ebx
    mov ebx, eax
    .nextchar:
        cmp byte [eax], 0
        jz .finished
        inc eax
        jmp .nextchar
    .finished:
        sub eax, ebx
        pop ebx
        ret

int_to_string:
    push ebx
    push ecx
    push edx
    push esi
    
    mov esi, buffer + 9
    mov byte [esi], 0
    mov ebx, 10
    
    .convert_loop:
        xor edx, edx
        div ebx
        add dl, '0'
        dec esi
        mov [esi], dl
        test eax, eax
        jnz .convert_loop
    
    mov eax, esi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

random_dado:
    push ebx
    push ecx
    push edx
    
    mov eax, 13         ; sys_time
    xor ebx, ebx
    int 0x80
    
    xor edx, edx
    mov ebx, 6
    div ebx
    mov eax, edx
    inc eax
    
    pop edx
    pop ecx
    pop ebx
    ret

print_number:
    pusha
    mov esi, buffer
    call int_to_string
    print eax
    popa
    ret

; =============== PROGRAMA PRINCIPAL ===============
_start:
    print msg_bienvenida

.pedir_jugadores:
    print msg_jugadores
    read input, 2

    ; Validar entrada
    movzx eax, byte [input]
    cmp eax, '1'
    jb .error_jugadores
    cmp eax, '4'
    ja .error_jugadores
    
    sub eax, '0'
    mov [num_jugadores], eax
    jmp .iniciar_juego

.error_jugadores:
    print msg_error_jugadores
    jmp .pedir_jugadores

.iniciar_juego:
    ; Inicializar posiciones de jugadores
    mov ecx, 4
    mov eax, 1
    xor ebx, ebx
.init_posiciones:
    mov [jugadores_pos + ebx*4], eax
    inc ebx
    loop .init_posiciones

; ============= BUCLE PRINCIPAL DEL JUEGO =============
.juego_loop:
    ; Obtener jugador actual
    mov eax, [turno_actual]
    mov ebx, [num_jugadores]
    cmp eax, ebx
    jb .turno_valido
    
    ; Reiniciar turno si excede
    xor eax, eax
    mov [turno_actual], eax
    
.turno_valido:
    ; Incrementar contadores
    mov ebx, [turno_actual]
    inc dword [jugadores_turnos + ebx*4]
    inc dword [total_turnos]
    
    ; Mostrar mensaje de turno
    print msg_turno
    mov eax, ebx
    inc eax
    call print_number
    print msg_nueva_linea
    
    ; Esperar ENTER para lanzar dado
    print msg_presione_enter
.esperar_enter:
    read buffer, 1
    cmp byte [buffer], 0xA
    jne .esperar_enter
    
    ; Lanzar dado y mostrar resultado
    call random_dado
    push eax
    print msg_dado
    call print_number
    print msg_nueva_linea
    pop eax
    
    ; Mover jugador
    mov ebx, [turno_actual]
    add [jugadores_pos + ebx*4], eax
    
    ; Verificar si pasó de 100
    mov ecx, [jugadores_pos + ebx*4]
    cmp ecx, 100
    jg .rebotar
    jmp .verificar_casilla

.rebotar:
    ; Calcular rebote si pasa de 100
    mov edx, ecx
    sub edx, 100
    mov ecx, 100
    sub ecx, edx
    mov [jugadores_pos + ebx*4], ecx

.verificar_casilla:
    ; Verificar serpiente/escalera
    dec ecx  ; Ajustar a índice 0-99
    mov eax, [tablero + ecx*4]
    test eax, eax
    jz .mostrar_posicion
    
    ; Determinar si es escalera o serpiente
    cmp eax, 0
    jg .escalera
    
    ; Serpiente
    print msg_serpiente
    mov ecx, [jugadores_pos + ebx*4]
    add ecx, eax  ; eax es negativo
    mov [jugadores_pos + ebx*4], ecx
    jmp .mostrar_cambio

.escalera:
    ; Escalera
    print msg_escalera
    mov ecx, [jugadores_pos + ebx*4]
    add ecx, eax
    mov [jugadores_pos + ebx*4], ecx

.mostrar_cambio:
    ; Mostrar nueva posición después de serpiente/escalera
    mov eax, ecx
    call print_number
    print msg_nueva_linea

.mostrar_posicion:
    ; Mostrar posición actual
    print msg_posicion
    mov ebx, [turno_actual]
    mov eax, [jugadores_pos + ebx*4]
    call print_number
    print msg_nueva_linea
    
    ; Verificar victoria
    cmp eax, 100
    je .victoria
    
    ; Pasar al siguiente jugador
    inc dword [turno_actual]
    jmp .juego_loop

; ============= FIN DEL JUEGO =============
.victoria:
    ; Mostrar mensaje de victoria
    print msg_victoria
    mov eax, [turno_actual]
    inc eax
    call print_number
    print msg_ganador
    
    ; Mostrar total de turnos
    print msg_turnos_total
    mov eax, [total_turnos]
    call print_number
    print msg_nueva_linea
    
    ; Salir del programa
    mov eax, 1
    xor ebx, ebx
    int 0x80