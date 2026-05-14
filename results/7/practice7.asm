; ============================================================
; practice7.asm - масив, формула, min/max
; ============================================================

section .bss
    input_buf  resb 32
    output_buf resb 32
    arr        resd 50      ; memory - масив 50 dword
    n_val      resd 1       ; memory - зберігаємо n

section .data
    str_min     db 'min: '
    str_min_len equ $ - str_min
    str_max     db 'max: '
    str_max_len equ $ - str_max
    str_idx     db ' idx: '
    str_idx_len equ $ - str_idx
    space       db ' '
    newline     db 0x0A

section .text
    global _start

_start:

; ============================================================
; I/O - читаємо n
; ============================================================
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 32
    int 0x80

; parse - atoi(n)
    mov ecx, input_buf
    call atoi
    mov [n_val], eax        ; зберігаємо n в пам'яті

; ============================================================
; loops - заповнюємо масив a[i] = (i*i - 3*i + 7) % 100
; ============================================================
    xor esi, esi            ; ESI = i

.fill_loop:
    cmp esi, [n_val]
    jge .fill_done

    ; math - i*i
    mov eax, esi
    imul eax, esi           ; eax = i*i

    ; math - 3*i
    mov ebx, esi
    imul ebx, ebx, 3        ; ebx = 3*i
    sub eax, ebx            ; eax = i*i - 3*i
    add eax, 7              ; eax = i*i - 3*i + 7

    ; math - abs перед mod
    test eax, eax
    jns .pos
    neg eax
.pos:
    xor edx, edx
    mov ebx, 100
    div ebx                 ; EDX = val % 100
    mov eax, edx            ; math - залишок від ділення

    ; memory - arr[i] = eax
    ; адреса = arr + i*4, використовуємо ebx як temp
    mov ebx, esi
    shl ebx, 2              ; ebx = i*4
    mov [arr + ebx], eax

    inc esi
    jmp .fill_loop

.fill_done:

; ============================================================
; loops - виводимо масив
; ============================================================
    xor esi, esi

.print_loop:
    cmp esi, [n_val]
    jge .print_done

    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]    ; eax = arr[i]
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    inc esi
    jmp .print_loop

.print_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; logic - знаходимо min та індекс
; ============================================================
    mov eax, [arr]          ; min = arr[0]
    xor ebx, ebx            ; min_idx = 0
    mov esi, 1              ; i = 1

.min_loop:
    cmp esi, [n_val]
    jge .min_done

    mov ecx, esi
    shl ecx, 2
    mov ecx, [arr + ecx]    ; ecx = arr[i]
    cmp ecx, eax
    jge .min_next
    mov eax, ecx
    mov ebx, esi

.min_next:
    inc esi
    jmp .min_loop

.min_done:
    ; I/O - виводимо "min: VAL idx: IDX"
    push eax
    push ebx
    mov eax, 4
    mov ebx, 1
    mov ecx, str_min
    mov edx, str_min_len
    int 0x80
    pop ebx
    pop eax
    push ebx
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80
    mov eax, 4
    mov ebx, 1
    mov ecx, str_idx
    mov edx, str_idx_len
    int 0x80
    pop eax
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
; logic - знаходимо max та індекс
; ============================================================
    mov eax, [arr]          ; max = arr[0]
    xor ebx, ebx            ; max_idx = 0
    mov esi, 1              ; i = 1

.max_loop:
    cmp esi, [n_val]
    jge .max_done

    mov ecx, esi
    shl ecx, 2
    mov ecx, [arr + ecx]    ; ecx = arr[i]
    cmp ecx, eax
    jle .max_next
    mov eax, ecx
    mov ebx, esi

.max_next:
    inc esi
    jmp .max_loop

.max_done:
    ; I/O - виводимо "max: VAL idx: IDX"
    push eax
    push ebx
    mov eax, 4
    mov ebx, 1
    mov ecx, str_max
    mov edx, str_max_len
    int 0x80
    pop ebx
    pop eax
    push ebx
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80
    mov eax, 4
    mov ebx, 1
    mov ecx, str_idx
    mov edx, str_idx_len
    int 0x80
    pop eax
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
; atoi - [ECX] -> EAX
; ============================================================
atoi:
    push ecx
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
    pop ecx
    ret

; ============================================================
; itoa - EAX -> рядок ECX=ptr EDX=len
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
