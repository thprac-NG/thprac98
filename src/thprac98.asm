ideal
model small, cpp  ; Set calling convention to C++-style
radix 10  ; The immediates will be recognized as decimal by default
locals  ; Enables block-scoped symbols
stack 100h
p386

codeseg
        jmp     real_main
        ; extern "C" int main_wrapper(char const far* program_name,
        ;                             int argument_size,
        ;                             char const far* raw_argument);
        extrn   _main_wrapper:proc

label terminate_and_stay_resident byte

real_main:
        ; jmp     $
        mov     ax, @data
        mov     ds, ax
        mov     ss, ax

        ; Calculate arguments to pass to the `main_wrapper` function
        mov     ah, 62h
        int     21h             ; Get current PSP
        mov     es, bx          ; es = bx = current PSP
        push    es 81h          ; push `raw_argument` argument of main_wrapper
        mov     ah, 0
        mov     al, [byte ptr es:80h]
        push    ax              ; push `argument_size` argument of main_wrapper
        mov     si, 2Ch
        mov     ax, [es:si]
        mov     es, ax          ; es = ax = environment block segment
        mov     si, 0
@@L1:
        cmp     [word ptr es:si], 0
        je      @@found_program_name
        inc     si
        jmp     @@L1
@@found_program_name:
        add     si, 4           ; skip the environment variables' '\0\0' tail
                                ; and the following word
        push    ax si           ; push `program_name` argument of main_wrapper
        call    _main_wrapper
        add     sp, 10
        ; ax = return value
        mov     ah, 4Ch
        int     21h
; end of real_main

segment dseg para public 'DATA'

ends dseg

end