; ============================================================
; practice10.asm - двійковий вивід, popcount, бітові маски
; ============================================================

section .bss
    input_buf  resb 64
    output_buf resb 64

section .data
    str_bin    db 'binary: '
    str_bin_len equ $ - str_bin
    str_pop    db 'popcount: '
    str_pop_len equ $ - str_pop
    str_res    db 'result: '
    str_res_len equ $ - str_res
    space      db ' '
    newline    db 0x0A
    ; logic - позиції бітів для set/clear
    bit_p      dd 3         ; set bit p=3
    bit_q      dd 7         ; set bit q=7
    bit_r      dd 1         ; clear bit r=1

section .text
    global _start

_start:

; ============================================================
; I/O - читаємо x
; ============================================================
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 64
    int 0x80

; parse - atoi(x)
    mov ecx, input_buf
    call atoi
    mov edi, eax            ; EDI = x

; ============================================================
; loops - виводимо 32-бітне двійкове число групами по 4
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_bin
    mov edx, str_bin_len
    int 0x80

    mov esi, 31             ; починаємо з біта 31
    xor ecx, ecx            ; лічильник для груп по 4

.bin_loop:
    cmp esi, 0
    jl  .bin_done

    ; logic - перевіряємо біт: (x >> i) & 1
    mov eax, edi
    mov ecx, esi
    shr eax, cl             ; eax = x >> i
    and eax, 1              ; eax = біт i

    ; I/O - виводимо '0' або '1'
    add eax, '0'
    mov [output_buf], al
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    mov edx, 1
    int 0x80

    ; logic - пробіл кожні 4 біти
    mov eax, 31
    sub eax, esi            ; позиція від початку
    inc eax
    test eax, 3             ; кратно 4?
    jnz .no_space
    cmp esi, 0
    je  .no_space
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

.no_space:
    dec esi
    jmp .bin_loop

.bin_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; math + loops - popcount: рахуємо кількість одиничних бітів
; алгоритм: зсуваємо вправо, рахуємо & 1
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_pop
    mov edx, str_pop_len
    int 0x80

    mov esi, edi            ; ESI = x (копія)
    xor ecx, ecx            ; ECX = popcount = 0
    mov ebx, 32             ; 32 ітерації

.pop_loop:
    test ebx, ebx
    jz  .pop_done
    mov eax, esi
    and eax, 1              ; math - молодший біт
    add ecx, eax            ; popcount += біт
    shr esi, 1              ; зсуваємо вправо
    dec ebx
    jmp .pop_loop

.pop_done:
    mov eax, ecx
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
; logic - бітові операції: set p,q та clear r
; set bit p:  x = x | (1 << p)
; set bit q:  x = x | (1 << q)
; clear bit r: x = x & ~(1 << r)
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_res
    mov edx, str_res_len
    int 0x80

    mov eax, edi            ; EAX = x

    ; logic - set bit p=3
    mov ecx, [bit_p]
    mov ebx, 1
    shl ebx, cl             ; ebx = 1 << p
    or  eax, ebx            ; x |= (1 << p)

    ; logic - set bit q=7
    mov ecx, [bit_q]
    mov ebx, 1
    shl ebx, cl             ; ebx = 1 << q
    or  eax, ebx            ; x |= (1 << q)

    ; logic - clear bit r=1
    mov ecx, [bit_r]
    mov ebx, 1
    shl ebx, cl             ; ebx = 1 << r
    not ebx                 ; ebx = ~(1 << r)
    and eax, ebx            ; x &= ~(1 << r)

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
    add edi, 60
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
