; ============================================================
; practice14.asm - selection sort, медіана
; ============================================================

section .bss
    input_buf  resb 4096    ; memory - буфер вводу
    arr        resd 100     ; memory - масив
    n_val      resd 1
    out_buf    resb 32

section .data
    str_before  db 'before: '
    str_before_len equ $ - str_before
    str_after   db 'after: '
    str_after_len equ $ - str_after
    str_median  db 'median: '
    str_median_len equ $ - str_median
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

; parse - atoi(n)
    mov ecx, input_buf
    call atoi
    mov [n_val], eax

; ============================================================
; loops + parse - заповнюємо масив
; ============================================================
    xor esi, esi

.read_loop:
    cmp esi, [n_val]
    jge .read_done
    call atoi
    mov ebx, esi
    shl ebx, 2
    mov [arr + ebx], eax    ; memory - arr[i] = eax
    inc esi
    jmp .read_loop

.read_done:

; ============================================================
; I/O - виводимо масив до сортування
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_before
    mov edx, str_before_len
    int 0x80

    xor esi, esi
.print_before:
    cmp esi, [n_val]
    jge .print_before_done
    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]
    call print_num_space
    inc esi
    jmp .print_before
.print_before_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; loops - selection sort (вкладені цикли i/j)
; знаходимо мінімум від i до n-1, міняємо з arr[i]
; ============================================================
    xor esi, esi            ; i = 0

.sort_i:
    mov eax, [n_val]
    dec eax
    cmp esi, eax
    jge .sort_done

    ; logic - min_idx = i
    mov edi, esi            ; EDI = min_idx
    mov ecx, esi
    inc ecx                 ; j = i+1

.sort_j:
    cmp ecx, [n_val]
    jge .sort_swap

    ; logic - arr[j] < arr[min_idx]?
    mov ebx, ecx
    shl ebx, 2
    mov eax, [arr + ebx]    ; eax = arr[j]
    mov ebx, edi
    shl ebx, 2
    mov edx, [arr + ebx]    ; edx = arr[min_idx]
    cmp eax, edx
    jge .sort_j_next
    mov edi, ecx            ; min_idx = j

.sort_j_next:
    inc ecx
    jmp .sort_j

.sort_swap:
    ; math - міняємо arr[i] та arr[min_idx]
    cmp edi, esi
    je  .sort_i_next

    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]    ; eax = arr[i]
    mov ecx, edi
    shl ecx, 2
    mov edx, [arr + ecx]    ; edx = arr[min_idx]
    mov [arr + ebx], edx    ; arr[i] = arr[min_idx]
    mov [arr + ecx], eax    ; arr[min_idx] = arr[i]

.sort_i_next:
    inc esi
    jmp .sort_i

.sort_done:

; ============================================================
; I/O - виводимо відсортований масив
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_after
    mov edx, str_after_len
    int 0x80

    xor esi, esi
.print_after:
    cmp esi, [n_val]
    jge .print_after_done
    mov ebx, esi
    shl ebx, 2
    mov eax, [arr + ebx]
    call print_num_space
    inc esi
    jmp .print_after
.print_after_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

; ============================================================
; math - медіана: для парного n - нижня середня arr[n/2-1]
;                 для непарного  - arr[n/2]
; ============================================================
    mov eax, 4
    mov ebx, 1
    mov ecx, str_median
    mov edx, str_median_len
    int 0x80

    mov eax, [n_val]
    xor edx, edx
    mov ebx, 2
    div ebx                 ; eax = n/2, edx = n%2

    test edx, edx
    jnz .odd_median         ; непарне - arr[n/2]
    dec eax                 ; парне - arr[n/2 - 1]

.odd_median:
    mov ebx, eax
    shl ebx, 2
    mov eax, [arr + ebx]
    call print_num_nl

; I/O - вихід
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ============================================================
; print_num_space - виводить EAX + пробіл
; ============================================================
print_num_space:
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
    jns .ps_check
    neg eax
    mov ebx, 1

.ps_check:
    test eax, eax
    jnz .ps_div
    mov byte [edi], '0'
    dec edi
    inc esi
    jmp .ps_sign

.ps_div:
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    mov [edi], dl
    dec edi
    inc esi
    test eax, eax
    jnz .ps_div

.ps_sign:
    test ebx, ebx
    jz  .ps_done
    mov byte [edi], '-'
    dec edi
    inc esi

.ps_done:
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

; ============================================================
; print_num_nl - виводить EAX + newline
; ============================================================
print_num_nl:
    push eax
    push esi
    push edi
    push ebx

    mov edi, out_buf
    add edi, 28
    mov byte [edi+1], 0x0A
    xor esi, esi
    xor ebx, ebx

    test eax, eax
    jns .pn_check
    neg eax
    mov ebx, 1

.pn_check:
    test eax, eax
    jnz .pn_div
    mov byte [edi], '0'
    dec edi
    inc esi
    jmp .pn_sign

.pn_div:
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    mov [edi], dl
    dec edi
    inc esi
    test eax, eax
    jnz .pn_div

.pn_sign:
    test ebx, ebx
    jz  .pn_done
    mov byte [edi], '-'
    dec edi
    inc esi

.pn_done:
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
