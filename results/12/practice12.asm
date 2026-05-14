; ============================================================
; practice12.asm - пошук підрядка в рядку, підрахунок входжень
; ============================================================

section .bss
    input_buf  resb 512     ; memory - весь ввід одразу
    text_buf   resb 256     ; memory - буфер для тексту
    pat_buf    resb 64      ; memory - буфер для патерну
    text_len   resd 1
    pat_len    resd 1
    limit      resd 1

section .data
    str_first     db 'first: '
    str_first_len equ $ - str_first
    str_count     db 'count: '
    str_count_len equ $ - str_count
    str_none      db '-1'
    str_none_len  equ $ - str_none
    out_buf       times 16 db 0
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
    mov edx, 511
    int 0x80

; ============================================================
; parse - копіюємо перший рядок в text_buf
; ============================================================
    mov esi, input_buf
    mov edi, text_buf
    xor ecx, ecx            ; ECX = довжина тексту

.copy_text:
    mov al, [esi]
    cmp al, 0x0A
    je  .text_copied
    cmp al, 0
    je  .text_copied
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    jmp .copy_text

.text_copied:
    mov byte [edi], 0       ; null terminator
    mov [text_len], ecx
    inc esi                 ; пропускаємо newline

; parse - копіюємо другий рядок в pat_buf
    mov edi, pat_buf
    xor ecx, ecx

.copy_pat:
    mov al, [esi]
    cmp al, 0x0A
    je  .pat_copied
    cmp al, 0
    je  .pat_copied
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    jmp .copy_pat

.pat_copied:
    mov byte [edi], 0
    mov [pat_len], ecx

; ============================================================
; logic - порожній патерн
; ============================================================
    cmp dword [pat_len], 0
    jne .do_search

    mov eax, 4
    mov ebx, 1
    mov ecx, str_first
    mov edx, str_first_len
    int 0x80
    mov eax, 0
    call itoa_print

    mov eax, 4
    mov ebx, 1
    mov ecx, str_count
    mov edx, str_count_len
    int 0x80
    mov eax, [text_len]
    inc eax
    call itoa_print
    jmp .exit

; ============================================================
; logic + loops - наївний пошук підрядка
; ============================================================
.do_search:
    ; math - limit = text_len - pat_len + 1
    mov eax, [text_len]
    sub eax, [pat_len]
    inc eax
    mov [limit], eax

    xor esi, esi            ; ESI = i
    mov edi, -1             ; EDI = first = -1
    xor ebp, ebp            ; EBP = count

.outer_loop:
    cmp esi, [limit]
    jge .search_done

    ; loops - внутрішній цикл
    xor ecx, ecx            ; ECX = j

.inner_loop:
    cmp ecx, [pat_len]
    jge .match_found

    ; logic - порівнюємо text[i+j] з pat[j]
    mov edx, esi
    add edx, ecx
    mov al, [text_buf + edx]
    mov bl, [pat_buf + ecx]
    cmp al, bl
    jne .no_match

    inc ecx
    jmp .inner_loop

.match_found:
    inc ebp
    cmp edi, -1
    jne .after_first
    mov edi, esi
.after_first:
    add esi, [pat_len]
    jmp .outer_loop

.no_match:
    inc esi
    jmp .outer_loop

.search_done:

; ============================================================
; I/O - виводимо first
; ============================================================
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
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    jmp .print_count

.print_first_val:
    mov eax, edi
    call itoa_print

; ============================================================
; I/O - виводимо count
; ============================================================
.print_count:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_count
    mov edx, str_count_len
    int 0x80
    mov eax, ebp
    call itoa_print

.exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ============================================================
; itoa_print - виводить EAX + newline
; ============================================================
itoa_print:
    push eax
    push esi
    push edi
    push ebx

    mov edi, out_buf
    add edi, 14
    mov byte [edi+1], 0x0A
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
    inc esi
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
