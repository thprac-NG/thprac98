; Compare strings, but ignore the cases.
;
; Procedures:
;       bool strcmp_ignore_case(const char far*, const char far*);

pushstate
ideal
radix 10
locals
p386

; --------------------------------------------------------------------------
; Function: strcmp_ignore_case
; Description: Compares two ASCIZ strings, without distinguishing the uppercase
;              and lowercase of the same letter.
; Input:  Argument 1 (dword): The address of the first string
;         Argument 2 (dword): The address of the second string
; Output: (in AX): 0 if the two strings are equal (in our sense), otherwise -1
; --------------------------------------------------------------------------
proc strcmp_ignore_case near
arg @@str1:dword, @@str2:dword
        push    es bx cx dx     ; Saving the registers for now.
                                ; # TODO: Save the caller-saved registers before
                                ; calling this function.
        push    ds si di

        mov     ax, [word ptr @@str1 + 2]
        mov     es, ax
        mov     di, [word ptr @@str1]
        mov     ax, [word ptr @@str2 + 2]
        mov     ds, ax
        mov     si, [word ptr @@str2]

@@str_check_loop:
        ; Convert the character from str1 to uppercase
        mov     al, [es:di]
        cmp     al, 'a'
        jb      @@ch1_not_lowercase
        cmp     al, 'z'
        ja      @@ch1_not_lowercase
        sub     al, 'a' - 'A'
@@ch1_not_lowercase:
        ; Convert the character from str2 to uppercase
        mov     bl, [ds:si]
        cmp     bl, 'a'
        jb      @@ch2_not_lowercase
        cmp     bl, 'z'
        ja      @@ch2_not_lowercase
        sub     bl, 'a' - 'A'
@@ch2_not_lowercase:
        ; If ch1 != ch2, return -1
        cmp     al, bl
        je      @@skip_return_neg1
        mov     ax, 0FFFFh
        jmp     @@return
@@skip_return_neg1:
        ; If ch1 == 0, return 0
        cbw
        test    ax, ax
        jz      @@return
        inc     si
        inc     di
        jmp     @@str_check_loop

@@return:
        pop     di si ds
        pop     dx cx bx es
        ret
endp strcmp_ignore_case

popstate
