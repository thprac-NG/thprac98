ideal
model small, cpp  ; Set calling convention to C++-style
radix 10  ; The immediates will be recognized as decimal by default
locals  ; Enables block-scoped symbols
stack 100h
p386

group DGROUP _DATA, _BSS, STACK

segment _BSS word public 'BSS'
ends _BSS
segment STACK stack 'STACK'
                db 100h dup(?)
exe_initial_sp  dw ?
ends STACK

codeseg
        jmp     real_main

        ; extern "C" int main_wrapper(char const far* program_name,
        ;                             int argument_size,
        ;                             char const far* raw_argument);
        extrn   _main_wrapper:proc
        ; extern "C" void stdio_init(void);
        extrn   _stdio_init:proc

        public  _load_th01
        public  th01_com_info

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
mdrv98_unload_param     db 3, ' -R', 0Dh, 0
op_param                db 4, '    ', 0Dh, 0
th01_com_unload_param   db 3, ' /U', 0Dh, 0
empty_command_param     db 0, 0Dh, 0
mdrv98_exe_name         db 'MDRV98.COM', 0
zunsoft_exe_name        db 'ZUNSOFT.COM', 0
op_exe_name             db 'OP.EXE', 0
th01_com_name           db 'TH01.COM', 0

psp_seg dw ?

saved_ss_sp     dd ?

struc embedded_com
        starting_pos    dd 99618848h
        size            dw 0000h
ends embedded_com

th01_com_info   embedded_com <>

th01_com_file_handle    dw ?
self_file_handle        dw ?
self_filename_ptr       dd ?

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
        int     21h
        mov     [cs:psp_seg], bx
        mov     [cs:params.fcb1_seg], bx
        mov     [cs:params.fcb2_seg], bx

        ; Switch to a stack that won't be released by the shrink
        mov     ax, cs
        cli
        mov     ss, ax
        mov     sp, offset initial_sp
        sti

        ; Create a temporary TH01.COM file.
        ; We first grow the file from (potentially) zero byte to 1 byte, then
        ; grow it to the desire size since, in some versions of DOS, using
        ; LSEEK to directly grow a zero-byte file to a large size can corrupt
        ; the FAT.
        mov     cx, 0
        mov     dx, offset th01_com_name
        mov     ax, cs
        mov     ds, ax
        mov     ah, 3Ch
        int     21h             ; Create/Truncate TH01.COM
        jc      @@create_th01_com_failed
        mov     [cs:th01_com_file_handle], ax
        mov     bx, ax
        mov     cx, 0
        mov     dx, 1
        mov     ax, 4200h
        int     21h             ; LSEEK TH01.COM to extend its size to 1
        jc      @@create_th01_com_failed
        mov     bx, [cs:th01_com_file_handle]
        mov     cx, 0
        mov     dx, [cs:th01_com_info.size]
        mov     ax, 4200h
        int     21h             ; LSEEK TH01.COM to extend its size
        jc      @@create_th01_com_failed
        mov     bx, [cs:th01_com_file_handle]
        mov     cx, 0
        mov     dx, 0
        mov     ax, 4200h
        int     21h             ; Seek TH01.COM back to origin
        jc      @@create_th01_com_failed

        ; Copy the file from the THPRAC98.EXE itself, using th01_com_info.
        ; NOTE: Must be called *before* shrinking the memory, since this section
        ; of code uses a buffer that will be shrinked during the shrink.
        lds     dx, [cs:self_filename_ptr]
        mov     ax, 3D00h
        int     21h             ; Open THPRAC98.EXE
        jnc     @@open_self_success
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset failed_to_open_self
        mov     ah, 09h
        int     21h
@@open_self_success:
        mov     [cs:self_file_handle], ax
        mov     bx, ax
        mov     si, offset th01_com_info.starting_pos
        mov     dx, [word ptr cs:si]
        mov     cx, [word ptr cs:si + 2]
        mov     ax, 4200h
        int     21h             ; Seek in THPRAC98.EXE
        jc      @@create_th01_com_failed
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset th01_com_buffer
        xor     di, di          ; di: Bytes read
