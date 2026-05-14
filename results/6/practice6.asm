; ============================================================
; practice6.asm - compares two numbers signed and unsigned
; ============================================================

section .bss
    input_buf  resb 64
    output_buf resb 32
    val_a      resd 1
    val_b      resd 1

section .data
    str_signed      db 'SIGNED: '
    str_signed_len  equ $ - str_signed
    str_unsigned    db 'UNSIGNED: '
    str_unsigned_len equ $ - str_unsigned
    str_max_s       db 'max_signed: '
    str_max_s_len   equ $ - str_max_s
    str_max_u       db 'max_unsigned: '
    str_max_u_len   equ $ - str_max_u
    str_lt          db 'a < b', 0x0A
    str_lt_len      equ $ - str_lt
    str_eq          db 'a = b', 0x0A
    str_eq_len      equ $ - str_eq
    str_gt          db 'a > b', 0x0A
    str_gt_len      equ $ - str_gt
    newline         db 0x0A

section .text
    global _start

_start:

; ============================================================
; I/O - читаємо обидва числа одразу
; ============================================================
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 64
    int 0x80

; parse - atoi(a) - ECX вказує на початок
    mov ecx, input_buf
    call atoi               ; EAX = a, ECX = вказівник після числа
    mov [val_a], eax

; parse - atoi(b) - ECX вже вказує на наступний символ після a
; пропускаємо newline - atoi сам пропустить його у .skip
    call atoi               ; EAX = b
    mov [val_b], eax

; ============================================================
; logic - SIGNED порівняння jl/jg/je
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_signed
    mov edx, str_signed_len
    int 0x80

    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jl  .s_lt
    jg  .s_gt
    mov eax, 4
    mov ebx, 1
    mov ecx, str_eq
    mov edx, str_eq_len
    int 0x80
    jmp .do_unsigned
.s_lt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_lt
    mov edx, str_lt_len
    int 0x80
    jmp .do_unsigned
.s_gt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_gt
    mov edx, str_gt_len
    int 0x80

; ============================================================
; logic - UNSIGNED порівняння jb/ja/je
; ============================================================
.do_unsigned:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_unsigned
    mov edx, str_unsigned_len
    int 0x80

    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jb  .u_lt
    ja  .u_gt
    mov eax, 4
    mov ebx, 1
    mov ecx, str_eq
    mov edx, str_eq_len
    int 0x80
    jmp .do_max_s
.u_lt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_lt
    mov edx, str_lt_len
    int 0x80
    jmp .do_max_s
.u_gt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_gt
    mov edx, str_gt_len
    int 0x80

; ============================================================
; math - max_signed
; ============================================================
.do_max_s:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_max_s
    mov edx, str_max_s_len
    int 0x80

    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jge .ms_a
    mov eax, ebx
    jmp .ms_print
.ms_a:
.ms_print:
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; math - max_unsigned
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_max_u
    mov edx, str_max_u_len
    int 0x80

    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jae .mu_a
    mov eax, ebx
    jmp .mu_print
.mu_a:
.mu_print:
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; I/O - вихід
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ============================================================
; atoi - [ECX] -> EAX, підтримує від'ємні
; повертає ECX що вказує на символ після числа
; ============================================================
atoi:
    push ebx
    push edx
    xor eax, eax
    xor ebx, ebx

; parse - пропускаємо пробіли та newline
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

; logic - перевіряємо знак
.sign:
    mov dl, [ecx]
    cmp dl, '-'
    jne .digits
    mov ebx, 1
    inc ecx

; loops - цикл цифр
.digits:
    mov dl, [ecx]
    cmp dl, '0'
    jl  .done
    cmp dl, '9'
    jg  .done
    imul eax, eax, 10
    sub dl, '0'
    movzx edx, dl
    add eax, edx
    inc ecx
    jmp .digits

.done:
    test ebx, ebx
    jz  .ret
    neg eax
.ret:
    pop edx
    pop ebx
    ret

; ============================================================
; itoa - EAX -> рядок, ECX=ptr, EDX=len
; ============================================================
itoa:
    push eax
    push esi
    push edi

    mov edi, output_buf
    add edi, 30
    mov byte [edi+1], 0
    xor esi, esi
    xor ebx, ebx

    test eax, eax
    jns .icheck
    neg eax
    mov ebx, 1

.icheck:
    test eax, eax
    jnz .idiv
    mov byte [edi], '0'
    dec edi
    inc esi
    jmp .isign

; loops - ділимо на 10
.idiv:
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    mov [edi], dl
    dec edi
    inc esi
    test eax, eax
    jnz .idiv

.isign:
    test ebx, ebx
    jz  .idone
    mov byte [edi], '-'
    dec edi
    inc esi

.idone:
    inc edi
    mov ecx, edi
    mov edx, esi
    pop edi
    pop esi
    pop eax
    ret
