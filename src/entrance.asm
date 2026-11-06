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
        assume  ds:nothing, es:nothing
        jmp     real_main

        ; extern "C" int main_wrapper(char const far* program_name,
        ;                             int argument_size,
        ;                             char const far* raw_argument);
        extrn   _main_wrapper:proc
        ; extern "C" void stdio_init(void);
        extrn   _stdio_init:proc

        public  _load_th01
        public  _load_th02
        public  th01_com_info
        public  th02_com_info

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
int21_4b_params execblock_00 <0, , , PSP_FCB1_OFFSET, , PSP_FCB2_OFFSET, >

zuninit_fcb     db 0, 'ZUNINIT ', '   ', 4 dup (0)
zun_res_fcb     db 0, 'ZUN_RES ', '   ', 4 dup (0)
ongchk_fcb      db 0, 'ONGCHK  ', '   ', 4 dup (0)
zunsoft_fcb     db 0, 'ZUNSOFT ', '   ', 4 dup (0)

PSP_FCB1_OFFSET EQU 5Ch
PSP_FCB2_OFFSET EQU 6Ch

; Common Params
dash_r_param            db 3, ' -R', 0Dh, 0
slash_u_param           db 3, ' /U', 0Dh, 0
slash_r_param           db 3, ' /R', 0Dh, 0
empty_command_param     db 0, 0Dh, 0
; TH01-specific params
mdrv98_load_param       db 4, ' -M7', 0Dh, 0
; TH02-specific params
zun_com_init_param      db 8, ' zuninit', 0Dh, 0
zun_com_init_r_param    db 11, ' zuninit -r', 0Dh, 0
zun_com_res_param       db 8, ' zun_res', 0Dh, 0
zun_com_res_r_param     db 11, ' zun_res -r', 0Dh, 0
zun_com_ongchk_param    db 7, ' ongchk', 0Dh, 0
zun_com_zunsoft_param   db 12, ' zunsoft.com', 0Dh, 0
mmd_load_param          db 11, ' /D /K /M12', 0Dh, 0
pmd_load_param          db 15, ' /M8 /V0 /E2 /K', 0Dh, 0
; Executable names
mdrv98_com_name         db 'MDRV98.COM', 0
zunsoft_com_name        db 'ZUNSOFT.COM', 0
zun_com_name            db 'ZUN.COM', 0
mmd_com_name            db 'MMD.COM', 0
pmd_com_name            db 'PMD.COM', 0
pmd86_com_name          db 'PMD86.COM', 0
pmdb2_com_name          db 'PMDB2.COM', 0
op_exe_name             db 'OP.EXE', 0
tsr_com_name            db 'THP98TSR.COM', 0

psp_seg dw ?
self_filename_ptr       dd ?

saved_ss_sp     dd ?

struc embedded_com
        starting_pos    dd 99618848h
        size            dw 0000h
ends embedded_com

th01_com_info           embedded_com <>
th02_com_info           embedded_com <>
selected_com_info       dw ?
simulated_game_bat_proc dw ?

proc load_game near
@@path_off      = +4
@@path_seg      = +6
        ; Move the path string to codeseg
        mov     ax, [bp + @@path_seg]
        mov     es, ax
        mov     si, [bp + @@path_off]
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
        mov     [cs:int21_4b_params.command_line_seg], cs
        mov     ah, 62h
        int     21h             ; Get current PSP address in BX
        mov     [cs:psp_seg], bx
        mov     [cs:int21_4b_params.fcb1_seg], bx
        mov     [cs:int21_4b_params.fcb2_seg], bx

        ; Switch to a stack that won't be released by the shrink
        mov     ax, cs
        cli
        mov     ss, ax
        mov     sp, offset initial_sp
        sti

        ; Create a temporary THP98TSR.COM file.
        ; We first grow the file from (potentially) zero byte to 1 byte, then
        ; grow it to the desire size since, in some versions of DOS, using
        ; LSEEK to directly grow a zero-byte file to a large size can corrupt
        ; the FAT.
        mov     si, [cs:selected_com_info]      ; SI: [selected_com_info]
        xor     cx, cx
        mov     dx, offset tsr_com_name
        mov     ax, cs
        mov     ds, ax
        mov     ah, 3Ch
        int     21h             ; Create/Truncate TMP98TSR.COM
        jc      @@create_com_failed
        mov     [cs:@@tsr_com_file_handle], ax
        mov     bx, ax
        xor     cx, cx
        mov     dx, 1
        mov     ax, 4200h
        int     21h             ; LSEEK TMP98TSR.COM to extend its size to 1
        jc      @@create_com_failed
        mov     bx, [cs:@@tsr_com_file_handle]
        xor     cx, cx
        mov     dx, [cs:si + embedded_com.size]
        mov     ax, 4200h
        int     21h             ; LSEEK TMP98TSR.COM to extend its size
        jc      @@create_com_failed
        mov     bx, [cs:@@tsr_com_file_handle]
        xor     cx, cx
        xor     dx, dx
        mov     ax, 4200h
        int     21h             ; Seek TMP98TSR.COM back to origin
        jc      @@create_com_failed
        ;
        ; Copy the file from the THPRAC98.EXE itself, using selected_com_info.
        ; NOTE: Must be called *before* shrinking the memory, since this section
        ; of code uses a buffer that will be shrinked.
        lds     dx, [cs:self_filename_ptr]
        mov     ax, 3D00h
        int     21h             ; Open THPRAC98.EXE
        jc      @@open_self_failed
        mov     [cs:@@self_file_handle], ax
        mov     bx, ax
        mov     dx, [word ptr cs:si + embedded_com.starting_pos]
        mov     cx, [word ptr cs:si + (2 + embedded_com.starting_pos)]
        mov     ax, 4200h
        int     21h             ; Seek in THPRAC98.EXE
        jc      @@create_com_failed
        mov     ax, cs
        mov     ds, ax
        mov     dx, (offset tsr_com_buffer)
        xor     di, di
        ;   The loop to copy the content from THPRAC98.EXE to THP98TSR.COM.
        ;   DI: Bytes read
