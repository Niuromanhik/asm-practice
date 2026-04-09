
section .data
    newline db 10

section .bss
    buffer resb 10

section .text
global _start

_start:

    ; logic
    mov eax, 1234

    ; memory
    mov esi, buffer

    ; parse
    call int2str

    ; I/O
    mov edx, eax
    mov eax, 4
    mov ebx, 1
    mov ecx, buffer
    mov edx, esi
    int 0x80

    ; newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; exit
    mov eax, 1
    xor ebx, ebx
    int 0x80


int2str:

    ; loops
    mov ecx, 0

convert_loop:

    ; math
    xor edx, edx
    mov ebx, 10
    div ebx

    ; parse
    add dl, '0'

    ; memory
    push dx
    inc ecx

    ; logic
    cmp eax, 0
    jne convert_loop

write_loop:

    ; memory
    pop dx
    mov [esi], dl
    inc esi

    ; loops
    loop write_loop

    ; logic
    mov eax, ecx
    ret
