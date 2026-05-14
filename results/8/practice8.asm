; ============================================================
; practice8.asm - лінійний пошук у масиві, статистика входжень
; ============================================================

section .bss
    input_buf  resb 4096    ; memory - великий буфер для всіх чисел
    output_buf resb 32
    arr        resd 100     ; memory - масив 100 елементів
    n_val      resd 1
    target     resd 1

section .data
    str_first     db 'first: '
    str_first_len equ $ - str_first
    str_count     db 'count: '
    str_count_len equ $ - str_count
    str_indices   db 'indices: '
    str_indices_len equ $ - str_indices
    str_none      db '-1'
    str_none_len  equ $ - str_none
    space         db ' '
    newline       db 0x0A

section .text
    global _start

_start:

; ============================================================
; I/O - читаємо весь ввід одразу
; ============================================================
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 4096
    int 0x80

; ============================================================
; parse - читаємо n (ECX вказує на поточну позицію в буфері)
; ============================================================
    mov ecx, input_buf
    call atoi
    mov [n_val], eax

; ============================================================
; loops + parse - читаємо n чисел в масив
; ============================================================
    xor esi, esi            ; i = 0

.read_loop:
    cmp esi, [n_val]
    jge .read_done

    call atoi               ; ECX автоматично рухається вперед

    ; memory - arr[i] = eax
    mov ebx, esi
    shl ebx, 2
    mov [arr + ebx], eax

    inc esi
    jmp .read_loop

.read_done:

; ============================================================
; parse - читаємо target
; ============================================================
    call atoi
    mov [target], eax

; ============================================================
; logic + loops - шукаємо перший індекс
; ============================================================
    xor esi, esi
    mov edi, -1

.first_loop:
    cmp esi, [n_val]
    jge .first_done

    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]
    cmp eax, [target]
    jne .first_next
    cmp edi, -1
    jne .first_next
    mov edi, esi

.first_next:
    inc esi
    jmp .first_loop

.first_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_first
    mov edx, str_first_len
    int 0x80

    cmp edi, -1
    jne .print_first_val
    mov eax, 4
    mov ebx, 1
    mov ecx, str_none
    mov edx, str_none_len
    int 0x80
    jmp .print_first_nl
.print_first_val:
    mov eax, edi
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80
.print_first_nl:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; logic + loops - рахуємо входження
; ============================================================
    xor esi, esi
    xor edi, edi

.count_loop:
    cmp esi, [n_val]
    jge .count_done

    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]
    cmp eax, [target]
    jne .count_next
    inc edi

.count_next:
    inc esi
    jmp .count_loop

.count_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_count
    mov edx, str_count_len
    int 0x80

    mov eax, edi
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
; loops - виводимо всі індекси
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_indices
    mov edx, str_indices_len
    int 0x80

    xor esi, esi

.idx_loop:
    cmp esi, [n_val]
    jge .idx_done

    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]
    cmp eax, [target]
    jne .idx_next

    mov eax, esi
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

.idx_next:
    inc esi
    jmp .idx_loop

.idx_done:
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
; atoi - [ECX] -> EAX, рухає ECX вперед, підтримує від'ємні
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
