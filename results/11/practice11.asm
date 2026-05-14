; ============================================================
; practice11.asm - ялинка з '*' по центру висотою h
; ============================================================

section .bss
    input_buf  resb 32
    line_buf   resb 128     ; memory - буфер для одного рядка

section .data
    newline    db 0x0A

section .text
    global _start

_start:

; ============================================================
; I/O - читаємо h
; ============================================================
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 32
    int 0x80

; parse - atoi(h)
    mov ecx, input_buf
    call atoi
    mov edi, eax            ; EDI = h

; ============================================================
; loops - цикл по рядках i = 0..h-1
; рядок i: (h-1-i) пробілів, (2*i+1) зірочок
; ============================================================
    xor esi, esi            ; ESI = i = 0

.row_loop:
    cmp esi, edi
    jge .row_done

    ; math - spaces = h - 1 - i
    mov ecx, edi
    dec ecx
    sub ecx, esi            ; ECX = кількість пробілів

    ; math - stars = 2*i + 1
    mov edx, esi
    shl edx, 1
    inc edx                 ; EDX = кількість зірочок

    ; memory - формуємо рядок в line_buf
    mov ebx, line_buf       ; EBX = вказівник в буфер
    xor eax, eax            ; лічильник довжини

    ; loops - записуємо пробіли
.spaces_loop:
    test ecx, ecx
    jz  .spaces_done
    mov byte [ebx + eax], ' '
    inc eax
    dec ecx
    jmp .spaces_loop
.spaces_done:

    ; loops - записуємо зірочки
.stars_loop:
    test edx, edx
    jz  .stars_done
    mov byte [ebx + eax], '*'
    inc eax
    dec edx
    jmp .stars_loop
.stars_done:

    ; memory - додаємо newline в кінець
    mov byte [ebx + eax], 0x0A
    inc eax

    ; I/O - виводимо рядок через підпрограму
    push eax                ; довжина
    push ebx                ; буфер
    call print_line
    add esp, 8

    inc esi
    jmp .row_loop

.row_done:

; I/O - вихід
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ============================================================
; print_line(buf, len) - виводить рядок на stdout
; [esp+4] = buf, [esp+8] = len
; ============================================================
print_line:
    push ebp
    mov ebp, esp
    push ebx

    mov eax, 4
    mov ebx, 1
    mov ecx, [ebp+8]        ; buf
    mov edx, [ebp+12]       ; len
    int 0x80

    pop ebx
    pop ebp
    ret

; ============================================================
; atoi - [ECX] -> EAX
; ============================================================
atoi:
    push ebx
    push edx
    xor eax, eax
    xor ebx, ebx

.skip:
    mov dl, [ecx]
    cmp dl, ' '
    je  .skip_inc
    cmp dl, 0x0A
    je  .skip_inc
    cmp dl, 0x0D
    je  .skip_inc
    jmp .sign
.skip_inc:
    inc ecx
    jmp .skip

.sign:
    mov dl, [ecx]
    cmp dl, '-'
    jne .digits
    mov ebx, 1
    inc ecx

.digits:
    mov dl, [ecx]
    cmp dl, '0'
    jl  .atoi_done
    cmp dl, '9'
    jg  .atoi_done
    imul eax, eax, 10
    sub dl, '0'
    movzx edx, dl
    add eax, edx
    inc ecx
    jmp .digits

.atoi_done:
    test ebx, ebx
    jz  .atoi_ret
    neg eax
.atoi_ret:
    pop edx
    pop ebx
    ret