@@copy_th01_com_loop:
        mov     cx, TH01_COM_BUFFER_SIZE
        mov     bx, [cs:self_file_handle]
        mov     ah, 3Fh
        int     21h             ; Read from THPRAC98.EXE
        mov     cx, [cs:th01_com_info.size]
        sub     cx, di
        cmp     cx, TH01_COM_BUFFER_SIZE
        jle     @@L1
        mov     cx, TH01_COM_BUFFER_SIZE
@@L1:
        add     di, TH01_COM_BUFFER_SIZE
        mov     bx, [cs:th01_com_file_handle]
        mov     ah, 40h
        int     21h             ; Write into TH01.COM
        cmp     di, [cs:th01_com_info.size]
        jl      @@copy_th01_com_loop
        mov     bx, [cs:th01_com_file_handle]
        mov     ah, 3Eh
        int     21h             ; Close TH01.COM
        mov     bx, [cs:self_file_handle]
        mov     ah, 3Eh
        int     21h             ; Close THPRAC98.EXE

        ; Call INT 21h/4Ah to shrink the allocated memory of the current process
        mov     es, [cs:psp_seg]
        mov     bx, (offset terminate_and_stay_resident) + 10Fh
        shr     bx, 4
        mov     ah, 4Ah
        int     21h

        ; Load TH01.COM
        call    call_dos_exec c, (offset th01_com_name), \
                                 (offset empty_command_param)
        test    ah, 80h
        jnz     @@delete_th01_com

        ; Save current drive & directory
        mov     ax, cs
        mov     ds, ax
        mov     ah, 19h
        int     21h
        mov     dl, al
        add     al, 'A'
        mov     [byte ptr cs:saved_current_directory], al
        inc     dl
        mov     si, (offset saved_current_directory + 3)
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

        call    call_dos_exec c, (offset mdrv98_exe_name), \
                                 (offset mdrv98_load_param)
        test    ah, 80h
        jnz     @@end_of_loading
        call    call_dos_exec c, (offset zunsoft_exe_name), \
                                 (offset empty_command_param)
        test    ah, 80h
        jnz     @@unload_mdrv98
        call    call_dos_exec c, (offset op_exe_name), (offset op_param)
        test    ah, 80h
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

        call    call_dos_exec c, (offset th01_com_name), \
                                 (offset th01_com_unload_param)

@@delete_th01_com:
        ; Delete TH01.COM
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset th01_com_name
        mov     ah, 41h
        int     21h
        jmp     @@return

@@create_th01_com_failed:
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset failed_to_create_th01
        mov     ah, 09h
        int     21h

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
failed_to_get_cd        db 'Running in invalid drive.', 0Ah, '$'
failed_to_set_cd        db 'Game path not found.', 0Ah, '$'
failed_to_restore_cd    db "Can't return to previous working directory: ", \
                           'Path not found.', 0Ah, '$'
failed_to_create_th01   db 'Failed to create TH01.COM.', 0Ah, '$'
failed_to_open_self     db 'Failed to open THPRAC98.EXE.', 0Ah, '$'
error_code_str          db 'Error code: '
error_code_num          db '??h.', 0Ah, '$'

game_directory          db 69 dup(0)    ; 69: [drive letter] + ":\\" + [longest
                                        ; ASCIZ string returned by INT 21h/3Bh
                                        ; (of length 64)] - "\0" + "\\\0"
saved_current_directory db 'A:\', 66 dup(0)

new_stack       db 100h dup(0)
initial_sp      dw 0

label terminate_and_stay_resident byte

TH01_COM_BUFFER_SIZE    EQU 100h
th01_com_buffer         db TH01_COM_BUFFER_SIZE dup (0)

real_main:
        mov     ax, @data
        mov     ds, ax
        mov     ss, ax
        mov     sp, offset exe_initial_sp

        call    _stdio_init

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
        mov     [word ptr cs:self_filename_ptr], si
        mov     [word ptr cs:self_filename_ptr + 2], ax
        push    ax si           ; push `program_name` argument of main_wrapper
        call    _main_wrapper
        add     sp, 10
        ; ax = return value
        mov     ah, 4Ch
        int     21h
; end of real_main

end