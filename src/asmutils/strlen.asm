; Check the length of an ASCIZ string.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
;
; Procedures:
;       int near string_length(const char far*);

pushstate
ideal
radix 10
locals
p386

; --------------------------------------------------------------------------
; Function: string_length
; Description: Check the length of an ASCIZ string.
; Input:  Argument 1 (dword): The address of the string.
; Output: (in AX): The length of the string.
; --------------------------------------------------------------------------
proc string_length near
arg @@str:dword
        mov     bx, [word ptr @@str]
        mov     es, [word ptr @@str + 2]
        xor     ax, ax
@@main_loop:
        cmp     [byte ptr es:bx], 0
        je      @@main_loop_break
        inc     bx
        inc     ax
        jmp     @@main_loop
@@main_loop_break:
        ret
endp string_length

popstate
