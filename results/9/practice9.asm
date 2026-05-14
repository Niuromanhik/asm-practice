; ============================================================
; practice9.asm - LCG генератор, частоти, гістограма
; ============================================================

section .bss
    input_buf  resb 32
    output_buf resb 32
    freq       resd 10      ; memory - масив частот [0..9]

section .data
    lcg_seed   dd 12345     ; memory - початкове зерно LCG
    str_colon  db ': '
    str_colon_len equ $ - str_colon
    str_hash   db '#'
    newline    db 0x0A

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
    mov edi, eax            ; EDI = n

; ============================================================
; loops - генеруємо n псевдовипадкових чисел LCG
; x = (1103515245 * x + 12345) mod 2^31
; digit = x % 10
; ============================================================
    xor esi, esi            ; i = 0

.gen_loop:
    cmp esi, edi
    jge .gen_done

    ; math - LCG: x = (1103515245 * x + 12345) mod 2^31
    mov eax, [lcg_seed]
    mov ebx, 1103515245
    imul ebx                ; EDX:EAX = seed * 1103515245
    add eax, 12345
    and eax, 0x7FFFFFFF     ; mod 2^31
    mov [lcg_seed], eax

    ; math - digit = x % 10
    xor edx, edx
    mov ebx, 10
    div ebx                 ; EDX = x % 10

    ; memory - freq[digit]++
    mov ebx, edx
    shl ebx, 2
    inc dword [freq + ebx]

    inc esi
    jmp .gen_loop

.gen_done:

; ============================================================
; loops - виводимо гістограму
; для кожного digits 0..9: "D: ####... (count)"
; ============================================================
    xor esi, esi            ; digit = 0

.hist_loop:
    cmp esi, 10
    jge .hist_done

    ; I/O - виводимо цифру
    mov eax, esi
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80

    ; I/O - виводимо ": "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_colon
    mov edx, str_colon_len
    int 0x80

    ; loops - виводимо # пропорційно count (1# = 2 елементи)
    mov ebx, esi
    shl ebx, 2
    mov edi, [freq + ebx]   ; EDI = count

    ; масштабуємо: друкуємо count/10 символів #
    mov eax, edi
    xor edx, edx
    mov ebx, 10
    div ebx                 ; EAX = count/10
    mov ecx, eax            ; ECX = кількість #

.hash_loop:
    test ecx, ecx
    jz  .hash_done
    push ecx
    mov eax, 4
    mov ebx, 1
    mov ecx, str_hash
    mov edx, 1
    int 0x80
    pop ecx
    dec ecx
    jmp .hash_loop

.hash_done:
    ; I/O - виводимо " (count)"
    mov eax, 4
    mov ebx, 1
    mov ecx, str_colon
    mov edx, 1              ; пробіл
    int 0x80

    mov ebx, esi
    shl ebx, 2
    mov eax, [freq + ebx]
    call itoa
    mov eax, 4
    mov ebx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    inc esi
    jmp .hist_loop

.hist_done:

; I/O - вихід
    mov eax, 1
    xor ebx, ebx
    int 0x80

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