@@copy_tsr_com_loop:
        mov     cx, TSR_COM_BUFFER_SIZE
        mov     bx, [cs:@@self_file_handle]
        mov     ah, 3Fh
        int     21h             ; Read from THPRAC98.EXE
        mov     cx, [cs:si + embedded_com.size]
        add     di, ax
        mov     cx, ax
        mov     bx, [cs:@@tsr_com_file_handle]
        mov     ah, 40h
        int     21h             ; Write into THP98TSR.COM
        cmp     di, [cs:si + embedded_com.size]
        jl      @@copy_tsr_com_loop
        mov     bx, [cs:@@tsr_com_file_handle]
        mov     ah, 3Eh
        int     21h             ; Close THP98TSR.COM
        mov     bx, [cs:@@self_file_handle]
        mov     ah, 3Eh
        int     21h             ; Close THPRAC98.EXE

        ; Call INT 21h/4Ah to shrink the allocated memory of the current process
        mov     es, [cs:psp_seg]
        mov     bx, (offset terminate_and_stay_resident) + 10Fh
        shr     bx, 4
        mov     ah, 4Ah
        int     21h             ; Shrink the memory

        ; Load THP98TSR.COM
        push    (offset empty_command_param) (offset tsr_com_name)
        call    call_dos_exec
        add     sp, 4
        test    ah, 80h
        jnz     @@delete_tsr_com

        ; Save current drive & directory (DS: CS)
        mov     ax, cs
        mov     ds, ax
        mov     ah, 19h
        int     21h             ; Get current drive letter in AL (00h = 'A')
        add     al, 'A'
        mov     [byte ptr cs:saved_current_directory], al
        xor     dl, dl
        mov     si, (offset saved_current_directory + 3)
        mov     ah, 47h         ; Get current directory of current drive in
        int     21h             ; [DS:SI]
        jc      @@get_cd_failed
        ;
        ; Change the current directory to the game directory
        mov     dl, [byte ptr cs:game_directory]
        sub     dl, 'A'
        mov     ah, 0Eh
        int     21h             ; Select default drive (00h = 'A')
        mov     dx, offset game_directory
        mov     ah, 3Bh
        int     21h             ; Set current directory
        jnc     @@set_current_directory_success
        mov     dx, offset failed_to_set_cd
        mov     ah, 09h
        int     21h
        mov     dl, [byte ptr cs:saved_current_directory]
        sub     dl, 'A'
        mov     ah, 0Eh
        int     21h             ; Select default drive
        jmp     @@unload_tsr_com
@@set_current_directory_success:

        ; Simulate the behaviour of the original GAME.BAT
        call    [word ptr simulated_game_bat_proc]

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
@@restore_current_directory_success:

        ; Unload THP98TSR.COM
@@unload_tsr_com:
        push    (offset slash_u_param) (offset tsr_com_name)
        call    call_dos_exec
        add     sp, 4

@@delete_tsr_com:
        ; Delete THP98TSR.COM
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset tsr_com_name
        mov     ah, 41h
        int     21h
        jmp     @@return

@@get_cd_failed:
        mov     dx, (offset failed_to_get_cd)
        jmp     @@print_error_message_in_dx

@@open_self_failed:
        mov     dx, (offset failed_to_open_self)
        jmp     @@print_error_message_in_dx

@@create_com_failed:
        mov     dx, (offset failed_to_create_tsr)

