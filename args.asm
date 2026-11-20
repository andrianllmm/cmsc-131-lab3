;
; args.asm - parse_args, the command line to a flag set, a pattern, and a
; file name. Callable from C.
;
; The contract, from driver.c:
;
;       struct args *out            [ebp+16]
;       char **argv                 [ebp+12]
;       int argc                    [ebp+8]
;
;       int parse_args(int argc, char **argv, struct args *out)
;
;       struct args { int flags; char *pattern; char *path; };
;                     +0         +4             +8
;
;       FLAG_N = 1, FLAG_C = 2, FLAG_V = 4, FLAG_I = 8, FLAG_W = 16
;
; Fill out and return 0. Return -1 when the pattern or the file is missing,
; or when a third positional token appears. Return the offending character,
; as a positive number, on an unknown flag. The driver prints it.
;
; Requirements from the manual:
;
;   * A token whose first byte is '-' and whose second byte is not NUL is a
;     flag group, wherever it appears. -nvi is -n -v -i. "-" alone is not a
;     flag group.
;   * Every other token is positional. The first is the pattern, the second
;     is the file.
;   * Keep the flag characters in a table, in bit order, and find each one
;     with scasb. The bit is 1 shifted left by the table index. A chain of
;     cmp/je is the structure the rubric marks down.
;   * Set cld explicitly. scasb honours the direction flag.
;   * Preserve ebx, esi, edi, and ebp. Return in eax.
;   * No calls into the C standard library.
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _parse_args parse_args
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

%ifdef ELF_TYPE
segment .rodata
%else
segment .rdata
%endif
flag_chars: db "ncviw"
flag_count: equ $ - flag_chars

segment .text
        global  _parse_args

_parse_args:
        enter   0,0
        push    ebx
        push    esi
        push    edi
        cld

        mov     edi, [ebp+16]            ; out
        xor     eax, eax
        mov     [edi], eax              ; flags
        mov     [edi+4], eax            ; pattern
        mov     [edi+8], eax            ; path

        mov     edx, [ebp+12]            ; argv
        mov     ebx, 1                   ; skip argv[0]

.next_arg:
        cmp     ebx, [ebp+8]
        jge     .check_positionals
        mov     esi, [edx+ebx*4]
        inc     ebx
        cmp     byte [esi], '-'
        jne     .positional
        cmp     byte [esi+1], 0
        je      .positional
        inc     esi

.next_flag:
        movzx   eax, byte [esi]
        test    eax, eax
        jz      .next_arg
        mov     edi, flag_chars
        mov     ecx, flag_count
        repne scasb
        jne     .done                    ; eax holds the unknown byte

        ; SCASB also counts the hit, so index = flag_count - ecx - 1.
        neg     ecx
        add     ecx, flag_count - 1
        mov     eax, 1
        shl     eax, cl
        mov     edi, [ebp+16]
        or      [edi], eax
        inc     esi
        jmp     .next_flag

.positional:
        cmp     dword [edi+4], 0
        je      .save_pattern
        cmp     dword [edi+8], 0
        jne     .bad_positionals
        mov     [edi+8], esi
        jmp     .next_arg

.save_pattern:
        mov     [edi+4], esi
        jmp     .next_arg

.check_positionals:
        cmp     dword [edi+8], 0         ; a path also means a pattern was saved
        je      .bad_positionals
        xor     eax, eax
        jmp     .done

.bad_positionals:
        mov     eax, -1

.done:
        pop     edi
        pop     esi
        pop     ebx
        leave
        ret
