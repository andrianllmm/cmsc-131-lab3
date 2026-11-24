;
; fmt.asm - int_to_dec, integer to decimal text. Callable from C.
;
; The contract, from driver.c:
;
;       char *out                   [ebp+12]
;       int n                       [ebp+8]
;
;       int int_to_dec(int n, char *out)
;
; Write the decimal text of n into out, return the number of bytes written.
; No leading zeros except for n == 0, which is "0". No sign. No terminator.
; The caller provides a buffer at least 16 bytes.
;
; Requirements from the manual:
;
;   * Divide by ten repeatedly, collecting remainders, which come out
;     backwards.
;   * The stack does the reversal. Push each remainder, then pop them into
;     the output in order.
;   * The loop must be bottom-tested so that zero emits one digit. A
;     top-tested loop emits nothing for n == 0, which is the classic bug.
;   * Clear edx before every div. The div writes its remainder there.
;   * Preserve ebx, esi, edi, and ebp. Return the byte count in eax.
;   * No calls into the C standard library.
;
; The manual's loop:
;
;       mov ebx, 10
;       xor ecx, ecx              ; digit count
;   digit_loop:
;       mov edx, 0                ; clear before div, as always
;       div ebx                   ; eax = quotient, edx = remainder
;       add dl, '0'               ; remainder to ASCII
;       push edx                  ; stack reverses them for us
;       inc ecx
;       cmp eax, 0
;       jne digit_loop
;       ; now pop ecx digits into edi in the right order
;
; The driver never passes a negative. It does pass 0, for -c on a file
; with no matching line, and int_to_dec must print that as one digit.
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _int_to_dec int_to_dec
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _int_to_dec

_int_to_dec:
        enter   0,0
        push    ebx
        push    edi

        mov     eax, [ebp+8]            ; n (then the quotient)
        mov     edi, [ebp+12]           ; next output byte
        mov     ebx, 10
        xor     ecx, ecx                ; digit count

.collect_digits:
        xor     edx, edx                ; clear the high half of the dividend
        div     ebx
        add     dl, '0'
        push    edx                     ; least significant digit first
        inc     ecx
        test    eax, eax
        jnz     .collect_digits         ; also collect one digit for n == 0

        mov     eax, ecx                ; save the byte count for the return
.write_digits:
        pop     edx                     ; most significant digit first
        mov     [edi], dl
        inc     edi
        dec     ecx
        jnz     .write_digits

        pop     edi
        pop     ebx
        leave
        ret