@@print_error_message_in_dx:
        mov     ax, cs
        mov     ds, ax
        mov     ah, 09h
        int     21h

@@return:
        mov     ax, 4C00h
        int     21h

@@tsr_com_file_handle   dw ?
@@self_file_handle      dw ?
endp load_game

proc simulated_th01_game_bat near
        ; Load MDRV98.COM with param '-M7'
        push    (offset mdrv98_load_param) (offset mdrv98_com_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load ZUNSOFT.COM
        push    (offset empty_command_param) (offset zunsoft_com_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load OP.EXE
        push    (offset empty_command_param) (offset op_exe_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load MDRV98.COM with param '-R'
        push    (offset dash_r_param) (offset mdrv98_com_name)
        call    call_dos_exec           ; delayed sp+4
        add     sp, 16                  ; sp+16

        ret
endp simulated_th01_game_bat

proc _load_th01 near
arg @@path_off:word, @@path_seg:word
        mov     [word ptr simulated_game_bat_proc], \
                (offset simulated_th01_game_bat)
        mov     [word ptr selected_com_info], offset th01_com_info
        jmp     load_game
endp _load_th01

proc simulated_th02_game_bat near
local @@driver_off:word
        ; We need to set up the FCB1 in the PSP here, since ZUN.COM uses it
        ; to detect the executable name.
        ; Load ZUN.COM with param 'zuninit'
        mov     [word ptr int21_4b_params.fcb1_off], 100h + (offset zuninit_fcb)
        push    (offset zun_com_init_param) (offset zun_com_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load ZUN.COM with param 'zun_res'
        mov     [word ptr int21_4b_params.fcb1_off], 100h + (offset zun_res_fcb)
        push    (offset zun_com_res_param) (offset zun_com_name)
        call    call_dos_exec           ; delayed sp+4
        add     sp, 8                   ; sp+8
        ; Jump to label `fin` if errorlevel=1
        cmp     al, 1
        je      @@fin

        ; Load MMD.COM with param '/D /K /M12'
        push    (offset mmd_load_param) (offset mmd_com_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load ZUN.COM with param 'ongchk'
        mov     [word ptr int21_4b_params.fcb1_off], 100h + (offset ongchk_fcb)
        push    (offset zun_com_ongchk_param) (offset zun_com_name)
        call    call_dos_exec           ; delayed sp+4
        ;
        ; Select the sound driver according to the errorlevel
        cmp     al, 6
        jae     @@skip_setting_default_value
        xor     al, al
@@skip_setting_default_value:
        shl     al, 1
        movzx   bx, al
        mov     ax, [word ptr bx + @@driver_exes]
        mov     [@@driver_off], ax
        ;
        ; Load sound driver with param '/M8 /V0 /E2 /K'
        push    (offset pmd_load_param) [@@driver_off]
        call    call_dos_exec           ; delayed sp+4
        ; Load ZUN.COM with param 'zunsoft.com'
        mov     [word ptr int21_4b_params.fcb1_off], 100h + (offset zunsoft_fcb)
        push    (offset zun_com_zunsoft_param) (offset zun_com_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load OP.EXE with empty param
        push    (offset empty_command_param) (offset op_exe_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load sound driver with param '/R'
        push    (offset slash_r_param) [@@driver_off]
        call    call_dos_exec           ; delayed sp+4
        add     sp, 24                  ; sp+24

@@fin:
        ; Load MMD.COM with param '/R'
        push    (offset slash_r_param) (offset mmd_com_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load ZUN.COM with param 'zuninit -r'
        mov     [word ptr int21_4b_params.fcb1_off], 100h + (offset zuninit_fcb)
        push    (offset zun_com_init_r_param) (offset zun_com_name)
        call    call_dos_exec           ; delayed sp+4
        ; Load ZUN.COM with param 'zun_res -r'
        mov     [word ptr int21_4b_params.fcb1_off], 100h + (offset zun_res_fcb)
        push    (offset zun_com_res_r_param) (offset zun_com_name)
        call    call_dos_exec           ; delayed sp+4
        add     sp, 12

        ret

@@driver_exes   dw (offset pmd_com_name), (offset pmd_com_name), \
                   (offset pmdb2_com_name), (offset pmd86_com_name), \
                   (offset pmdb2_com_name), (offset pmd86_com_name)
endp simulated_th02_game_bat

proc _load_th02 near
arg @@path_off:word, @@path_seg:word
        mov     [word ptr simulated_game_bat_proc], \
                (offset simulated_th02_game_bat)
        mov     [word ptr selected_com_info], offset th02_com_info
        jmp     load_game
endp _load_th02

; --------------------------------------------------------------------------
; Function: call_dos_exec
; Description: Executable an executable using the EXEC function INT 21h/4Bh,
;              with parameter.
; Input: Argument 1 (word): offset to an ASCIZ string of the name of the
;                           executable.
;        Argument 2 (word); offset to an ASCIZ string of the parameter.
; Output (in AX):
;       ret[15] == 0: Success.
;              ret[9:8]: termination type
;                      00b: normal (INT 20h, INT 21h/00h, INT 21h/4Ch)
;                      01b: Ctrl+C abort
;                      10b: Critical error abort
;                      11b: Terminate and stay resident (INT 21h/31h or INT 27h)
;              ret[7:0]: Return code
;       ret[15] == 1: Failed.
;              ret[7:0]: Extended error code
;                      02h: File not found
;                      05h: Access denied
;                      08h: Insufficient memory
;                      0Ah: Environment invalid (usually >32k in length)
;                      0Bh: Format invalid
; --------------------------------------------------------------------------
proc call_dos_exec near
arg @@exe_name_offset:word, @@param_offset:word
local @@error_code:word
        push    ds es

        ; Execute the executable with the given parameter.
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        mov     ax, [@@param_offset]
        mov     [int21_4b_params.command_line_off], ax
        mov     bx, (offset int21_4b_params)    ; ES:BX: parameter block
        mov     dx, [@@exe_name_offset]         ; DS:DX: ASCIZ program name
        mov     ax, 4B00h                       ; Execute the program. (destroys
        int     21h                             ; BX, DX)

        ; Print error message if INT 21h/4B00h failed
        jnc     @@no_error
        mov     [@@error_code], ax
        mov     dx, offset failed_to_execute_1
        mov     ah, 09h
        int     21h
        push    [@@exe_name_offset]
        call    print_asciz_string              ; delayed sp+2
        mov     dx, offset failed_to_execute_2
        mov     ah, 09h
        int     21h
        push    [@@param_offset]
        call    print_asciz_string              ; delayed sp+2
        mov     dx, offset failed_to_execute_3
        mov     ah, 09h
        int     21h
        push    [@@error_code]
        call    print_error_code                ; delayed sp+2
        add     sp, 6                           ; sp+6

        ;   Prepare the return value, then return
        mov     al, [byte ptr @@error_code]
        mov     ah, 80h
        jmp     @@return
@@no_error:

        ; Get termination type in AH, return code in AL
        mov     ah, 4Dh
        int     21h

        pop     es ds
@@return:
        ret
endp call_dos_exec

; --------------------------------------------------------------------------
; Function: print_asciz_string
; Description: Print an ASCIZ string to the console.
; Input: Argument 1 (word): offset to an ASCIZ string to be printed.
; Output: None
; --------------------------------------------------------------------------
proc print_asciz_string near
arg @@str_off:word
        mov     bx, [@@str_off]
        mov     ah, 02h
@@main_loop:
        mov     dl, [byte ptr cs:bx]
        test    dl, dl
        jz      @@end_of_main_loop
        int     21h
        inc     bx
        jmp     @@main_loop
@@end_of_main_loop:
        ret
endp print_asciz_string

; --------------------------------------------------------------------------
; Function: print_error_code
; Description: Print the error code byte.
; Input: Argument 1 (word): The lower byte is the error code byte.
; Output: None
; --------------------------------------------------------------------------
proc print_error_code near
arg @@code:word
        push    si di ds

        mov     dx, [@@code]
        mov     di, (offset error_code_num + 1)
        xor     si, si
@@print_loop:
        mov     al, dl
        and     al, 0Fh
        cmp     al, 10
        jl      @@not_letter
        add     al, 'A' - 10 - '0'
@@not_letter:
        add     al, '0'
        mov     [byte ptr cs:di], al
        dec     di
        shr     dl, 4
        inc     si
        cmp     si, 2
        jne     @@print_loop

        mov     ax, cs
        mov     ds, ax
        mov     dx, (offset error_code_str)
        mov     ah, 09h
        int     21h

        pop     ds di si
        ret
endp print_error_code

failed_to_execute_1     db 'Failed to execute `$'
failed_to_execute_2     db "' with parameter `$"
failed_to_execute_3     db "'.", 0Ah, '$'
failed_to_get_cd        db 'Running in invalid drive.', 0Ah, '$'
failed_to_set_cd        db 'Game path not found.', 0Ah, '$'
failed_to_restore_cd    db "Can't return to previous working directory: ", \
                           'Path not found.', 0Ah, '$'
failed_to_create_tsr    db 'Failed to create THP98TSR.COM.', 0Ah, '$'
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

TSR_COM_BUFFER_SIZE     EQU 100h
tsr_com_buffer          db TSR_COM_BUFFER_SIZE dup (0)

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