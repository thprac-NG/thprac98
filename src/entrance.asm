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
        public  _load_th01

; Parameter structure of INT 21h/4B00h.
struc execblock_00
        env_seg                 dw ? ; 0000h: copy the caller's env seg
        command_line_off        dw ?
        command_line_seg        dw ?
        fcb1_off                dw ?
        fcb1_seg                dw ?
        fcb2_off                dw ?
        fcb2_seg                dw ?
ends execblock_00
PSP_FCB1_OFFSET EQU 5Ch
PSP_FCB2_OFFSET EQU 6Ch

params  execblock_00 <0, , , PSP_FCB1_OFFSET, , PSP_FCB2_OFFSET, >

mdrv98_load_param       db 4, ' -M7', 0Dh, 0
mdrv98_unload_param     db 2, ' -R', 0Dh, 0
op_param                db 4, '    ', 0Dh, 0
empty_command_param     db 0, 0Dh, 0
mdrv98_exe_name         db 'MDRV98.COM', 0
zunsoft_exe_name        db 'ZUNSOFT.COM', 0
op_exe_name             db 'OP.EXE', 0

psp_seg dw ?

saved_ss_sp     dd ?

proc _load_th01 near
arg @@path_off:word, @@path_seg:word
        ; Move the path string to codeseg
        mov     ax, [@@path_seg]
        mov     es, ax
        mov     si, [@@path_off]
        mov     di, offset game_directory
@@move_path_string_loop:
        mov     dl, [byte ptr es:si]
        test    dl, dl
        jz      @@end_of_move_path_string_loop
        mov     [byte ptr cs:di], dl
        inc     si
        inc     di
        jmp     @@move_path_string_loop
@@end_of_move_path_string_loop:

        ; Set several segment fields
        mov     ax, cs
        mov     [cs:params.command_line_seg], cs
        mov     ah, 62h
        int     21h             ; bx = [cs:psp_seg] {
        mov     [cs:psp_seg], bx
        mov     [cs:params.fcb1_seg], bx
        mov     [cs:params.fcb2_seg], bx

        ; Switch to a stack that won't be released by the shrink
        mov     ax, cs          ; ax = cs {
        cli
        mov     ss, ax
        mov     sp, offset initial_sp
        sti

        ; Save current drive & directory
        mov     ds, ax          ; ax = cs }
        mov     ah, 19h
        int     21h
        mov     dl, al
        add     al, 'A'
        mov     [byte ptr cs:saved_current_directory], al
        mov     si, (offset saved_current_directory)
        mov     ah, 47h
        int     21h
        jnc     @@get_current_directory_success
        mov     dx, offset failed_to_get_cd
        mov     ah, 09h
        int     21h
        jmp     @@return
@@get_current_directory_success:

        ; Change the current directory to the game directory
        mov     dl, [byte ptr cs:game_directory]
        sub     dl, 'A'
        mov     ah, 0Eh
        int     21h
        mov     dx, offset game_directory
        mov     ah, 3Bh
        int     21h
        jnc     @@set_current_directory_success
        mov     dx, offset failed_to_set_cd
        mov     ah, 09h
        int     21h
        mov     dl, [byte ptr cs:saved_current_directory]
        sub     dl, 'A'
        mov     ah, 0Eh
        int     21h
        jmp     @@return
@@set_current_directory_success:

        ; Call INT 21h/4Ah to shrink the allocated memory of the current process
        mov     es, bx          ; bx = [cs:psp_seg] }
        mov     bx, (offset terminate_and_stay_resident) + 10Fh
        shr     bx, 4
        mov     ah, 4Ah
        int     21h

        call    call_dos_exec c, (offset mdrv98_exe_name), \
                                 (offset mdrv98_load_param)
        test    ah, 80h
        jnz     @@end_of_loading
        call    call_dos_exec c, (offset zunsoft_exe_name), \
                                 (offset empty_command_param)
        test    ah, 80h
        jnz     @@unload_mdrv98_after_error
        call    call_dos_exec c, (offset op_exe_name), (offset op_param)
        test    ah, 80h
        jz      @@unload_mdrv98
@@unload_mdrv98_after_error:
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset trying_to_unload_mdrv98
        mov     ah, 09h
        int     21h
@@unload_mdrv98:
        call    call_dos_exec c, (offset mdrv98_exe_name), \
                                 (offset mdrv98_unload_param)
