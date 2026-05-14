; ============================================================
; practice13.asm - реверс масиву, перевірка паліндрому
; ============================================================

section .bss
    input_buf  resb 4096    ; memory - великий буфер для вводу
    arr        resd 200     ; memory - оригінальний масив
    rev        resd 200     ; memory - реверсований масив
    n_val      resd 1
    out_buf    resb 32

section .data
    str_orig    db 'original: '
    str_orig_len equ $ - str_orig
    str_rev     db 'reversed: '
    str_rev_len equ $ - str_rev
    str_pal_yes db 'PALINDROME: YES'
    str_pal_yes_len equ $ - str_pal_yes
    str_pal_no  db 'PALINDROME: NO'
    str_pal_no_len  equ $ - str_pal_no
    space       db ' '
    newline     db 0x0A

section .text
    global _start

_start:

; ============================================================
; I/O - читаємо весь ввід одразу
; ============================================================
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 4095
    int 0x80

; parse - atoi(n), ECX рухається вперед автоматично
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

    call atoi               ; ECX вказує на наступне число
    mov ebx, esi
    shl ebx, 2
    mov [arr + ebx], eax    ; memory - arr[i] = eax

    inc esi
    jmp .read_loop

.read_done:

; ============================================================
; loops - копіюємо arr в rev у зворотньому порядку (rep movsd)
; rev[i] = arr[n-1-i]
; ============================================================
    xor esi, esi            ; i = 0

.rev_loop:
    cmp esi, [n_val]
    jge .rev_done

    ; math - j = n-1-i
    mov eax, [n_val]
    dec eax
    sub eax, esi            ; eax = n-1-i

    ; memory - rev[i] = arr[n-1-i]
    mov ebx, eax
    shl ebx, 2
    mov eax, [arr + ebx]    ; eax = arr[j]
    mov ebx, esi
    shl ebx, 2
    mov [rev + ebx], eax    ; rev[i] = eax

    inc esi
    jmp .rev_loop

.rev_done:

; ============================================================
; I/O - виводимо оригінальний масив
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_orig
    mov edx, str_orig_len
    int 0x80

    xor esi, esi

.print_orig:
    cmp esi, [n_val]
    jge .print_orig_done

    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]
    call itoa_print_space

    inc esi
    jmp .print_orig

.print_orig_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; I/O - виводимо реверсований масив
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_rev
    mov edx, str_rev_len
    int 0x80

    xor esi, esi

.print_rev:
    cmp esi, [n_val]
    jge .print_rev_done

    mov ebx, esi
    shl ebx, 2
    mov eax, [rev + ebx]
    call itoa_print_space

    inc esi
    jmp .print_rev

.print_rev_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; logic - перевіряємо паліндром: arr[i] == arr[n-1-i]
; ============================================================
    xor esi, esi
    mov edi, [n_val]
    shr edi, 1              ; перевіряємо тільки першу половину

.pal_loop:
    cmp esi, edi
    jge .is_palindrome

    ; logic - arr[i] vs arr[n-1-i]
    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]    ; eax = arr[i]

    mov ebx, [n_val]
    dec ebx
    sub ebx, esi            ; ebx = n-1-i
    shl ebx, 2
    mov ecx, [arr + ebx]    ; ecx = arr[n-1-i]

    cmp eax, ecx
    jne .not_palindrome

    inc esi
    jmp .pal_loop

.is_palindrome:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_pal_yes
    mov edx, str_pal_yes_len
    int 0x80
    jmp .print_pal_nl

.not_palindrome:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_pal_no
    mov edx, str_pal_no_len
    int 0x80

.print_pal_nl:
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
; itoa_print_space - виводить EAX + пробіл
; ============================================================
itoa_print_space:
    push eax
    push esi
    push edi
    push ebx

    mov edi, out_buf
    add edi, 28
    mov byte [edi+1], ' '
    xor esi, esi
    xor ebx, ebx

    test eax, eax
    jns .ip_check
    neg eax
    mov ebx, 1

.ip_check:
    test eax, eax
    jnz .ip_div
    mov byte [edi], '0'
    dec edi
    inc esi
    jmp .ip_sign

.ip_div:
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    mov [edi], dl
    dec edi
    inc esi
    test eax, eax
    jnz .ip_div

.ip_sign:
    test ebx, ebx
    jz  .ip_done
    mov byte [edi], '-'
    dec edi
    inc esi

.ip_done:
    inc edi
    inc esi                 ; +1 для пробілу
    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    mov edx, esi
    int 0x80

    pop ebx
    pop edi
    pop esi
    pop eax
    ret

; ============================================================
; atoi - [ECX] -> EAX, рухає ECX вперед
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
