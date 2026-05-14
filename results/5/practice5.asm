; ============================================================
; practice5.asm — читає число x, виводить sumDigits(x) та len(x)
; ============================================================

section .bss
    input_buf  resb 32      ; буфер для вводу (memory)
    output_buf resb 32      ; буфер для виводу (memory)

section .data
    newline db 0x0A

section .text
    global _start

_start:

; ============================================================
; I/O — читаємо рядок з консолі (stdin)
; ============================================================
    mov eax, 3              ; sys_read
    mov ebx, 0              ; fd = stdin
    mov ecx, input_buf      ; буфер
    mov edx, 32             ; макс байт
    int 0x80

; ============================================================
; parse — atoi: конвертуємо ASCII рядок в число в EAX
; ============================================================
    mov esi, input_buf      ; ESI = вказівник на рядок
    xor eax, eax            ; EAX = акумулятор

.parse_loop:
    mov bl, [esi]
    cmp bl, '0'
    jl  .parse_done
    cmp bl, '9'
    jg  .parse_done
    ; math — EAX = EAX * 10 + (цифра - '0')
    imul eax, eax, 10
    sub bl, '0'
    movzx ebx, bl
    add eax, ebx
    inc esi
    jmp .parse_loop

.parse_done:
    mov edi, eax            ; EDI = x (зберігаємо оригінал)

; ============================================================
; math + loops — рахуємо sumDigits та len
; цикл while x > 0: ділимо на 10, залишок = цифра
; ============================================================
    xor esi, esi            ; ESI = sumDigits
    xor ecx, ecx            ; ECX = len (кількість цифр)

    ; logic — якщо x == 0 то sum=0, len=1
    test edi, edi
    jnz .digit_loop
    mov esi, 0
    mov ecx, 1
    jmp .print_sum

.digit_loop:
    test edi, edi
    jz  .print_sum

    ; math — div: EDX:EAX / 10
    mov eax, edi
    xor edx, edx            ; обнуляємо EDX перед div (обов'язково!)
    mov ebx, 10
    div ebx                 ; EAX = x/10, EDX = x%10 (цифра)

    add esi, edx            ; sumDigits += цифра
    inc ecx                 ; len++
    mov edi, eax            ; x = x/10

    ; loops — повторюємо поки x > 0
    jmp .digit_loop

; ============================================================
; I/O + math — виводимо sumDigits(x)
; ============================================================
.print_sum:
    push ecx                ; зберігаємо len на стеку
    mov eax, esi            ; EAX = sumDigits
    call itoa
    mov eax, 4
    mov ebx, 1
    ; ecx = вказівник на рядок (з itoa)
    int 0x80

    ; newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; I/O + math — виводимо len(x)
; ============================================================
    pop eax                 ; EAX = len (з стеку)
    call itoa
    mov eax, 4
    mov ebx, 1
    ; ecx = вказівник на рядок (з itoa)
    int 0x80

    ; newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; I/O — завершення
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ============================================================
; itoa — конвертує число в EAX в ASCII рядок в output_buf
; повертає EDX = довжина рядка, ECX = вказівник на рядок
; ============================================================
itoa:
    push eax
    push esi
    push edi

    ; memory — використовуємо output_buf
    mov edi, output_buf
    add edi, 30
    mov byte [edi+1], 0
    xor esi, esi

    ; logic — якщо 0
    test eax, eax
    jnz .itoa_loop
    mov byte [edi], '0'
    dec edi
    inc esi
    jmp .itoa_done

.itoa_loop:
    ; loops — ділимо на 10 поки не 0
    test eax, eax
    jz  .itoa_done
    xor edx, edx            ; обнуляємо EDX перед div
    mov ebx, 10
    div ebx                 ; EAX = EAX/10, EDX = залишок
    add dl, '0'
    mov [edi], dl           ; memory — записуємо цифру
    dec edi
    inc esi
    jmp .itoa_loop

.itoa_done:
    inc edi
    mov ecx, edi            ; ECX = вказівник на рядок
    mov edx, esi            ; EDX = довжина

    pop edi
    pop esi
    pop eax
    ret