@@end_of_loading:

        ; Restore the current directory
        mov     dl, [byte ptr cs:offset saved_current_directory]
        sub     dl, 'A'
        mov     ah, 0Eh
        int     21h
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset saved_current_directory
        mov     ah, 3Bh
        int     21h
        jnc     @@restore_current_directory_success
        mov     dx, offset failed_to_restore_cd
        mov     ah, 09h
        int     21h
        jmp     @@return
@@restore_current_directory_success:

@@return:
        mov     ax, 4C00h
        int     21h
endp _load_th01

; Internal procedure, destroys all registers except CS, IP, SS, SP
; ret[15] == 0: Success.
;       ret[9:8]: termination type
;               00b: normal (INT 20h, INT 21h/00h, INT 21h/4Ch)
;               01b: Ctrl+C abort
;               10b: Critical error abort
;               11b: Terminate and stay resident (INT 21h/31h or INT 27h)
;       ret[7:0]: Return code
; ret[15] == 1: Failed.
;       ret[7:0]: Extended error code
;               02h: File not found
;               05h: Access denied
;               08h: Insufficient memory
;               0Ah: Environment invalid (usually >32k in length)
;               0Bh: Format invalid
proc call_dos_exec near
arg @@exe_name_offset:word, @@param_offset:word
        ; Call INT 21h/4B00h. SS:SP will be destroyed when calling it in
        ; DOS 2.0, so we are saving it before calling EXEC.
        mov     [word ptr cs:saved_ss_sp], sp
        mov     [word ptr cs:saved_ss_sp + 2], ss
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        mov     ax, [@@param_offset]
        mov     [params.command_line_off], ax
        mov     bx, offset params
        mov     dx, [@@exe_name_offset]
        mov     ax, 4B00h
        int     21h
        lss     sp, [cs:saved_ss_sp]

        ; Print error message if INT 21h/4B00h failed
        jnc     @@no_error
        mov     cl, al          ; cl: saved error code {
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset failed_to_execute_1
        mov     ah, 09h
        int     21h
        call    print_asciz_string c, [@@exe_name_offset]
        mov     dx, offset failed_to_execute_2
        mov     ah, 09h
        int     21h
        call    print_asciz_string c, [@@param_offset]
        mov     dx, offset failed_to_execute_3
        mov     ah, 09h
        int     21h
        call    print_error_code c, cx  ; cl: saved error code |
        ; Prepare the return value, then return
        mov     al, cl          ; cl: saved error code }
        mov     ah, 80h
        jmp     @@return
@@no_error:

        mov     ah, 4Dh
        int     21h
@@return:
        ret
endp call_dos_exec

; Internal procedure, destroys SI, AX, DX.
proc print_asciz_string near
arg @@str_off:word
        mov     si, [@@str_off]
        mov     ah, 02h
@@main_loop:
        mov     dl, [byte ptr cs:si]
        test    dl, dl
        jz      @@end_of_main_loop
        int     21h
        inc     si
        jmp     @@main_loop
@@end_of_main_loop:
        ret
endp print_asciz_string

; Internal procedure, destroys AX, DX, DI, SI.
proc print_error_code near
arg @@code:word
        mov     dx, [@@code]
        mov     di, offset error_code_num
        xor     si, si
@@print_loop:
        mov     al, dl
        and     al, 0Fh
        cmp     al, 10
        jge     @@L1
        add     al, 'A' - 10 - '0'
@@L1:
        add     al, '0'
        mov     [byte ptr cs:di], al
        inc     di
        shl     dl, 4
        inc     si
        cmp     si, 2
        jne     @@print_loop
        ret
endp print_error_code

failed_to_execute_1     db 'Failed to execute `$'
failed_to_execute_2     db "' with parameter `$"
failed_to_execute_3     db "'.", 0Ah, '$'
trying_to_unload_mdrv98 db 'Now trying to unload MDRV98.COM...', 0Ah, '$'
failed_to_get_cd        db 'Running in invalid drive.', 0Ah, '$'
failed_to_set_cd        db 'Game path not found.', 0Ah, '$'
failed_to_restore_cd    db "Can't return to previous working directory: ", \
                           'Path not found.', 0Ah, '$'
error_code_str          db 'Error code: '
error_code_num          db '??h.', 0Ah, '$'

game_directory          db 69 dup(0)    ; 69: [drive letter] + ":\\" + [longest
                                        ; ASCIZ string returned by INT 21h/3Bh
                                        ; (of length 64)] - "\0" + "\\\0"
saved_current_directory db 'A:\', 66 dup(0)

new_stack       db 100h dup(0)
initial_sp      dw 0

label terminate_and_stay_resident byte

real_main:
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