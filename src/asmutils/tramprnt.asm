; Print characters and strings to the TRAM.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
;
; Procedures:
;       int print_ch(int code, int x, int y, int attr);
;       int print_str(char const far* str, int x, int y, int attr);

pushstate
ideal
radix 10
locals
p386

include "..\src\asmdefs.asm"

; --------------------------------------------------------------------------
; Function: print_str
; Description: Prints a ASCIZ string onto the TRAM area. Will break and report
;              error when attempting to write to an out-of-bound coordinate.
; Input:  Argument 1 (dword): The address of the string
;         Argument 2 (word): The X coordinate on the TRAM. (0 ~ 79)
;         Argument 3 (word): The Y coordinate on the TRAM. (0 ~ 24)
;         Argument 4 (word): The text attribute.
; Output: (in AX): 0 if success, 1 if one of the coordinates is out of bound.
; --------------------------------------------------------------------------
proc print_str near
arg @@str:dword, @@x:word, @@y:word, @@attr:word
        push    ds si di

        mov     ds, [word ptr @@str + 2]
        mov     si, [word ptr @@str]
        mov     di, [@@x]

@@main_loop:
        movzx   ax, [ds:si]
        test    ax, ax
        jz      @@return_0
        push    [@@attr] [@@y] di ax
        call    print_ch
        add     sp, 8
        test    ax, ax
        jnz     @@return
        inc     di
        inc     si
        jmp     @@main_loop

@@return_0:
        xor     ax, ax
@@return:
        pop     di si ds
        ret
endp print_str

; --------------------------------------------------------------------------
; Function: print_ch
; Description: Prints a character onto the TRAM area. Will report error if the
;              coordinates are out of bound.
; Input:  Argument 1 (word): The code of the character.
;         Argument 2 (word): The X coordinate on the TRAM. (0 ~ 79)
;         Argument 3 (word): The Y coordinate on the TRAM. (0 ~ 24)
;         Argument 4 (word): The text attribute.
; Output: (in AX): 0 if success, 1 if the coordinates are out of bound.
; --------------------------------------------------------------------------
proc print_ch near
arg @@char:word, @@x:word, @@y:word, @@attr:word
        push    si

        ; Compute the offset (stored in si) (= y * 160 + x * 2)
        mov     si, [@@y]
        cmp     si, SCREEN_HEIGHT
        jae     @@return_1
        imul    si, 160
        mov     ax, [@@x]
        cmp     ax, SCREEN_WIDTH
        jae     @@return_1
        add     si, ax
        add     si, ax

        ; Print the character
        mov     ax, TRAM_SEG
        mov     es, ax
        mov     ax, [@@char]
        mov     [es:si], ax

        ; Set the attribute
        mov     ax, TRAM_ATTR_SEG
        mov     es, ax
        mov     ax, [@@attr]
        mov     [es:si], ax

        xor     ax, ax
        jmp     @@return
@@return_1:
        mov     ax, 1
@@return:
        pop     si
        ret
endp print_ch

popstate
