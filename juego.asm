; Compilar con:
; nasm -f elf32 juego.asm && gcc -m32 juego.o -o juego

extern printf, scanf, getchar, rand, srand, time

section .data
    msg_inicio     db "Bienvenido a Serpientes y Escaleras", 10, 0
    msg_jugadores  db "Ingrese número de jugadores (1-5): ", 0
    fmt_d          db "%d", 0
    msg_turno      db "Turno del Jugador %d - Presiona ENTER para lanzar dado...", 10, 0
    msg_dado       db "Jugador %d obtuvo un: %d", 10, 0
    msg_escalera   db "Subiste por una escalera hasta la casilla %d", 10, 0
    msg_serpiente  db "Bajaste por una serpiente hasta la casilla %d", 10, 0
    msg_posicion   db "Jugador %d está en la casilla %d", 10, 0
    msg_victoria   db "¡Jugador %d ganó en %d turnos!", 10, 0

    escaleras_origen db 3, 8, 28
    escaleras_destino db 22, 26, 84

    serpientes_origen db 17, 52, 99
    serpientes_destino db 7, 29, 10

section .bss
    posiciones resd 5        ; posiciones de hasta 5 jugadores
    turnos     resd 1
    jugador_actual resd 1
    total_jugadores resd 1
    input resd 1

section .text
global main

main:
    ; Inicializar rand con time
    push 0
    call time
    add esp, 4
    push eax
    call srand
    add esp, 4

    ; Mensaje bienvenida
    push msg_inicio
    call printf
    add esp, 4

    ; Pedir número de jugadores
pedir_jugadores:
    push total_jugadores
    push msg_jugadores
    call printf
    add esp, 4

    push total_jugadores
    push fmt_d
    call scanf
    add esp, 8

    mov eax, [total_jugadores]
    cmp eax, 1
    jl pedir_jugadores
    cmp eax, 5
    jg pedir_jugadores

    ; Inicializar posiciones
    xor ecx, ecx
init_loop:
    cmp ecx, [total_jugadores]
    jge turnos_loop
    mov dword [posiciones + ecx*4], 1
    inc ecx
    jmp init_loop

turnos_loop:
    mov eax, [jugador_actual]
    inc dword [turnos]

    ; Mostrar mensaje turno
    push eax
    inc eax
    push msg_turno
    call printf
    add esp, 8

    ; Esperar ENTER
    call getchar
    call getchar

    ; Lanzar dado (rand() % 6 + 1)
    call rand
    mov ecx, 6
    xor edx, edx
    div ecx
    inc edx      ; edx = valor del dado (1-6)

    ; Mostrar resultado
    push edx
    mov eax, [jugador_actual]
    inc eax
    push eax
    push msg_dado
    call printf
    add esp, 12

    ; Avanzar posición
    mov eax, [jugador_actual]
    mov ecx, [posiciones + eax*4]
    add ecx, edx
    cmp ecx, 100
    jae .check_exacto
    jmp .verificar_especiales

.check_exacto:
    jne .verificar_especiales
    ; Victoria exacta
    mov ebx, [jugador_actual]
    inc ebx
    mov eax, [turnos]
    push eax
    push ebx
    push msg_victoria
    call printf
    add esp, 12
    jmp fin

.verificar_especiales:
    ; Revisar si cae en escalera
    mov ebx, 0
.revisar_escaleras:
    cmp ebx, 3
    jge .revisar_serpientes
    mov al, [escaleras_origen + ebx]
    cmp al, cl
    jne .next_esc
    mov al, [escaleras_destino + ebx]
    movzx ecx, al
    push ecx
    push msg_escalera
    call printf
    add esp, 8
    jmp .guardar

.next_esc:
    inc ebx
    jmp .revisar_escaleras

.revisar_serpientes:
    mov ebx, 0
.revisar_loop:
    cmp ebx, 3
    jge .guardar
    mov al, [serpientes_origen + ebx]
    cmp al, cl
    jne .next_serp
    mov al, [serpientes_destino + ebx]
    movzx ecx, al
    push ecx
    push msg_serpiente
    call printf
    add esp, 8
    jmp .guardar

.next_serp:
    inc ebx
    jmp .revisar_loop

.guardar:
    ; Guardar posición actualizada
    mov eax, [jugador_actual]
    mov [posiciones + eax*4], ecx

    ; Mostrar posiciones de todos
    xor ecx, 0
.mostrar_pos:
    cmp ecx, [total_jugadores]
    jge .siguiente_turno
    mov eax, [posiciones + ecx*4]
    push eax
    mov ebx, ecx
    inc ebx
    push ebx
    push msg_posicion
    call printf
    add esp, 12
    inc ecx
    jmp .mostrar_pos

.siguiente_turno:
    mov eax, [jugador_actual]
    inc eax
    cmp eax, [total_jugadores]
    jl .guardar_jugador
    xor eax, eax
.guardar_jugador:
    mov [jugador_actual], eax
    jmp turnos_loop

fin:
    mov eax, 1
    xor ebx, ebx
    int 0x80
