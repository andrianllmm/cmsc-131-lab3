;
; lines.asm - index_lines, a file buffer to a list of lines. Callable from C.
;
; This is your starting point: it assembles and links as-is, so the build
; works before you write any code. Right now it returns 0 lines, which makes
; rengrep print nothing. Your job is to replace that with the index
; described below.
;
; The contract, from driver.c:
;
;       int max                     [ebp+20]
;       struct line *out            [ebp+16]
;       int len                     [ebp+12]
;       char *buf                   [ebp+8]
;
;       struct line { int offset; int length; };
;
; Fill out with one entry per line and return the number of entries
; written. The capacity is a hard limit: stop when out is full and return
; what you wrote. max == 0 writes nothing and returns 0.
;
; Requirements from the manual:
;
;   * A line's length EXCLUDES its trailing newline.
;   * A file with no trailing newline still indexes its last line.
;   * An empty file (len == 0) has zero lines.
;   * Preserve ebx, esi, edi, and ebp. Return the count in eax.
;   * No calls into the C standard library.
;
; The manual calls this "buffer to line index". Walk the buffer, find the
; newlines yourself, and record where each line starts and how long it
; is. The driver reads the file into one buffer and uses your index to
; treat it as a list of lines.
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _index_lines index_lines
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _index_lines

_index_lines:
        enter   0,0

        ; Save the registers we will use
        push    ebx                     ; Base register
        push    esi                     ; Source index
        push    edi                     ; Destination index

        ; Load the parameters into the registers
        mov     esi, [ebp+8]            ; buf -> pointer to the first byte
        mov     edi, [ebp+16]           ; out ->  the output (where to write the line offsets and lengths)
        mov     ebx, [ebp+20]           ; max -> how much room out has

        ; Initialize the counters 
        xor     ecx, ecx                ; i = 0
        xor     edx, edx                ; start = 0
        xor     eax, eax                ; count = 0

        ; Scan each byte for a newline
scan:

        cmp     ecx, [ebp+12]           ; i < len?
        jge     tail

        cmp     byte [esi+ecx], 0x0A    ; buf[i] == newline?
        jne     next

        ; Record the line, stop if out is full
        cmp     eax, ebx                ; count >= max?
        jge     done
        mov     [edi+eax*8], edx        ; offset = start
        mov     [edi+eax*8+4], ecx      ; length = i - start
        sub     [edi+eax*8+4], edx
        inc     eax                     ; count++
        lea     edx, [ecx+1]            ; start = i + 1
next:
        inc     ecx                     ; i++
        jmp     scan

        ; Record the last line if it has no newline
tail:
        cmp     edx, ecx                ; start < len?
        jge     done
        cmp     eax, ebx                ; count >= max?
        jge     done
        mov     [edi+eax*8], edx        ; offset = start
        mov     [edi+eax*8+4], ecx      ; length = len - start
        sub     [edi+eax*8+4], edx
        inc     eax                     ; count++

        ; Restore the registers, count is already in eax
done:
        pop     edi
        pop     esi
        pop     ebx
        leave
        ret
