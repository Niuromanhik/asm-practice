; ============================================================
; practice4.asm — зчитує рядок з консолі, конвертує в число,
; потім конвертує назад у рядок і виводить на екран
; ============================================================

section .bss
    input_buf resb 32       ; буфер для вводу (memory)
    output_buf resb 32      ; буфер для виводу (memory)

section .data
    newline db 0x0A         ; символ нового рядка

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
    mov esi, eax            ; зберігаємо кількість прочитаних байт

; ============================================================
; parse — конвертуємо ASCII рядок в ціле число (int) в AX
; обробляємо: пробіли спереду, знак мінус, цифри
; ============================================================
    mov ecx, input_buf      ; ECX = вказівник на початок рядка
    xor eax, eax            ; EAX = акумулятор результату
    xor ebx, ebx            ; EBX = прапор знаку (0=плюс, 1=мінус)

; пропускаємо пробіли і переноси на початку
.skip_spaces:
    mov dl, [ecx]
    cmp dl, ' '
    je .next_space
    cmp dl, 0x0A            ; newline
    je .next_space
    cmp dl, 0x0D            ; carriage return
    je .next_space
    jmp .check_sign
.next_space:
    inc ecx
    jmp .skip_spaces

; logic — перевіряємо знак
.check_sign:
    mov dl, [ecx]
    cmp dl, '-'
    jne .parse_digits
    mov ebx, 1              ; запам'ятовуємо мінус
    inc ecx

; loops — цикл обробки цифр
.parse_digits:
    mov dl, [ecx]
    cmp dl, '0'
    jl .parse_done
    cmp dl, '9'
    jg .parse_done

    ; math — AX = AX * 10 + (цифра - '0')
    imul eax, eax, 10
    sub dl, '0'
    movzx edx, dl
    add eax, edx
    inc ecx
    jmp .parse_digits

.parse_done:
    ; logic — якщо був мінус — заперечуємо
    test ebx, ebx
    jz .store_result
    neg eax

.store_result:
    mov ax, ax              ; результат в AX (16-біт, як вимагає задача)

; ============================================================
; math + loops — конвертуємо число з EAX в ASCII рядок
; ============================================================
    mov ecx, output_buf
    add ecx, 30             ; починаємо з кінця буфера
    mov byte [ecx+1], 0x0A  ; newline в кінці
    mov byte [ecx+2], 0     ; null terminator

    xor esi, esi            ; лічильник цифр
    xor ebx, ebx            ; прапор від'ємного числа

    ; logic — перевіряємо чи від'ємне
    test eax, eax
    jns .convert_loop
    neg eax
    mov ebx, 1

    ; loops — ділимо на 10, записуємо цифри у зворотньому порядку
.convert_loop:
    xor edx, edx
    mov edi, 10
    div edi                 ; EAX = EAX/10, EDX = залишок
    add dl, '0'
    mov [ecx], dl           ; memory — записуємо цифру
    dec ecx
    inc esi
    test eax, eax
    jnz .convert_loop

    ; logic — якщо від'ємне — додаємо мінус
    test ebx, ebx
    jz .print_number
    mov byte [ecx], '-'
    dec ecx
    inc esi

.print_number:
    inc ecx                 ; ECX вказує на початок рядка

; ============================================================
; I/O — виводимо результат на екран (stdout)
; ============================================================
    mov eax, 4              ; sys_write
    mov ebx, 1              ; fd = stdout
    ; ecx вже вказує на рядок
    add esi, 1              ; +1 для newline
    mov edx, esi
    int 0x80

; I/O — завершення програми
    mov eax, 1              ; sys_exit
    xor ebx, ebx            ; код виходу 0
    int 0x80
