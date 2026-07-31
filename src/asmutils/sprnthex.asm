; Print hexadecimal numbers to ASCII string.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
;
; Procedures:
;       unsigned near to_hex_digit(unsigned);
;       void near sprint_byte(char near*, unsigned);
;       void near sprint_word(char near*, unsigned);
;       void near sprint_dword(char near*, unsigned long);

pushstate
ideal
radix 10
locals
p386

; --------------------------------------------------------------------------
; Function: to_hex_digit
; Description: Transform a nibble to a hex digit character.
; Input:  Argument 1 (word): The hex digit to be transformed. Ignores all but
;                            the lowest nibbles.
; Output: (in AX): The ASCII code of the transformed character (uppercase).
; --------------------------------------------------------------------------
proc to_hex_digit near
arg @@num:word
        mov     ax, [@@num]
        and     ax, 0Fh
        cmp     ax, 10
        jl      @@is_dec_digit
        add     ax, 'A' - 10
        jmp     @@return
@@is_dec_digit:
        add     ax, '0'
@@return:
        ret
endp to_hex_digit

; --------------------------------------------------------------------------
; Function: sprint_byte
; Description: Print a byte in hex to a string. All letters are uppercase.
;              The '\0' won't be appended.
; Input:  Argument 1 (word): The offset of the string.
;         Argument 2 (word): The value to print. The higher byte is ignored.
; Output: Nothing
; --------------------------------------------------------------------------
proc sprint_byte near
arg @@off:word, @@num:word
        push    si
        mov     si, [@@off]

        ; Print the lower nibble
        push    [@@num]
        call    to_hex_digit            ; delayed sp+2
        mov     [si + 1], al
        ; Print the higher nibble
        mov     ax, [@@num]
        shr     ax, 4
        push    ax
        call    to_hex_digit            ; delayed sp+2
        add     sp, 4                   ; sp+4
        mov     [si], al

        pop     si
        ret
endp sprint_byte

; --------------------------------------------------------------------------
; Function: sprint_word
; Description: Print a hex word to a string. All letters are uppercase.
;              The '\0' won't be appended.
; Input:  Argument 1 (word): The offset of the string.
;         Argument 2 (word): The word to print.
; Output: Nothing
; --------------------------------------------------------------------------
proc sprint_word near
arg @@off:word, @@num:word
        push    si
        mov     cx, 0
        mov     si, [@@off]
        add     si, 3
@@print_nibble_loop:
        mov     ax, [@@num]
        shr     ax, cl
        push    cx
        push    ax
        call    to_hex_digit
        add     sp, 2
        pop     cx
        mov     [si], al
        add     cx, 4
        dec     si
        cmp     cx, 16
        jne     @@print_nibble_loop
        pop     si
        ret
endp sprint_word

; --------------------------------------------------------------------------
; Function: sprint_dword
; Description: Print a hex dword to a string. All letters are uppercase.
;              The '\0' won't be appended.
; Input:  Argument 1 (word): The offset of the string.
;         Argument 2 (dword): The dword to print.
; Output: Nothing
; --------------------------------------------------------------------------
proc sprint_dword near
arg @@off:word, @@num:dword
        push    si
        mov     si, [@@off]
        push    [word ptr @@num + 2] si
        call    sprint_word              ; delayed sp+4
        add     si, 4
        push    [word ptr @@num] si
        call    sprint_word              ; delayed sp+4
        add     sp, 8                    ; sp+8
        pop     si
        ret
endp sprint_dword

popstate
